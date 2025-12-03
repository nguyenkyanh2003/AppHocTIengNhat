import express from 'express';
import LessonProgress from '../model/LessonProgress.js';
import Lesson from '../model/Lesson.js';
import UserStreak from '../model/UserStreak.js';
import { authenticateUser } from './auth.js';
import { getVietnamTime, convertDatesToVietnam } from '../utils/timezone.js';

const router = express.Router();

// Tất cả routes cần authentication
router.use(authenticateUser);

// GET /api/lesson-progress/lesson/:lessonId - Lấy tiến độ của user cho lesson
router.get('/lesson/:lessonId', async (req, res) => {
    try {
        const { lessonId } = req.params;
        const userId = req.user._id;

        const progress = await LessonProgress.findOne({
            user: userId,
            lesson: lessonId
        });

        if (!progress) {
            return res.json(null);
        }

        res.json(convertDatesToVietnam(progress));
    } catch (error) {
        console.error('Error getting lesson progress:', error);
        res.status(500).json({ message: 'Lỗi server', error: error.message });
    }
});

// GET /api/lesson-progress/lessons - Lấy tất cả tiến độ của user
router.get('/lessons', async (req, res) => {
    try {
        const userId = req.user._id;

        const progressList = await LessonProgress.find({ user: userId })
            .populate('lesson', 'title level order')
            .sort({ last_studied_at: -1 });

        res.json(convertDatesToVietnam(progressList));
    } catch (error) {
        console.error('Error getting all progress:', error);
        res.status(500).json({ message: 'Lỗi server', error: error.message });
    }
});

// POST /api/lesson-progress/lesson/:lessonId/start - Bắt đầu học lesson
router.post('/lesson/:lessonId/start', async (req, res) => {
    try {
        const { lessonId } = req.params;
        const userId = req.user._id;

        // Kiểm tra lesson tồn tại
        const lesson = await Lesson.findById(lessonId);
        if (!lesson) {
            return res.status(404).json({ message: 'Không tìm thấy bài học' });
        }

        // Kiểm tra đã có progress chưa
        let progress = await LessonProgress.findOne({
            user: userId,
            lesson: lessonId
        });

        if (progress) {
            // Đã có rồi, chỉ cập nhật last_studied_at
            progress.last_studied_at = getVietnamTime();
            await progress.save();
        } else {
            // Tạo mới
            progress = new LessonProgress({
                user: userId,
                lesson: lessonId,
                total_vocabularies: lesson.vocabularies.length,
                total_grammars: lesson.grammars.length,
                total_kanjis: lesson.kanjis.length,
            });
            await progress.save();
            
            // Cập nhật streak khi bắt đầu học bài mới
            try {
                const streak = await UserStreak.findOne({ user: userId });
                if (streak) {
                    const updated = streak.updateStreakOnActivity();
                    if (updated.is_new_day) {
                        console.log(`✅ Streak updated for user ${userId}: ${streak.current_streak} days`);
                    }
                    streak.addXP(3, 'Bắt đầu học bài');
                    await streak.save();
                }
            } catch (streakError) {
                console.error('⚠️ Lỗi cập nhật streak:', streakError);
            }
        }

        res.json(convertDatesToVietnam(progress));
    } catch (error) {
        console.error('Error starting lesson:', error);
        res.status(500).json({ message: 'Lỗi server', error: error.message });
    }
});

// POST /api/lesson-progress/lesson/:lessonId/update - Cập nhật tiến độ
router.post('/lesson/:lessonId/update', async (req, res) => {
    try {
        const { lessonId } = req.params;
        const { item_type, item_id, completed } = req.body;
        const userId = req.user._id;

        // Validate
        if (!['vocabulary', 'grammar', 'kanji'].includes(item_type)) {
            return res.status(400).json({ message: 'Item type không hợp lệ' });
        }

        // Tìm progress
        let progress = await LessonProgress.findOne({
            user: userId,
            lesson: lessonId
        });

        if (!progress) {
            // Nếu chưa có, tạo mới
            const lesson = await Lesson.findById(lessonId);
            if (!lesson) {
                return res.status(404).json({ message: 'Không tìm thấy bài học' });
            }

            progress = new LessonProgress({
                user: userId,
                lesson: lessonId,
                total_vocabularies: lesson.vocabularies.length,
                total_grammars: lesson.grammars.length,
                total_kanjis: lesson.kanjis.length,
            });
        }

        // Cập nhật
        if (completed) {
            progress.markItemLearned(item_type, item_id);
            
            // Cập nhật streak khi học xong một item
            try {
                const streak = await UserStreak.findOne({ user: userId });
                if (streak) {
                    const updated = streak.updateStreakOnActivity();
                    if (updated.is_new_day) {
                        console.log(`✅ Streak updated for user ${userId}: ${streak.current_streak} days`);
                    }
                    // 2 XP cho mỗi item học xong (vocabulary/grammar/kanji)
                    streak.addXP(2, `Học ${item_type}`);
                    await streak.save();
                }
            } catch (streakError) {
                console.error('⚠️ Lỗi cập nhật streak:', streakError);
            }
        } else {
            progress.unmarkItemLearned(item_type, item_id);
        }

        await progress.save();
        res.json(convertDatesToVietnam(progress));
    } catch (error) {
        console.error('Error updating progress:', error);
        res.status(500).json({ message: 'Lỗi server', error: error.message });
    }
});

// POST /api/lesson-progress/lesson/:lessonId/complete - Đánh dấu lesson hoàn thành
router.post('/lesson/:lessonId/complete', async (req, res) => {
    try {
        const { lessonId } = req.params;
        const userId = req.user._id;

        const progress = await LessonProgress.findOne({
            user: userId,
            lesson: lessonId
        });

        if (!progress) {
            return res.status(404).json({ message: 'Không tìm thấy tiến độ' });
        }

        progress.is_completed = true;
        progress.completed_at = getVietnamTime();
        await progress.save();

        // Cập nhật streak khi hoàn thành bài học
        try {
            const streak = await UserStreak.findOne({ user: userId });
            if (streak) {
                const updated = streak.updateStreakOnActivity();
                if (updated.is_new_day) {
                    console.log(`✅ Streak updated for user ${userId}: ${streak.current_streak} days`);
                }
                // 20 XP cho việc hoàn thành bài học
                streak.addXP(20, 'Hoàn thành bài học');
                await streak.save();
            }
        } catch (streakError) {
            console.error('⚠️ Lỗi cập nhật streak:', streakError);
        }

        res.json(convertDatesToVietnam(progress));
    } catch (error) {
        console.error('Error completing lesson:', error);
        res.status(500).json({ message: 'Lỗi server', error: error.message });
    }
});

// POST /api/lesson-progress/lesson/:lessonId/reset - Reset tiến độ
router.post('/lesson/:lessonId/reset', async (req, res) => {
    try {
        const { lessonId } = req.params;
        const userId = req.user._id;

        await LessonProgress.findOneAndDelete({
            user: userId,
            lesson: lessonId
        });

        res.json({ message: 'Đã reset tiến độ' });
    } catch (error) {
        console.error('Error resetting progress:', error);
        res.status(500).json({ message: 'Lỗi server', error: error.message });
    }
});

// GET /api/lesson-progress/stats - Thống kê tổng quan
router.get('/stats', async (req, res) => {
    try {
        const userId = req.user._id;

        const allProgress = await LessonProgress.find({ user: userId });

        const stats = {
            total_lessons: allProgress.length,
            completed_lessons: allProgress.filter(p => p.is_completed).length,
            in_progress_lessons: allProgress.filter(p => !p.is_completed).length,
            total_vocabularies_learned: allProgress.reduce((sum, p) => sum + p.completed_vocabularies, 0),
            total_grammars_learned: allProgress.reduce((sum, p) => sum + p.completed_grammars, 0),
            total_kanjis_learned: allProgress.reduce((sum, p) => sum + p.completed_kanjis, 0),
        };

        res.json(stats);
    } catch (error) {
        console.error('Error getting stats:', error);
        res.status(500).json({ message: 'Lỗi server', error: error.message });
    }
});

// GET /api/lesson-progress/level/:level - Thống kê theo level
router.get('/level/:level', async (req, res) => {
    try {
        const { level } = req.params;
        const userId = req.user._id;

        // Lấy tất cả lessons của level
        const lessons = await Lesson.find({ level });
        const lessonIds = lessons.map(l => l._id);

        // Lấy progress của user cho các lessons này
        const progressList = await LessonProgress.find({
            user: userId,
            lesson: { $in: lessonIds }
        });

        const stats = {
            level,
            total_lessons: lessons.length,
            started_lessons: progressList.length,
            completed_lessons: progressList.filter(p => p.is_completed).length,
            progress_percentage: lessons.length > 0 
                ? Math.round((progressList.filter(p => p.is_completed).length / lessons.length) * 100)
                : 0
        };

        res.json(stats);
    } catch (error) {
        console.error('Error getting level stats:', error);
        res.status(500).json({ message: 'Lỗi server', error: error.message });
    }
});

export default router;
