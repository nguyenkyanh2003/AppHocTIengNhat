import Vocabulary from '../../../model/Vocabulary.js';
import Lesson from '../../../model/Lesson.js';
import Kanji from '../../../model/Kanji.js';

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
  Kanji: kanjiModel,
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

  findKanjiByCharacters(characters) {
    if (characters.length === 0) return [];
    return kanjiModel
      .find({ character: { $in: characters } })
      .select('character hanviet meaning')
      .lean();
  },

  /**
   * Từ liên quan để gợi ý học tiếp: từ chứa chung chữ Hán nếu có, không thì
   * cùng chủ đề và cùng cấp. Cùng cấp xếp trước để không gợi ý từ N1 cho
   * người đang học N5.
   */
  async findRelated({ vocabulary, characters, limit }) {
    const fields = 'word hiragana meaning level';
    const filter = characters.length > 0
      ? { word: { $regex: `[${characters.join('')}]` } }
      : vocabulary.topic
        ? { topic: vocabulary.topic, level: vocabulary.level }
        : null;
    if (!filter) return [];

    filter._id = { $ne: vocabulary._id };
    // Tên riêng trong giáo trình (桜大学, ...) không đáng gợi ý để học.
    if (!filter.topic) filter.topic = { $ne: 'proper' };
    const [sameLevel, others] = await Promise.all([
      vocabularyModel.find({ ...filter, level: vocabulary.level }).select(fields).limit(limit).lean(),
      vocabularyModel.find({ ...filter, level: { $ne: vocabulary.level } }).select(fields).limit(limit).lean(),
    ]);
    return [...sameLevel, ...others].slice(0, limit);
  },

  /** Chỉ các trường dùng để chia bộ, theo thứ tự nhập từ giáo trình. */
  findSetFields(level) {
    return vocabularyModel
      .find({ level })
      .select('_id topic word_type difficulty')
      .sort({ _id: 1 })
      .lean();
  },

  /** Trả về theo đúng thứ tự `ids` — thứ tự học trong bộ. */
  async findByIdsInOrder(ids) {
    const docs = await vocabularyModel.find({ _id: { $in: ids } }).lean();
    const byId = new Map(docs.map((doc) => [String(doc._id), doc]));
    return ids.map((id) => byId.get(String(id))).filter(Boolean);
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
  Kanji,
});

export default vocabularyRepository;
