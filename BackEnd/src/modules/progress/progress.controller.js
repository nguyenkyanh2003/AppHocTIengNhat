import LearningHistory from "../../../model/LearningHistory.js";
import UserStreak from "../../../model/UserStreak.js";
import { streakReadService } from "../streaks/streak-read.service.js";
import { convertDatesToVietnam } from "../../shared/utils/timezone.js";
import dotenv from "dotenv";

dotenv.config();

// Lấy tiến độ cá nhân
export const getMyProgress = async (req, res) => {
    try {
        const nguoiHocID = req.user._id;
        
        if (!nguoiHocID) {
            return res.status(401).json({ message: "Không tìm thấy ID người dùng." });
        }

        const progressList = await LearningHistory.find({ NguoiHocID: nguoiHocID })
            .populate('BaiHocID', 'TenBaiHoc CapDo LoaiBaiHoc')
            .sort({ NgayHoc: -1 })
            .lean();

        res.json({ 
            total: progressList.length,
            data: convertDatesToVietnam(progressList) 
        });
    } catch (error) {
        console.error("Lỗi khi lấy tiến độ cá nhân:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
};

// ===== DASHBOARD STATISTICS =====
import ExerciseResult from '../../../model/ExerciseResult.js';
import SRSProgress from '../../../model/SRSProgress.js';
import LessonProgress from '../../../model/LessonProgress.js';

// Lấy thống kê tổng quan cho dashboard
export const getDashboardStats = async (req, res) => {
  try {
    const userId = req.user._id;

    // Đếm từ vựng đã học
    const vocabularyCount = await SRSProgress.countDocuments({
      user: userId,
      item_type: 'vocabulary',
      status: { $in: ['reviewed', 'mastered'] }
    });

    // Đếm kanji đã học
    const kanjiCount = await SRSProgress.countDocuments({
      user: userId,
      item_type: 'kanji',
      status: { $in: ['reviewed', 'mastered'] }
    });

    // Đếm bài tập đã làm
    const exerciseCount = await ExerciseResult.countDocuments({
      user_id: userId
    });

    // Đếm bài học đã hoàn thành
    const completedLessons = await LessonProgress.countDocuments({
      user: userId,
      is_completed: true
    });

    // Lấy streak info
    const streak = await UserStreak.findOne({ user: userId });

    // Tính tổng thời gian học
    const exercises = await ExerciseResult.find({ user_id: userId });
    const totalStudyTime = exercises.reduce((sum, ex) => sum + (ex.time_spent || 0), 0);

    res.json({
      vocabulary_learned: vocabularyCount,
      kanji_learned: kanjiCount,
      exercises_completed: exerciseCount,
      lessons_completed: completedLessons,
      total_study_time: totalStudyTime,
      current_streak: streak?.current_streak || 0,
      total_xp: streak?.total_xp || 0,
      level: streak?.level || 1
    });
  } catch (error) {
    console.error('Lỗi khi lấy thống kê dashboard:', error);
    res.status(500).json({ message: 'Lỗi server', error: error.message });
  }
};

// Lấy dữ liệu timeline cho biểu đồ
export const getDashboardTimeline = async (req, res) => {
  try {
    const userId = req.user._id;
    const { period = 'week' } = req.query;

    let startDate = new Date();
    switch (period) {
      case 'week':
        startDate.setDate(startDate.getDate() - 7);
        break;
      case 'month':
        startDate.setMonth(startDate.getMonth() - 1);
        break;
      case 'year':
        startDate.setFullYear(startDate.getFullYear() - 1);
        break;
    }

    const exercises = await ExerciseResult.find({
      user_id: userId,
      createdAt: { $gte: startDate }
    }).sort({ createdAt: 1 });

    const lessons = await LessonProgress.find({
      user: userId,
      last_studied_at: { $gte: startDate }
    }).sort({ last_studied_at: 1 });

    const dailyData = {};
    
    exercises.forEach(ex => {
      const date = ex.createdAt.toISOString().split('T')[0];
      if (!dailyData[date]) {
        dailyData[date] = { exercises: 0, lessons: 0, time: 0, xp: 0 };
      }
      dailyData[date].exercises += 1;
      dailyData[date].time += ex.time_spent || 0;
    });

    lessons.forEach(lesson => {
      const date = lesson.last_studied_at.toISOString().split('T')[0];
      if (!dailyData[date]) {
        dailyData[date] = { exercises: 0, lessons: 0, time: 0, xp: 0 };
      }
      dailyData[date].lessons += 1;
    });

    // Lịch sử XP đọc qua service chung: mảng `xp_history` cũ không còn được
    // ghi thêm sau cutover, nên đọc thẳng nó là bảng XP đứng yên từ hôm nay.
    const xpHistory = await streakReadService.xpHistory(userId);
    xpHistory.forEach(({ amount, earned_at: earnedAt }) => {
      const date = new Date(earnedAt).toISOString().split('T')[0];
      if (dailyData[date]) {
        dailyData[date].xp += amount;
      }
    });

    const timeline = Object.keys(dailyData).map(date => ({
      date,
      ...dailyData[date]
    }));

    res.json(timeline);
  } catch (error) {
    console.error('Lỗi khi lấy timeline:', error);
    res.status(500).json({ message: 'Lỗi server', error: error.message });
  }
};

// Lấy dữ liệu heatmap calendar
export const getDashboardHeatmap = async (req, res) => {
  try {
    const userId = req.user._id;
    const { year = new Date().getFullYear() } = req.query;

    const startDate = new Date(year, 0, 1);
    const endDate = new Date(year, 11, 31, 23, 59, 59);

    // Ngày học lấy từ lịch `StreakDay` (gộp cả ngày cũ chưa migration).
    const activityDates = await streakReadService.activityDates(userId);

    const exercises = await ExerciseResult.find({
      user_id: userId,
      createdAt: { $gte: startDate, $lte: endDate }
    });

    const lessons = await LessonProgress.find({
      user: userId,
      last_studied_at: { $gte: startDate, $lte: endDate }
    });

    const heatmapData = {};

    activityDates.forEach(date => {
      const dateStr = new Date(date).toISOString().split('T')[0];
      if (dateStr >= startDate.toISOString().split('T')[0] && 
          dateStr <= endDate.toISOString().split('T')[0]) {
        if (!heatmapData[dateStr]) {
          heatmapData[dateStr] = { count: 0, time: 0 };
        }
        heatmapData[dateStr].count += 1;
      }
    });

    exercises.forEach(ex => {
      const dateStr = ex.createdAt.toISOString().split('T')[0];
      if (!heatmapData[dateStr]) {
        heatmapData[dateStr] = { count: 0, time: 0 };
      }
      heatmapData[dateStr].count += 1;
      heatmapData[dateStr].time += ex.time_spent || 0;
    });

    lessons.forEach(lesson => {
      const dateStr = lesson.last_studied_at.toISOString().split('T')[0];
      if (!heatmapData[dateStr]) {
        heatmapData[dateStr] = { count: 0, time: 0 };
      }
      heatmapData[dateStr].count += 1;
    });

    const heatmap = Object.keys(heatmapData).map(date => ({
      date,
      count: heatmapData[date].count,
      time: heatmapData[date].time
    }));

    res.json(heatmap);
  } catch (error) {
    console.error('Lỗi khi lấy heatmap:', error);
    res.status(500).json({ message: 'Lỗi server', error: error.message });
  }
};

// Lấy phân tích chi tiết
export const getDashboardBreakdown = async (req, res) => {
  try {
    const userId = req.user._id;
    console.log('📊 Fetching breakdown for user:', userId);

    const lessonsByLevel = await LessonProgress.aggregate([
      { $match: { user: userId } },
      {
        $lookup: {
          from: 'lessons',
          localField: 'lesson',
          foreignField: '_id',
          as: 'lessonInfo'
        }
      },
      { $unwind: '$lessonInfo' },
      {
        $group: {
          _id: '$lessonInfo.level',
          completed: { $sum: { $cond: ['$is_completed', 1, 0] } },
          in_progress: { $sum: { $cond: ['$is_completed', 0, 1] } }
        }
      }
    ]);

    const exercisesByType = await ExerciseResult.aggregate([
      { $match: { user_id: userId } },
      {
        $lookup: {
          from: 'exercises',
          localField: 'exercise_id',
          foreignField: '_id',
          as: 'exerciseInfo'
        }
      },
      { $unwind: '$exerciseInfo' },
      {
        $group: {
          _id: '$exerciseInfo.type',
          count: { $sum: 1 },
          average_score: { $avg: '$score' },
          passed: { $sum: { $cond: ['$passed', 1, 0] } }
        }
      }
    ]);

    console.log(`📊 Found ${lessonsByLevel.length} lesson levels, ${exercisesByType.length} exercise types`);

    res.json({
      lessons_by_level: lessonsByLevel,
      exercises_by_type: exercisesByType
    });
  } catch (error) {
    console.error('❌ Lỗi khi lấy breakdown:', error);
    res.status(500).json({ message: 'Lỗi server', error: error.message });
  }
};
