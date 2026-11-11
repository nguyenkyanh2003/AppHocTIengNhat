import mongoose from 'mongoose';

import Achievement from '../../../model/Achievement.js';
import Exercise from '../../../model/Exercise.js';
import ExerciseResult from '../../../model/ExerciseResult.js';
import LessonProgress from '../../../model/LessonProgress.js';
import SRSProgress from '../../../model/SRSProgress.js';
import UserAchievement from '../../../model/UserAchievement.js';

/**
 * Truy cập dữ liệu huy hiệu, và các phép **đếm chỉ đọc** mà tiêu chí huy hiệu
 * cần (từ đã học, bài đã hoàn thành, bài tập đã nộp).
 *
 * Mọi hàm dùng trong cổng ghi hoạt động nhận `session`: huy hiệu được xét
 * trong cùng transaction với hoạt động vừa ghi, nên phép đếm phải thấy cả bản
 * ghi chưa commit của chính transaction đó.
 */

const SORT = { category: 1, requirement_value: 1 };

/** Loại bài tập kiểm tra mẫu câu; bài "Hội thoại" của mỗi bài học thuộc loại `Tổng hợp`. */
const PATTERN_EXERCISE_TYPES = Object.freeze(['Ngữ pháp', 'Tổng hợp']);

/** `aggregate` không ép kiểu `user` như `find`; so chuỗi với ObjectId ra 0 dòng. */
const toObjectId = (value) =>
  value instanceof mongoose.Types.ObjectId ? value : new mongoose.Types.ObjectId(String(value));

export const createAchievementRepository = ({
  Achievement: achievementModel = Achievement,
  UserAchievement: userAchievementModel = UserAchievement,
  LessonProgress: lessonProgressModel = LessonProgress,
  ExerciseResult: exerciseResultModel = ExerciseResult,
  Exercise: exerciseModel = Exercise,
  SRSProgress: srsModel = SRSProgress,
} = {}) => {
  /** Số mục khác nhau user đã học qua mọi bài, ví dụ `learned_kanji_ids`. */
  const countDistinctLessonItems = async ({ userId, field, session }) => {
    const [row] = await lessonProgressModel
      .aggregate([
        { $match: { user: toObjectId(userId) } },
        { $unwind: `$${field}` },
        { $group: { _id: `$${field}` } },
        { $count: 'total' },
      ])
      .session(session);
    return row?.total ?? 0;
  };

  return {
    findActive({ session } = {}) {
      return achievementModel.find({ is_active: true }).sort(SORT).session(session).lean();
    },

    findAll() {
      return achievementModel.find().sort(SORT).lean();
    },

    findActiveByCategory(category) {
      return achievementModel.find({ category, is_active: true }).sort({ requirement_value: 1 }).lean();
    },

    /** Huy hiệu của user kèm định nghĩa; bỏ dòng mà định nghĩa đã bị xoá. */
    async findUserAchievements({ userId, achievementIds }) {
      const filter = { user: userId };
      if (achievementIds) filter.achievement = { $in: achievementIds };
      const rows = await userAchievementModel
        .find(filter)
        .populate('achievement')
        .sort({ is_completed: -1, earned_at: -1 })
        .lean();
      return rows.filter((row) => row.achievement);
    },

    async findCompletedAchievementIds({ userId, session }) {
      const rows = await userAchievementModel
        .find({ user: userId, is_completed: true })
        .select('achievement')
        .session(session)
        .lean();
      return new Set(rows.map((row) => String(row.achievement)));
    },

    /** Ghi huy hiệu đã đạt; upsert vì user chưa từng có dòng tiến độ nào cho nó. */
    markCompleted({ userId, achievementId, progress, earnedAt, session }) {
      return userAchievementModel.updateOne(
        { user: userId, achievement: achievementId },
        { $set: { is_completed: true, progress, earned_at: earnedAt } },
        { upsert: true, runValidators: true, session },
      );
    },

    /**
     * Từ đã học = từ có thẻ ôn **hoặc** đã bấm "Đã nhớ" trong một bài, mỗi từ
     * tính một lần. Chỉ đếm thẻ ôn thì học theo bài không bao giờ làm tăng số
     * này. Hai truy vấn chạy lần lượt: chạy song song trong cùng transaction
     * là cách driver MongoDB khuyên tránh.
     */
    async countLearnedVocabulary({ userId, session }) {
      const inReview = await srsModel
        .distinct('item_id', { user: userId, item_type: 'Vocabulary' })
        .session(session);
      const inLessons = await lessonProgressModel
        .distinct('learned_vocabulary_ids', { user: userId })
        .session(session);
      return new Set([...inReview, ...inLessons].map(String)).size;
    },

    countLearnedKanji: ({ userId, session }) =>
      countDistinctLessonItems({ userId, field: 'learned_kanji_ids', session }),

    /** Số bài tập mẫu câu đã đạt, mỗi bài tính một lần dù làm lại bao nhiêu lần. */
    async countPassedPatternExercises({ userId, session }) {
      const passed = await exerciseResultModel
        .distinct('exercise_id', { user_id: userId, is_passed: true })
        .session(session);
      if (passed.length === 0) return 0;
      return exerciseModel
        .countDocuments({ _id: { $in: passed }, type: { $in: PATTERN_EXERCISE_TYPES } })
        .session(session);
    },

    countCompletedLessons({ userId, session }) {
      return lessonProgressModel.countDocuments({ user: userId, is_completed: true }).session(session);
    },

    countExerciseSubmissions({ userId, session }) {
      return exerciseResultModel.countDocuments({ user_id: userId }).session(session);
    },

    countActive() {
      return achievementModel.countDocuments({ is_active: true });
    },

    countActiveByCategory() {
      return achievementModel.aggregate([
        { $match: { is_active: true } },
        { $group: { _id: '$category', count: { $sum: 1 } } },
      ]);
    },

    countCompletedByCategory(userId) {
      return userAchievementModel.aggregate([
        { $match: { user: toObjectId(userId), is_completed: true } },
        {
          $lookup: {
            from: achievementModel.collection.name,
            localField: 'achievement',
            foreignField: '_id',
            as: 'definition',
          },
        },
        { $unwind: '$definition' },
        { $match: { 'definition.is_active': true } },
        { $group: { _id: '$definition.category', count: { $sum: 1 } } },
      ]);
    },

    /** Mỗi huy hiệu có bao nhiêu người đã mở, cho màn quản trị. */
    countCompletedByAchievement() {
      return userAchievementModel.aggregate([
        { $match: { is_completed: true } },
        { $group: { _id: '$achievement', count: { $sum: 1 } } },
      ]);
    },

    async create(payload) {
      return (await achievementModel.create(payload)).toObject();
    },

    updateById(id, updates) {
      return achievementModel.findByIdAndUpdate(id, updates, { new: true, runValidators: true }).lean();
    },

    /** Xoá định nghĩa cùng tiến độ của mọi user với nó. Trả định nghĩa đã xoá hoặc `null`. */
    async deleteById(id) {
      const deleted = await achievementModel.findByIdAndDelete(id).lean();
      if (deleted) await userAchievementModel.deleteMany({ achievement: deleted._id });
      return deleted;
    },
  };
};

export const achievementRepository = createAchievementRepository();

export default achievementRepository;
