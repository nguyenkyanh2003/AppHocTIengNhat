import express from 'express';
import Achievement from '../model/Achievement.js';
import UserAchievement from '../model/UserAchievement.js';
import { authenticateUser } from './auth.js';

const router = express.Router();

// Lấy tất cả thành tích
router.get('/all', authenticateUser, async (req, res) => {
  try {
    const achievements = await Achievement.find({ is_active: true })
      .sort({ category: 1, requirement_value: 1 });
    
    res.json(achievements);
  } catch (error) {
    console.error('Lỗi khi lấy danh sách achievement:', error);
    res.status(500).json({ message: 'Lỗi khi lấy danh sách achievement' });
  }
});

// Lấy các thành tích của người dùng với tiến độ
router.get('/my-achievements', authenticateUser, async (req, res) => {
  try {
    const userAchievements = await UserAchievement.find({ user: req.user._id })
      .populate('achievement')
      .sort({ is_completed: -1, earned_at: -1 });
    
    // Lấy tất cả thành tích để hiển thị các thành tích chưa mở khóa
    const allAchievements = await Achievement.find({ is_active: true });
    const earnedIds = userAchievements.map(ua => ua.achievement._id.toString());
    
    const lockedAchievements = allAchievements
      .filter(a => !earnedIds.includes(a._id.toString()))
      .map(a => ({
        achievement: a,
        progress: 0,
        is_completed: false,
        is_locked: true
      }));
    
    res.json({
      earned: userAchievements,
      locked: lockedAchievements,
      total: allAchievements.length,
      completed: userAchievements.filter(ua => ua.is_completed).length
    });
  } catch (error) {
    console.error('Lỗi khi lấy achievement của người dùng:', error);
    res.status(500).json({ message: 'Lỗi khi lấy achievement của người dùng' });
  }
});

// Lấy thành tích theo danh mục
router.get('/category/:category', authenticateUser, async (req, res) => {
  try {
    const { category } = req.params;
    
    const achievements = await Achievement.find({ 
      category: category,
      is_active: true 
    }).sort({ requirement_value: 1 });
    
    const userAchievements = await UserAchievement.find({
      user: req.user._id,
      achievement: { $in: achievements.map(a => a._id) }
    }).populate('achievement');
    
    res.json({
      achievements,
      user_progress: userAchievements
    });
  } catch (error) {
    console.error('Lỗi khi lấy achievement theo danh mục:', error);
    res.status(500).json({ message: 'Lỗi khi lấy achievement theo danh mục' });
  }
});

// Cập nhật tiến độ thành tích thủ công
router.post('/update-progress', authenticateUser, async (req, res) => {
  try {
    const { achievement_id, progress } = req.body;
    
    const achievement = await Achievement.findById(achievement_id);
    if (!achievement) {
      return res.status(404).json({ message: 'Achievement không tồn tại' });
    }
    
    let userAchievement = await UserAchievement.findOne({
      user: req.user._id,
      achievement: achievement_id
    });
    
    if (!userAchievement) {
      userAchievement = new UserAchievement({
        user: req.user._id,
        achievement: achievement_id,
        progress: progress
      });
    } else {
      userAchievement.progress = progress;
    }
    
    // Kiểm tra xem thành tích đã hoàn thành chưa
    if (progress >= achievement.requirement_value && !userAchievement.is_completed) {
      userAchievement.is_completed = true;
      userAchievement.earned_at = new Date();
      
      // Thưởng XP
      const UserStreak = (await import('../model/UserStreak.js')).default;
      const streak = await UserStreak.findOne({ user: req.user._id });
      if (streak) {
        streak.addXP(achievement.xp_reward, `Thành tích: ${achievement.name_vi}`);
        await streak.save();
      }
    }
    
    await userAchievement.save();
    
    res.json(userAchievement);
  } catch (error) {
    console.error('Lỗi khi cập nhật tiến độ achievement:', error);
    res.status(500).json({ message: 'Lỗi khi cập nhật tiến độ achievement' });
  }
});

// Admin: Tạo thành tích mới
router.post('/create', authenticateUser, async (req, res) => {
  try {
    // TODO: Thêm kiểm tra quyền admin
    const achievement = new Achievement(req.body);
    await achievement.save();
    
    res.status(201).json(achievement);
  } catch (error) {
    console.error('Lỗi khi tạo achievement:', error);
    res.status(500).json({ message: 'Lỗi khi tạo achievement' });
  }
});

// Lấy thống kê thành tích
router.get('/stats', authenticateUser, async (req, res) => {
  try {
    const totalAchievements = await Achievement.countDocuments({ is_active: true });
    const earnedAchievements = await UserAchievement.countDocuments({
      user: req.user._id,
      is_completed: true
    });
    
    const achievementsByCategory = await Achievement.aggregate([
      { $match: { is_active: true } },
      { $group: { _id: '$category', count: { $sum: 1 } } }
    ]);
    
    const earnedByCategory = await UserAchievement.aggregate([
      { $match: { user: req.user._id, is_completed: true } },
      { 
        $lookup: {
          from: 'achievements',
          localField: 'achievement',
          foreignField: '_id',
          as: 'achievement_data'
        }
      },
      { $unwind: '$achievement_data' },
      { $group: { _id: '$achievement_data.category', count: { $sum: 1 } } }
    ]);
    
    res.json({
      total_achievements: totalAchievements,
      earned_achievements: earnedAchievements,
      completion_rate: totalAchievements > 0 ? (earnedAchievements / totalAchievements * 100).toFixed(1) : 0,
      by_category: achievementsByCategory,
      earned_by_category: earnedByCategory
    });
  } catch (error) {
    console.error('Lỗi khi lấy thống kê achievement:', error);
    res.status(500).json({ message: 'Lỗi khi lấy thống kê achievement' });
  }
});

export default router;
