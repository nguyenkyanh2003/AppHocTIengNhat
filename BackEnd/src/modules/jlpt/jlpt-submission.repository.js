import mongoose from 'mongoose';

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
/**
 * ID câu hỏi trong bài làm có thể thiếu hoặc không phải ObjectId (câu nằm
 * trong nhóm đọc/nghe không có ID riêng). Sinh ID mới cho những câu đó để bản
 * ghi lịch sử vẫn hợp lệ.
 */
const toQuestionId = (questionId) =>
  questionId && mongoose.Types.ObjectId.isValid(questionId)
    ? new mongoose.Types.ObjectId(String(questionId))
    : new mongoose.Types.ObjectId();

export const createJlptSubmissionRepository = ({
  JLPT: examModel = JLPT,
  LearningHistory: historyModel = LearningHistory,
} = {}) => ({
  findExam(id, { session } = {}) {
    return examModel.findById(id).session(session).lean();
  },

  async saveHistory({ userId, examId, patch }, { session } = {}) {
    const userAnswers = patch.user_answers?.map((answer) => ({ ...answer, question_id: toQuestionId(answer.question_id) }));
    return historyModel.findOneAndUpdate(
      { user: userId, exam: examId },
      { $set: { ...patch, ...(userAnswers && { user_answers: userAnswers }) } },
      { upsert: true, new: true, setDefaultsOnInsert: true, session },
    );
  },
});

export const jlptSubmissionRepository = createJlptSubmissionRepository();

export default jlptSubmissionRepository;
