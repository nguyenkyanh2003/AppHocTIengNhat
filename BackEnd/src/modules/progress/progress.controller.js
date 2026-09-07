import LearningHistory from "../../../model/LearningHistory.js";
import Lesson from "../../../model/Lesson.js";
import User from "../../../model/User.js";
import UserStreak from "../../../model/UserStreak.js";
import { getVietnamTime, convertDatesToVietnam } from "../../shared/utils/timezone.js";
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

// Lấy tiến độ của một bài học cụ thể
export const getLessonProgress = async (req, res) => {
    try {
        const { lessonID } = req.params;
        const nguoiHocID = req.user._id;

        const progress = await LearningHistory.findOne({
            NguoiHocID: nguoiHocID,
            BaiHocID: lessonID
        })
            .populate('BaiHocID', 'TenBaiHoc CapDo LoaiBaiHoc')
            .lean();

        if (!progress) {
            return res.status(404).json({ 
                message: "Chưa có tiến độ cho bài học này.",
                data: null
            });
        }

        res.json({ data: progress });
    } catch (error) {
        console.error("Lỗi khi lấy tiến độ bài học:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
};

// Cập nhật tiến độ cho một bài học
export const updateLessonProgress = async (req, res) => {
    try {
        const { lessonID } = req.params;
        const nguoiHocID = req.user._id;
        const { TienDo, ThoiGianHoc, GhiChu } = req.body;
        
        let newProgress = parseInt(TienDo, 10);

        if (isNaN(newProgress) || newProgress < 0) {
            newProgress = 0;
        }
        if (newProgress > 100) newProgress = 100;

        const lesson = await Lesson.findById(lessonID);
        if (!lesson) {
            return res.status(404).json({ message: "Bài học không tồn tại." });
        }
        let progress = await LearningHistory.findOne({
            NguoiHocID: nguoiHocID,
            BaiHocID: lessonID
        });

        if (progress) {
            if (newProgress > progress.TienDo) {
                progress.TienDo = newProgress;
                progress.NgayHoc = getVietnamTime();
                
                if (ThoiGianHoc) {
                    progress.ThoiGianHoc = (progress.ThoiGianHoc || 0) + parseInt(ThoiGianHoc, 10);
                }
                if (GhiChu) {
                    progress.GhiChu = GhiChu;
                }
                
                await progress.save();
            }
        } else {
            progress = await LearningHistory.create({
                NguoiHocID: nguoiHocID,
                BaiHocID: lessonID,
                TienDo: newProgress,
                ThoiGianHoc: ThoiGianHoc || 0,
                GhiChu: GhiChu || null,
                NgayHoc: getVietnamTime()
            });
        }

        const populatedProgress = await LearningHistory.findById(progress._id)
            .populate('BaiHocID', 'TenBaiHoc CapDo LoaiBaiHoc')
            .lean();

        // Cập nhật streak khi học bài
        try {
            const streak = await UserStreak.findOne({ user: nguoiHocID });
            if (streak) {
                const updated = streak.updateStreakOnActivity();
                if (updated.is_new_day) {
                    console.log(`✅ Streak updated for user ${nguoiHocID}: ${streak.current_streak} days`);
                }
                
                // Thêm XP cho việc học bài (5 XP cho mỗi tiến độ cập nhật)
                if (newProgress > (progress.TienDo || 0)) {
                    const xpEarned = newProgress === 100 ? 15 : 5; // 15 XP nếu hoàn thành, 5 XP nếu đang học
                    streak.addXP(xpEarned, 'Học bài');
                    await streak.save();
                }
            }
        } catch (streakError) {
            console.error('⚠️ Lỗi cập nhật streak:', streakError);
        }

        res.status(200).json({ 
            message: "Cập nhật tiến độ thành công.", 
            data: convertDatesToVietnam(populatedProgress) 
        });
    } catch (error) {
        console.error("Lỗi khi cập nhật tiến độ:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
};

// Lấy thống kê tiến độ cá nhân
export const getStudyTime = async (req, res) => {
    try {
        const nguoiHocID = req.user._id;

        const [totalLessons, completedLessons, inProgressLessons, avgProgress, byLevel] = await Promise.all([
            LearningHistory.countDocuments({ NguoiHocID: nguoiHocID }),
            LearningHistory.countDocuments({ NguoiHocID: nguoiHocID, TienDo: 100 }),
            LearningHistory.countDocuments({ 
                NguoiHocID: nguoiHocID, 
                TienDo: { $gt: 0, $lt: 100 } 
            }),
            LearningHistory.aggregate([
                { $match: { NguoiHocID: nguoiHocID } },
                { $group: { _id: null, avgProgress: { $avg: "$TienDo" } } }
            ]),
            LearningHistory.aggregate([
                { $match: { NguoiHocID: nguoiHocID } },
                { 
                    $lookup: {
                        from: 'lessons',
                        localField: 'BaiHocID',
                        foreignField: '_id',
                        as: 'lesson'
                    }
                },
                { $unwind: '$lesson' },
                { $group: { _id: "$lesson.CapDo", count: { $sum: 1 }, avgProgress: { $avg: "$TienDo" } } },
                { $sort: { _id: 1 } }
            ])
        ]);

        res.json({
            totalLessons,
            completedLessons,
            inProgressLessons,
            notStartedLessons: totalLessons - completedLessons - inProgressLessons,
            avgProgress: avgProgress[0]?.avgProgress || 0,
            completionRate: totalLessons > 0 ? ((completedLessons / totalLessons) * 100).toFixed(2) : 0,
            byLevel
        });
    } catch (error) {
        console.error("Lỗi khi lấy thống kê tiến độ:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
};

// Lấy lịch sử học tập gần đây
export const getRecentAchievements = async (req, res) => {
    try {
        const nguoiHocID = req.user._id;
        const limit = parseInt(req.query.limit, 10) || 10;

        const recentProgress = await LearningHistory.find({ NguoiHocID: nguoiHocID })
            .populate('BaiHocID', 'TenBaiHoc CapDo LoaiBaiHoc')
            .sort({ NgayHoc: -1 })
            .limit(limit)
            .lean();

        res.json({ 
            total: recentProgress.length,
            data: recentProgress 
        });
    } catch (error) {
        console.error("Lỗi khi lấy lịch sử học tập gần đây:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
};

// Xóa tiến độ của một bài học
export const deleteLessonProgress = async (req, res) => {
    try {
        const { lessonID } = req.params;
        const nguoiHocID = req.user._id;

        const deletedProgress = await LearningHistory.findOneAndDelete({
            NguoiHocID: nguoiHocID,
            BaiHocID: lessonID
        });

        if (!deletedProgress) {
            return res.status(404).json({ message: "Không tìm thấy tiến độ." });
        }

        res.json({ 
            message: "Xóa tiến độ thành công.",
            data: deletedProgress
        });
    } catch (error) {
        console.error("Lỗi khi xóa tiến độ:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
};

// Lấy tiến độ của tất cả người dùng
export const listAdminProgress = async (req, res) => {
    try {
        const page = parseInt(req.query.page, 10) || 1;
        const limit = parseInt(req.query.limit, 10) || 10;
        const { userId, lessonId, minProgress, maxProgress } = req.query;

        const query = {};
        
        if (userId) {
            query.NguoiHocID = userId;
        }
        if (lessonId) {
            query.BaiHocID = lessonId;
        }
        if (minProgress) {
            query.TienDo = { ...query.TienDo, $gte: parseInt(minProgress, 10) };
        }
        if (maxProgress) {
            query.TienDo = { ...query.TienDo, $lte: parseInt(maxProgress, 10) };
        }

        const skip = (page - 1) * limit;

        const [progressList, total] = await Promise.all([
            LearningHistory.find(query)
                .populate('BaiHocID', 'TenBaiHoc CapDo LoaiBaiHoc')
                .populate('NguoiHocID', 'HoTen Email')
                .sort({ NgayHoc: -1 })
                .skip(skip)
                .limit(limit)
                .lean(),
            LearningHistory.countDocuments(query)
        ]);

        res.json({
            totalItems: total,
            totalPages: Math.ceil(total / limit),
            currentPage: page,
            data: progressList
        });
    } catch (error) {
        console.error("Lỗi khi lấy tiến độ của tất cả người dùng:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
};

// Lấy tiến độ của người dùng cụ thể
export const getAdminUserProgress = async (req, res) => {
    try {
        const { userID } = req.params;
        
        const progressList = await LearningHistory.find({ NguoiHocID: userID })
            .populate('BaiHocID', 'TenBaiHoc CapDo LoaiBaiHoc')
            .sort({ NgayHoc: -1 })
            .lean();

        if (!progressList || progressList.length === 0) {
            return res.status(404).json({ message: "Không tìm thấy tiến độ học của người dùng này." });
        }

        res.json({ 
            total: progressList.length,
            data: progressList 
        });
    } catch (error) {
        console.error("Lỗi khi lấy tiến độ của người dùng cụ thể:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
};

// Lấy thống kê tổng quan
export const getAdminStats = async (req, res) => {
    try {
        const [
            totalProgress,
            totalUsers,
            totalLessons,
            avgProgress,
            progressByLevel,
            topUsers,
            recentActivity
        ] = await Promise.all([
            LearningHistory.countDocuments(),
            LearningHistory.distinct('NguoiHocID').then(ids => ids.length),
            LearningHistory.distinct('BaiHocID').then(ids => ids.length),
            LearningHistory.aggregate([
                { $group: { _id: null, avgProgress: { $avg: "$TienDo" } } }
            ]),
            LearningHistory.aggregate([
                { 
                    $lookup: {
                        from: 'lessons',
                        localField: 'BaiHocID',
                        foreignField: '_id',
                        as: 'lesson'
                    }
                },
                { $unwind: '$lesson' },
                { $group: { 
                    _id: "$lesson.CapDo", 
                    count: { $sum: 1 }, 
                    avgProgress: { $avg: "$TienDo" },
                    completed: { $sum: { $cond: [{ $eq: ["$TienDo", 100] }, 1, 0] } }
                }},
                { $sort: { _id: 1 } }
            ]),
            LearningHistory.aggregate([
                { $group: { 
                    _id: "$NguoiHocID", 
                    totalLessons: { $sum: 1 },
                    completedLessons: { $sum: { $cond: [{ $eq: ["$TienDo", 100] }, 1, 0] } },
                    avgProgress: { $avg: "$TienDo" }
                }},
                { $sort: { completedLessons: -1, avgProgress: -1 } },
                { $limit: 10 },
                { 
                    $lookup: {
                        from: 'users',
                        localField: '_id',
                        foreignField: '_id',
                        as: 'user'
                    }
                },
                { $unwind: '$user' }
            ]),
            LearningHistory.find()
                .populate('NguoiHocID', 'HoTen')
                .populate('BaiHocID', 'TenBaiHoc')
                .sort({ NgayHoc: -1 })
                .limit(20)
                .lean()
        ]);

        res.json({
            overview: {
                totalProgress,
                totalUsers,
                totalLessons,
                avgProgress: avgProgress[0]?.avgProgress || 0
            },
            progressByLevel,
            topUsers,
            recentActivity
        });
    } catch (error) {
        console.error("Lỗi khi lấy thống kê tổng quan:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
};

// Cập nhật tiến độ cho người dùng (admin)
export const updateAdminProgress = async (req, res) => {
    try {
        const { id } = req.params;
        const updateData = req.body;

        if (updateData.TienDo !== undefined) {
            updateData.TienDo = Math.max(0, Math.min(100, parseInt(updateData.TienDo, 10)));
        }

        const updatedProgress = await LearningHistory.findByIdAndUpdate(
            id,
            updateData,
            { new: true, runValidators: true }
        )
            .populate('BaiHocID', 'TenBaiHoc CapDo LoaiBaiHoc')
            .populate('NguoiHocID', 'HoTen Email');

        if (!updatedProgress) {
            return res.status(404).json({ message: "Không tìm thấy tiến độ." });
        }

        res.json({ 
            message: "Cập nhật tiến độ thành công.", 
            data: updatedProgress 
        });
    } catch (error) {
        console.error("Lỗi khi cập nhật tiến độ:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
};

// Xóa tiến độ 
export const deleteAdminProgress = async (req, res) => {
    try {
        const { id } = req.params;
        
        const deletedProgress = await LearningHistory.findByIdAndDelete(id);

        if (!deletedProgress) {
            return res.status(404).json({ message: "Không tìm thấy bản ghi tiến độ." });
        }

        res.json({ 
            message: "Xóa tiến độ thành công.",
            data: deletedProgress
        });
    } catch (error) {
        console.error("Lỗi khi thực hiện xóa tiến độ:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
};

// Xóa nhiều tiến độ 
export const deleteManyProgress = async (req, res) => {
    try {
        const { ids } = req.body;

        if (!Array.isArray(ids) || ids.length === 0) {
            return res.status(400).json({ message: "Danh sách ID không hợp lệ." });
        }

        const result = await LearningHistory.deleteMany({ _id: { $in: ids } });

        res.json({ 
            message: `Đã xóa ${result.deletedCount} tiến độ.`,
            deletedCount: result.deletedCount
        });
    } catch (error) {
        console.error("Lỗi khi xóa nhiều tiến độ:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
};

// Xóa tất cả tiến độ của người dùng 
export const clearUserProgress = async (req, res) => {
    try {
        const { userID } = req.params;

        const result = await LearningHistory.deleteMany({ NguoiHocID: userID });

        res.json({ 
            message: `Đã xóa ${result.deletedCount} tiến độ của người dùng.`,
            deletedCount: result.deletedCount
        });
    } catch (error) {
        console.error("Lỗi khi xóa tiến độ người dùng:", error);
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

    const streak = await UserStreak.findOne({ user: userId });
    if (streak && streak.xp_history) {
      streak.xp_history.forEach(xp => {
        const date = xp.earned_at.toISOString().split('T')[0];
        if (dailyData[date]) {
          dailyData[date].xp += xp.amount;
        }
      });
    }

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

    const streak = await UserStreak.findOne({ user: userId });
    const activityDates = streak?.activity_dates || [];

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


