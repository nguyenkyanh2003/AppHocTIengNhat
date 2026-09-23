import mongoose from 'mongoose';

import Achievement from '../../../model/Achievement.js';
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

/** `aggregate` không ép kiểu `user` như `find`; so chuỗi với ObjectId ra 0 dòng. */
const toObjectId = (value) =>
  value instanceof mongoose.Types.ObjectId ? value : new mongoose.Types.ObjectId(String(value));

export const createAchievementRepository = ({
  Achievement: achievementModel = Achievement,
  UserAchievement: userAchievementModel = UserAchievement,
  LessonProgress: lessonProgressModel = LessonProgress,
  ExerciseResult: exerciseResultModel = ExerciseResult,
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

    countLearnedVocabulary({ userId, session }) {
      return srsModel.countDocuments({ user: userId, item_type: 'Vocabulary' }).session(session);
    },

    countLearnedKanji: ({ userId, session }) =>
      countDistinctLessonItems({ userId, field: 'learned_kanji_ids', session }),

    countLearnedGrammar: ({ userId, session }) =>
      countDistinctLessonItems({ userId, field: 'learned_grammar_ids', session }),

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
        { $group: { _id: '$definition.category', count: { $sum: 1 } } },
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
