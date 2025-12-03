import express from 'express';
import UserStreak from '../model/UserStreak.js';
import UserAchievement from '../model/UserAchievement.js';
import Achievement from '../model/Achievement.js';
import { authenticateUser } from './auth.js';

const router = express.Router();

// Lấy thông tin streak của người dùng hiện tại
router.get('/my-streak', authenticateUser, async (req, res) => {
  try {
    const userId = req.user._id;
    const username = req.user.TenDangNhap || req.user.username;
    
    console.log(`🔥 Streak request - User: ${username} (${userId})`);
    
    let streak = await UserStreak.findOne({ user: userId });
    
    if (!streak) {
      // Tạo bản ghi streak mới
      console.log(`📝 Creating new streak for user ${username}`);
      streak = new UserStreak({ user: userId });
      await streak.save();
    } else {
      console.log(`✅ Streak found - User: ${username}, XP: ${streak.total_xp}, Streak: ${streak.current_streak} days, Level: ${streak.level}`);
    }
    
    res.json(streak);
  } catch (error) {
    console.error('Lỗi khi lấy streak:', error);
    res.status(500).json({ message: 'Lỗi khi lấy thông tin streak' });
  }
});

// Thêm XP và tự động cập nhật streak (gọi khi hoàn thành bài tập, lesson, học từ vựng, v.v.)
router.post('/add-xp', authenticateUser, async (req, res) => {
  try {
    const { amount, reason } = req.body;
    
    if (!amount || amount <= 0) {
      return res.status(400).json({ message: 'Số XP không hợp lệ' });
    }
    
    let streak = await UserStreak.findOne({ user: req.user._id });
    
    if (!streak) {
      streak = new UserStreak({ user: req.user._id });
    }
    
    // Cập nhật streak trước khi thêm XP (vì đây là hoạt động học tập)
    const streakResult = streak.updateStreakOnActivity();
    
    // Thêm XP thưởng cho hoạt động
    streak.addXP(amount, reason || 'Hoạt động học tập');
    
    // Nếu là ngày mới, thưởng thêm XP cho streak
    if (streakResult.is_new_day) {
      let bonusXP = 10; // XP cơ bản cho mỗi ngày học
      
      // Thưởng cột mốc
      if (streak.current_streak % 7 === 0) bonusXP = 50; // Cột mốc 7 ngày
      if (streak.current_streak % 30 === 0) bonusXP = 200; // Cột mốc 30 ngày
      
      streak.addXP(bonusXP, `Streak ${streak.current_streak} ngày`);
    }
    
    await streak.save();
    
    // Kiểm tra thành tích
    await checkStreakAchievements(req.user._id, streak.current_streak, streak.longest_streak);
    await checkXPAchievements(req.user._id, streak.total_xp);
    
    res.json({
      total_xp: streak.total_xp,
      level: streak.level,
      xp_to_next_level: streak.xp_to_next_level,
      current_streak: streak.current_streak,
      longest_streak: streak.longest_streak,
      is_new_day: streakResult.is_new_day,
      streak_broken: streakResult.streak_broken || false
    });
  } catch (error) {
    console.error('Lỗi khi thêm XP:', error);
    res.status(500).json({ message: 'Lỗi khi thêm XP' });
  }
});

// Lấy lịch sử XP
router.get('/xp-history', authenticateUser, async (req, res) => {
  try {
    const streak = await UserStreak.findOne({ user: req.user._id });
    
    if (!streak) {
      return res.json([]);
    }
    
    res.json(streak.xp_history.sort((a, b) => b.earned_at - a.earned_at));
  } catch (error) {
    console.error('Lỗi khi lấy lịch sử XP:', error);
    res.status(500).json({ message: 'Lỗi khi lấy lịch sử XP' });
  }
});

// Lấy bảng xếp hạng
router.get('/leaderboard', authenticateUser, async (req, res) => {
  try {
    const { period = 'all', limit = 50 } = req.query;
    
    let query = {};
    
    if (period === 'week') {
      const weekAgo = new Date();
      weekAgo.setDate(weekAgo.getDate() - 7);
      query = { 'xp_history.earned_at': { $gte: weekAgo } };
    } else if (period === 'month') {
      const monthAgo = new Date();
      monthAgo.setMonth(monthAgo.getMonth() - 1);
      query = { 'xp_history.earned_at': { $gte: monthAgo } };
    }
    
    const leaderboard = await UserStreak.find(query)
      .sort({ total_xp: -1, current_streak: -1 })
      .limit(parseInt(limit))
      .populate('user', 'username email full_name avatar');
    
    // Thêm thứ hạng
    const rankedLeaderboard = leaderboard.map((entry, index) => ({
      rank: index + 1,
      user: entry.user,
      total_xp: entry.total_xp,
      level: entry.level,
      current_streak: entry.current_streak,
      longest_streak: entry.longest_streak
    }));
    
    // Tìm thứ hạng của người dùng hiện tại
    const userStreak = await UserStreak.findOne({ user: req.user._id });
    let userRank = null;
    
    if (userStreak) {
      const higherRanked = await UserStreak.countDocuments({
        total_xp: { $gt: userStreak.total_xp }
      });
      userRank = higherRanked + 1;
    }
    
    res.json({
      leaderboard: rankedLeaderboard,
      user_rank: userRank
    });
  } catch (error) {
    console.error('Lỗi khi lấy bảng xếp hạng:', error);
    res.status(500).json({ message: 'Lỗi khi lấy bảng xếp hạng' });
  }
});

// Hàm kiểm tra thành tích streak
async function checkStreakAchievements(userId, currentStreak, longestStreak) {
  const streakMilestones = [7, 14, 30, 50, 100, 365];
  
  for (const milestone of streakMilestones) {
    if (currentStreak >= milestone || longestStreak >= milestone) {
      const achievement = await Achievement.findOne({
        category: 'streak',
        requirement_value: milestone
      });
      
      if (achievement) {
        await updateUserAchievement(userId, achievement._id, milestone, milestone);
      }
    }
  }
}

// Hàm kiểm tra thành tích XP
async function checkXPAchievements(userId, totalXP) {
  const xpMilestones = [100, 500, 1000, 5000, 10000];
  
  for (const milestone of xpMilestones) {
    if (totalXP >= milestone) {
      const achievement = await Achievement.findOne({
        category: 'xp',
        requirement_value: milestone
      });
      
      if (achievement) {
        await updateUserAchievement(userId, achievement._id, totalXP, milestone);
      }
    }
  }
}

// Hàm cập nhật tiến độ thành tích của người dùng
async function updateUserAchievement(userId, achievementId, progress, required) {
  try {
    let userAchievement = await UserAchievement.findOne({
      user: userId,
      achievement: achievementId
    });
    
    if (!userAchievement) {
      userAchievement = new UserAchievement({
        user: userId,
        achievement: achievementId,
        progress: progress
      });
    } else {
      userAchievement.progress = progress;
    }
    
    if (progress >= required && !userAchievement.is_completed) {
      userAchievement.is_completed = true;
      userAchievement.earned_at = new Date();
      
      // Thưởng XP cho thành tích
      const achievement = await Achievement.findById(achievementId);
      if (achievement) {
        const streak = await UserStreak.findOne({ user: userId });
        if (streak) {
          streak.addXP(achievement.xp_reward, `Thành tích: ${achievement.name_vi}`);
          await streak.save();
        }
      }
    }
    
    await userAchievement.save();
  } catch (error) {
    console.error('Lỗi khi cập nhật thành tích:', error);
  }
}

// 🧪 TEST ONLY: Reset last_activity_date về hôm qua để test streak
router.post('/test/reset-yesterday', authenticateUser, async (req, res) => {
  try {
    const streak = await UserStreak.findOne({ user: req.user._id });
    
    if (!streak) {
      return res.status(404).json({ message: 'Không tìm thấy streak' });
    }
    
    // Set last_activity_date về hôm qua
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    yesterday.setHours(0, 0, 0, 0);
    
    streak.last_activity_date = yesterday;
    await streak.save();
    
    console.log(`🧪 TEST: Reset streak last_activity_date to yesterday for user ${req.user._id}`);
    console.log(`   Yesterday: ${yesterday.toISOString()}`);
    console.log(`   Current streak: ${streak.current_streak}`);
    
    res.json({
      message: 'Đã reset last_activity_date về hôm qua',
      last_activity_date: yesterday,
      current_streak: streak.current_streak,
      note: 'Login hoặc học bất kỳ để streak tăng lên!'
    });
  } catch (error) {
    console.error('Lỗi khi reset test:', error);
    res.status(500).json({ message: 'Lỗi server' });
  }
});

// 🧪 TEST ONLY: Xem chi tiết streak debug
router.get('/test/debug', authenticateUser, async (req, res) => {
  try {
    const streak = await UserStreak.findOne({ user: req.user._id });
    
    if (!streak) {
      return res.status(404).json({ message: 'Không tìm thấy streak' });
    }
    
    const now = new Date();
    const vietnamTime = new Date(now.toLocaleString("en-US", { timeZone: "Asia/Ho_Chi_Minh" }));
    const today = new Date(vietnamTime.getFullYear(), vietnamTime.getMonth(), vietnamTime.getDate());
    
    const lastActivity = streak.last_activity_date ? new Date(streak.last_activity_date) : null;
    const lastActivityVN = lastActivity ? new Date(lastActivity.getFullYear(), lastActivity.getMonth(), lastActivity.getDate()) : null;
    
    const daysDiff = lastActivityVN ? Math.floor((today - lastActivityVN) / (1000 * 60 * 60 * 24)) : null;
    
    res.json({
      server_time_utc: now.toISOString(),
      vietnam_time: vietnamTime.toLocaleString('vi-VN'),
      today_date: today.toISOString().split('T')[0],
      last_activity_date: lastActivity ? lastActivity.toISOString() : null,
      last_activity_date_vn: lastActivityVN ? lastActivityVN.toISOString().split('T')[0] : null,
      days_difference: daysDiff,
      current_streak: streak.current_streak,
      longest_streak: streak.longest_streak,
      total_xp: streak.total_xp,
      activity_dates_count: streak.activity_dates.length,
      will_increase_streak: daysDiff === 1,
      will_break_streak: daysDiff > 1,
      already_today: daysDiff === 0
    });
  } catch (error) {
    console.error('Lỗi khi debug:', error);
    res.status(500).json({ message: 'Lỗi server' });
  }
});

export default router;
