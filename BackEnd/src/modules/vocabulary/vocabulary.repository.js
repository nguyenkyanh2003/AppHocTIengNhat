import Vocabulary from '../../../model/Vocabulary.js';
import Lesson from '../../../model/Lesson.js';

const LESSON_FIELDS = 'title level';

/**
 * Mọi truy vấn Mongoose của domain từ vựng.
 *
 * Service chỉ gọi repository, không import model. Nhờ vậy test service chỉ cần
 * truyền một repository giả, không cần MongoDB.
 */
export const createVocabularyRepository = ({
  Vocabulary: vocabularyModel,
  Lesson: lessonModel,
}) => ({
  findPage({ filter, sort, skip, limit }) {
    return vocabularyModel
      .find(filter)
      .populate('lesson', LESSON_FIELDS)
      .sort(sort)
      .skip(skip)
      .limit(limit)
      .lean();
  },

  count(filter) {
    return vocabularyModel.countDocuments(filter);
  },

  findAll({ filter, sort }) {
    return vocabularyModel
      .find(filter)
      .populate('lesson', LESSON_FIELDS)
      .sort(sort)
      .lean();
  },

  findDetailById(id) {
    return vocabularyModel
      .findById(id)
      .populate('lesson', LESSON_FIELDS)
      .populate('related_kanjis')
      .lean();
  },

  findById(id) {
    return vocabularyModel.findById(id).lean();
  },

  findPopulatedById(id) {
    return vocabularyModel
      .findById(id)
      .populate('lesson', LESSON_FIELDS)
      .lean();
  },

  /** Danh sách tình huống sử dụng, bỏ giá trị rỗng/null. */
  distinctUsageContexts() {
    return vocabularyModel.distinct('usage_context', {
      usage_context: { $nin: [null, ''] },
    });
  },

  sample({ filter, size }) {
    return vocabularyModel.aggregate([
      { $match: filter },
      { $sample: { size } },
    ]);
  },

  create(payload) {
    return vocabularyModel.create(payload);
  },

  updateById(id, data) {
    return vocabularyModel
      .findByIdAndUpdate(id, data, { new: true, runValidators: true })
      .populate('lesson', LESSON_FIELDS)
      .lean();
  },

  deleteById(id) {
    return vocabularyModel.findByIdAndDelete(id).lean();
  },

  async deleteManyByIds(ids) {
    const result = await vocabularyModel.deleteMany({ _id: { $in: ids } });
    return result.deletedCount ?? 0;
  },

  insertMany(rows) {
    return vocabularyModel.insertMany(rows);
  },

  lessonExists(lessonId) {
    return lessonModel.exists({ _id: lessonId });
  },

  /** Số liệu tổng quan cho màn quản trị. */
  async stats() {
    const [total, byLevel, bySituation, byLesson, recent] = await Promise.all([
      vocabularyModel.countDocuments(),
      vocabularyModel.aggregate([
        { $group: { _id: '$level', count: { $sum: 1 } } },
        { $sort: { _id: 1 } },
      ]),
      vocabularyModel.aggregate([
        { $match: { usage_context: { $nin: [null, ''] } } },
        { $group: { _id: '$usage_context', count: { $sum: 1 } } },
        { $sort: { count: -1 } },
        { $limit: 10 },
      ]),
      vocabularyModel.aggregate([
        { $group: { _id: '$lesson', count: { $sum: 1 } } },
        { $sort: { count: -1 } },
        { $limit: 10 },
        {
          $lookup: {
            from: 'lessons',
            localField: '_id',
            foreignField: '_id',
            as: 'lessonInfo',
          },
        },
        { $unwind: '$lessonInfo' },
      ]),
      vocabularyModel
        .find()
        .populate('lesson', LESSON_FIELDS)
        .sort({ _id: -1 })
        .limit(10)
        .lean(),
    ]);

    return {
      totalVocabularies: total,
      byLevel,
      bySituation,
      byLesson,
      recentVocabularies: recent,
    };
  },

  findForExport(filter) {
    return vocabularyModel.find(filter).populate('lesson', 'title').lean();
  },
});

export const vocabularyRepository = createVocabularyRepository({
  Vocabulary,
  Lesson,
});

export default vocabularyRepository;
