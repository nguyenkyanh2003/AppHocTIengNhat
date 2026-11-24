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

  /**
   * Gọi **ngoài** transaction, sau khi lượt nộp đã commit: document bài tập là
   * chỗ mọi người học cùng ghi, xem `exercise-submission.service.js`.
   */
  incrementAttempts(id) {
    return exerciseModel.updateOne({ _id: id }, { $inc: { total_attempts: 1 } });
  },
});

export const exerciseSubmissionRepository = createExerciseSubmissionRepository();

export default exerciseSubmissionRepository;
