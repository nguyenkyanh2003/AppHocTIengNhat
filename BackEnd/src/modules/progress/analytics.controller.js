import User from '../../../model/User.js';
import LessonProgress from '../../../model/LessonProgress.js';
import LearningHistory from '../../../model/LearningHistory.js';

const periodDays = (period) => ({ '7d': 7, '30d': 30, '90d': 90 }[period] || 7);

const dateKey = (date) => date.toISOString().slice(0, 10);

const fillSeries = (days, rows, valueField = 'value') => {
    const values = new Map(rows.map((row) => [row._id, row[valueField]]));
    const labels = [];
    const data = [];
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    for (let offset = days - 1; offset >= 0; offset -= 1) {
        const day = new Date(today);
        day.setDate(day.getDate() - offset);
        const key = dateKey(day);
        labels.push(key);
        data.push(values.get(key) || 0);
    }
    return { labels, data };
};

export const getAdminAnalytics = async (req, res) => {
    try {
        const days = periodDays(req.query.period);
        const start = new Date();
        start.setHours(0, 0, 0, 0);
        start.setDate(start.getDate() - days + 1);
        const today = new Date();
        today.setHours(0, 0, 0, 0);

        const [
            totalUsers,
            activeToday,
            completedLessons,
            totalStudyTime,
            registrations,
            activeUsers,
            lessons,
            studyTime,
            levelDistribution
        ] = await Promise.all([
            User.countDocuments(),
            User.countDocuments({ LanDangNhapCuoi: { $gte: today } }),
            LessonProgress.countDocuments({ is_completed: true, completed_at: { $gte: start } }),
            LearningHistory.aggregate([{ $match: { taken_at: { $gte: start } } }, { $group: { _id: null, seconds: { $sum: '$duration' } } }]),
            User.aggregate([{ $match: { createdAt: { $gte: start } } }, { $group: { _id: { $dateToString: { format: '%Y-%m-%d', date: '$createdAt' } }, value: { $sum: 1 } } }]),
            User.aggregate([{ $match: { LanDangNhapCuoi: { $gte: start } } }, { $group: { _id: { $dateToString: { format: '%Y-%m-%d', date: '$LanDangNhapCuoi' } }, value: { $sum: 1 } } }]),
            LessonProgress.aggregate([{ $match: { is_completed: true, completed_at: { $gte: start } } }, { $group: { _id: { $dateToString: { format: '%Y-%m-%d', date: '$completed_at' } }, value: { $sum: 1 } } }]),
            LearningHistory.aggregate([{ $match: { taken_at: { $gte: start } } }, { $group: { _id: { $dateToString: { format: '%Y-%m-%d', date: '$taken_at' } }, value: { $sum: { $divide: ['$duration', 60] } } } }]),
            User.aggregate([{ $group: { _id: '$TrinhDo', value: { $sum: 1 } } }, { $sort: { _id: 1 } }])
        ]);

        const registrationSeries = fillSeries(days, registrations);
        const activeSeries = fillSeries(days, activeUsers);
        const lessonSeries = fillSeries(days, lessons);
        const studySeries = fillSeries(days, studyTime);

        return res.json({
            period: `${days}d`,
            labels: registrationSeries.labels,
            metrics: {
                total_users: totalUsers,
                active_today: activeToday,
                lessons_completed: completedLessons,
                study_minutes: Math.round((totalStudyTime[0]?.seconds || 0) / 60)
            },
            daily_active_users: activeSeries.data,
            new_registrations: registrationSeries.data,
            lessons_completed: lessonSeries.data,
            total_study_time: studySeries.data.map((value) => Math.round(value)),
            level_distribution: Object.fromEntries(levelDistribution.map((row) => [row._id || 'Chưa đặt', row.value]))
        });
    } catch (error) {
        console.error('Lỗi analytics admin:', error);
        return res.status(500).json({ message: 'Lỗi máy chủ.' });
    }
};
