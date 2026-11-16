import JLPT from '../../../model/JLPT.js';
import LearningHistory from '../../../model/LearningHistory.js';

/** Người học chỉ thấy đề đã xuất bản và còn hoạt động. */
const PUBLISHED = { is_published: true, is_active: true };
const NEWEST_FIRST = { year: -1, month: -1, createdAt: -1, _id: -1 };

/** Truy vấn Mongoose để xem đề, đáp án và luyện nhanh. Phần nộp đề ở `jlpt-submission.repository.js`. */
export const createJlptRepository = ({ JLPT: examModel = JLPT, LearningHistory: historyModel = LearningHistory } = {}) => ({
  findPublishedPage({ filter, skip, limit }) {
    return examModel.find({ ...filter, ...PUBLISHED }).sort(NEWEST_FIRST).skip(skip).limit(limit).lean();
  },

  countPublished(filter) {
    return examModel.countDocuments({ ...filter, ...PUBLISHED });
  },

  /** Kết quả gần nhất của người học trên từng đề (mỗi cặp người–đề một bản ghi). */
  findLatestResults({ userId, examIds }) {
    return historyModel
      .find({ user: userId, exam: { $in: examIds } })
      .select('exam score is_passed taken_at createdAt')
      .lean();
  },

  /** Đọc đề và cộng một lượt xem trong cùng một lệnh. */
  findPublishedAndCountView(id) {
    return examModel.findOneAndUpdate({ _id: id, ...PUBLISHED }, { $inc: { total_views: 1 } }, { new: true }).lean();
  },

  findPublished(id) {
    return examModel.findOne({ _id: id, ...PUBLISHED }).lean();
  },

  async hasResult({ userId, examId }) {
    return Boolean(await historyModel.exists({ user: userId, exam: examId }));
  },

  /** Chỉ lấy một phần thi của mọi đề phù hợp: đủ để rút câu luyện nhanh. */
  findPracticeSections({ type, level }) {
    return examModel
      .find({ ...PUBLISHED, ...(level && { level }) })
      .select(`level title sections.${type}`)
      .lean();
  },
});

export const jlptRepository = createJlptRepository();
