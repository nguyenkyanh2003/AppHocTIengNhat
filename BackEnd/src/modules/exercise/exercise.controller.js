import { created, list, ok, paginated } from '../../shared/http/respond.js';

/**
 * Bài tập: xem đề, nộp bài, xem lại kết quả. Người làm bài luôn lấy từ phiên
 * đăng nhập (`req.user`).
 *
 * Phần nộp bài (chấm, lưu, chống nộp trùng, ghi hoạt động học) ở
 * `exercise-submission.service.js`; phần còn lại ở `exercise.service.js`.
 */
export const createExerciseController = ({ service, submission }) => ({
  async listByLevel(req, res) {
    return list(res, await service.listByLevel(req.valid.params.level));
  },

  async listByLesson(req, res) {
    return list(res, await service.listByLesson(req.valid.params.lessonID));
  },

  async detail(req, res) {
    return ok(res, await service.detail(req.valid.params.id));
  },

  async submit(req, res) {
    const { attempt_id: attemptId, answers, timeSpent } = req.valid.body;
    const { result, replayed } = await submission.submit({
      userId: req.user._id,
      exerciseId: req.valid.params.id,
      attemptId,
      answers,
      timeSpent,
    });
    // Gửi lại đúng lượt làm cũ không tạo thêm gì, nên không phải 201.
    return replayed ? ok(res, result) : created(res, result);
  },

  async history(req, res) {
    return paginated(res, await service.history({ userId: req.user._id, ...req.valid.query }));
  },

  async result(req, res) {
    return ok(res, await service.result({ userId: req.user._id, id: req.valid.params.resultId }));
  },
});
