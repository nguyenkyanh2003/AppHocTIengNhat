import JLPT from '../../../model/JLPT.js';
import LearningHistory from '../../../model/LearningHistory.js';

/**
 * Truy vấn Mongoose của việc nộp đề JLPT.
 *
 * `LearningHistory` giữ **một** bản ghi cho mỗi cặp (người học, đề), nên nó
 * là "kết quả gần nhất" chứ không phải nhật ký từng lượt thi. Điểm của từng
 * lượt nằm trong receipt của `ActivityEvent`; ở đây chỉ cập nhật bản ghi gần
 * nhất, đúng như hành vi cũ.
 */
export const createJlptSubmissionRepository = ({
  JLPT: examModel = JLPT,
  LearningHistory: historyModel = LearningHistory,
} = {}) => ({
  findExam(id, { session } = {}) {
    return examModel.findById(id).session(session).lean();
  },

  async saveHistory({ userId, examId, patch }, { session } = {}) {
    return historyModel.findOneAndUpdate(
      { user: userId, exam: examId },
      { $set: patch },
      { upsert: true, new: true, setDefaultsOnInsert: true, session },
    );
  },
});

export const jlptSubmissionRepository = createJlptSubmissionRepository();

export default jlptSubmissionRepository;
