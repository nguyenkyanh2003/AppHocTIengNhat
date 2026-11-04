import mongoose from 'mongoose';

import Exercise from '../../../model/Exercise.js';
import ExerciseResult from '../../../model/ExerciseResult.js';
import LearningHistory from '../../../model/LearningHistory.js';
import Lesson from '../../../model/Lesson.js';
import LessonProgress from '../../../model/LessonProgress.js';
import User from '../../../model/User.js';
import { STREAK_TIMEZONE } from '../streaks/streak-rules.js';

/** `aggregate` không ép kiểu `user` như `find`; so chuỗi với ObjectId ra 0 dòng. */
const toObjectId = (value) =>
  value instanceof mongoose.Types.ObjectId ? value : new mongoose.Types.ObjectId(String(value));

/** Khoá ngày `YYYY-MM-DD` theo giờ Việt Nam — cùng cách chia ngày với streak. */
const dayOf = (field) => ({
  $dateToString: { format: '%Y-%m-%d', date: `$${field}`, timezone: STREAK_TIMEZONE },
});

const totalOf = async (rows) => (await rows)[0]?.seconds ?? 0;

/**
 * Mọi truy vấn Mongoose của thống kê học tập — chỉ đọc.
 *
 * Tên trường đối chiếu với `BackEnd/model/`: `ExerciseResult` dùng `user_id`,
 * `is_passed`, `completed_at`; `LessonProgress` dùng `user`, `lesson`;
 * `LearningHistory` là lượt thi JLPT với `taken_at`, `duration` (giây).
 */
export const createProgressRepository = ({
  ExerciseResult: resultModel = ExerciseResult,
  Exercise: exerciseModel = Exercise,
  LessonProgress: progressModel = LessonProgress,
  Lesson: lessonModel = Lesson,
  LearningHistory: historyModel = LearningHistory,
  User: userModel = User,
} = {}) => ({
  /** Tổng số giây làm bài tập của user. */
  sumExerciseSeconds(userId) {
    return totalOf(
      resultModel.aggregate([
        { $match: { user_id: toObjectId(userId) } },
        { $group: { _id: null, seconds: { $sum: '$time_spent' } } },
      ]),
    );
  },

  findExerciseResultsBetween({ userId, from, to }) {
    return resultModel
      .find({ user_id: userId, completed_at: { $gte: from, $lt: to } })
      .select('completed_at time_spent')
      .lean();
  },

  findLessonsStudiedBetween({ userId, from, to }) {
    return progressModel
      .find({ user: userId, last_studied_at: { $gte: from, $lt: to } })
      .select('last_studied_at')
      .lean();
  },

  /** `[{ _id: level, completed, in_progress }]`, N5 trước. */
  lessonsByLevel(userId) {
    return progressModel.aggregate([
      { $match: { user: toObjectId(userId) } },
      {
        $lookup: {
          from: lessonModel.collection.name,
          localField: 'lesson',
          foreignField: '_id',
          as: 'lesson',
        },
      },
      { $unwind: '$lesson' },
      {
        $group: {
          _id: '$lesson.level',
          completed: { $sum: { $cond: ['$is_completed', 1, 0] } },
          in_progress: { $sum: { $cond: ['$is_completed', 0, 1] } },
        },
      },
      { $sort: { _id: -1 } },
    ]);
  },

  /** `[{ _id: type, count, average_score, passed }]` — đếm theo lượt nộp. */
  exercisesByType(userId) {
    return resultModel.aggregate([
      { $match: { user_id: toObjectId(userId) } },
      {
        $lookup: {
          from: exerciseModel.collection.name,
          localField: 'exercise_id',
          foreignField: '_id',
          as: 'exercise',
        },
      },
      { $unwind: '$exercise' },
      {
        $group: {
          _id: '$exercise.type',
          count: { $sum: 1 },
          average_score: { $avg: '$score' },
          passed: { $sum: { $cond: ['$is_passed', 1, 0] } },
        },
      },
      { $sort: { _id: 1 } },
    ]);
  },

  countUsers() {
    return userModel.countDocuments();
  },

  countUsersActiveSince({ since }) {
    return userModel.countDocuments({ LanDangNhapCuoi: { $gte: since } });
  },

  countLessonsCompletedSince({ since }) {
    return progressModel.countDocuments({ is_completed: true, completed_at: { $gte: since } });
  },

  sumExamSecondsSince({ since }) {
    return totalOf(
      historyModel.aggregate([
        { $match: { taken_at: { $gte: since } } },
        { $group: { _id: null, seconds: { $sum: '$duration' } } },
      ]),
    );
  },

  dailyRegistrations({ since }) {
    return userModel.aggregate([
      { $match: { createdAt: { $gte: since } } },
      { $group: { _id: dayOf('createdAt'), value: { $sum: 1 } } },
    ]);
  },

  /** User có lần đăng nhập **cuối** rơi vào từng ngày — model không lưu lịch sử đăng nhập. */
  dailyActiveUsers({ since }) {
    return userModel.aggregate([
      { $match: { LanDangNhapCuoi: { $gte: since } } },
      { $group: { _id: dayOf('LanDangNhapCuoi'), value: { $sum: 1 } } },
    ]);
  },

  dailyLessonsCompleted({ since }) {
    return progressModel.aggregate([
      { $match: { is_completed: true, completed_at: { $gte: since } } },
      { $group: { _id: dayOf('completed_at'), value: { $sum: 1 } } },
    ]);
  },

  dailyExamMinutes({ since }) {
    return historyModel.aggregate([
      { $match: { taken_at: { $gte: since } } },
      { $group: { _id: dayOf('taken_at'), value: { $sum: { $divide: ['$duration', 60] } } } },
    ]);
  },

  levelDistribution() {
    return userModel.aggregate([
      { $group: { _id: '$TrinhDo', value: { $sum: 1 } } },
      { $sort: { _id: 1 } },
    ]);
  },
});

export const progressRepository = createProgressRepository();

export default progressRepository;
