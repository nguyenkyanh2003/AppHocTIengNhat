import Exercise from '../../../model/Exercise.js';
import ExerciseResult from '../../../model/ExerciseResult.js';

/**
 * Truy vấn Mongoose của việc nộp bài tập.
 *
 * Mọi lệnh nhận `session` để bài nộp, số lượt làm và hoạt động học cùng nằm
 * trong một transaction — lưu được kết quả mà không ghi được hoạt động thì
 * người học mất XP, còn ngược lại thì XP không có bài nộp nào đứng sau.
 */
export const createExerciseSubmissionRepository = ({
  Exercise: exerciseModel = Exercise,
  ExerciseResult: resultModel = ExerciseResult,
} = {}) => ({
  findExercise(id, { session } = {}) {
    return exerciseModel.findById(id).session(session).lean();
  },

  /**
   * `create` với mảng một phần tử: theo chính cảnh báo trong mã nguồn Mongoose,
   * `session` ở tham số thứ hai chỉ có tác dụng khi tham số đầu là mảng.
   */
  async createResult(doc, { session } = {}) {
    const [created] = await resultModel.create([doc], { session });
    return created.toObject();
  },

  incrementAttempts(id, { session } = {}) {
    return exerciseModel.updateOne({ _id: id }, { $inc: { total_attempts: 1 } }, { session });
  },
});

export const exerciseSubmissionRepository = createExerciseSubmissionRepository();

export default exerciseSubmissionRepository;
