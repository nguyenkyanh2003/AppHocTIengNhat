import Grammar from '../../../model/Grammar.js';
import Kanji from '../../../model/Kanji.js';
import Lesson from '../../../model/Lesson.js';
import Vocabulary from '../../../model/Vocabulary.js';

/**
 * Mọi truy vấn Mongoose của domain bài học, kể cả truy vấn chéo sang
 * Vocabulary/Grammar/Kanji khi cần đếm hoặc lấy nội dung liên quan.
 *
 * Ba model liên quan dùng ba tên field khác nhau để trỏ về Lesson —
 * `Vocabulary.lesson`, `Grammar.lesson_id`, `Kanji.lessonId` — đây là nơi
 * duy nhất phải nhớ đúng cả ba, service không được biết chi tiết này.
 */
/**
 * Danh sách chỉ cần đủ để dựng thẻ bài học. Lời thoại theo từng giây của video
 * và nội dung HTML là phần nặng nhất của một bài và chỉ màn chi tiết dùng —
 * gửi kèm danh sách thì mỗi lần mở trang Bài học phải tải và giải mã vô ích.
 */
export const LESSON_LIST_PROJECTION = Object.freeze({ content_html: 0, 'videos.transcript': 0 });

export const createLessonRepository = ({
  Lesson: lessonModel,
  Vocabulary: vocabularyModel,
  Grammar: grammarModel,
  Kanji: kanjiModel,
}) => ({
  findMany({ filter, sort, skip, limit }) {
    return lessonModel
      .find(filter, LESSON_LIST_PROJECTION)
      .sort(sort)
      .skip(skip)
      .limit(limit)
      .lean();
  },

  count(filter) {
    return lessonModel.countDocuments(filter);
  },

  findById(id) {
    return lessonModel
      .findById(id)
      .populate('vocabularies')
      .populate('grammars')
      .populate('kanjis')
      .lean();
  },

  findVocabulariesByLesson(lessonId) {
    return vocabularyModel.find({ lesson: lessonId }).lean();
  },

  findActiveGrammarsByLesson(lessonId) {
    return grammarModel.find({ lesson_id: lessonId, is_active: true }).lean();
  },

  findKanjisByLesson(lessonId) {
    return kanjiModel.find({ lessonId }).lean();
  },

  findByLevel(level) {
    return lessonModel.find({ level }).sort({ order: 1 }).lean();
  },

  /**
   * Tình huống đang thực sự có bài học — bỏ bài chưa gắn tình huống. Có `level`
   * thì chỉ lấy chủ đề có bài ở đúng cấp đó.
   */
  distinctSituations({ level } = {}) {
    const filter = { situation: { $ne: null } };
    if (level) filter.level = level;
    return lessonModel.distinct('situation', filter);
  },

  findByTypePattern(regexFilter) {
    return lessonModel
      .find({ type: regexFilter })
      .sort({ level: -1, order: 1 })
      .lean();
  },

  async aggregateStats() {
    const [totalLessons, byLevel, byType] = await Promise.all([
      lessonModel.countDocuments(),
      lessonModel.aggregate([
        { $group: { _id: '$level', count: { $sum: 1 } } },
        { $sort: { _id: 1 } },
      ]),
      lessonModel.aggregate([
        { $match: { type: { $nin: [null, ''] } } },
        { $group: { _id: '$type', count: { $sum: 1 } } },
        { $sort: { count: -1 } },
      ]),
    ]);

    return { totalLessons, byLevel, byType };
  },

  create(input) {
    return lessonModel.create(input);
  },

  createMany(inputs) {
    return lessonModel.insertMany(inputs);
  },

  updateById(id, input) {
    return lessonModel.findByIdAndUpdate(id, input, {
      new: true,
      runValidators: true,
    });
  },

  findByIdLean(id) {
    return lessonModel.findById(id).lean();
  },

  deleteById(id) {
    return lessonModel.findByIdAndDelete(id);
  },

  async deleteManyByIds(ids) {
    const result = await lessonModel.deleteMany({ _id: { $in: ids } });
    return result.deletedCount;
  },

  async countRelated(lessonIds) {
    const [vocabulary, kanji, grammar] = await Promise.all([
      vocabularyModel.countDocuments({ lesson: { $in: lessonIds } }),
      kanjiModel.countDocuments({ lessonId: { $in: lessonIds } }),
      grammarModel.countDocuments({ lesson_id: { $in: lessonIds } }),
    ]);
    return { vocabulary, kanji, grammar };
  },
});

export const lessonRepository = createLessonRepository({
  Lesson,
  Vocabulary,
  Grammar,
  Kanji,
});

export default lessonRepository;
