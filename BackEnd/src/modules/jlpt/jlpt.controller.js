import { list, ok, paginated } from '../../shared/http/respond.js';

/**
 * Đề JLPT. Người thi luôn lấy từ phiên đăng nhập (`req.user`).
 *
 * Nộp đề (chấm, lưu kết quả, chống nộp trùng, ghi hoạt động học) ở
 * `jlpt-submission.service.js`; phần còn lại ở `jlpt.service.js`.
 */
export const createJlptController = ({ service, submission }) => ({
  async list(req, res) {
    return paginated(res, await service.list({ userId: req.user._id, ...req.valid.query }));
  },

  async practice(req, res) {
    return list(res, await service.practice(req.valid.query));
  },

  async detail(req, res) {
    return ok(res, await service.detail(req.valid.params.id));
  },

  async solutions(req, res) {
    return ok(res, await service.solutions({ userId: req.user._id, examId: req.valid.params.id }));
  },

  async submit(req, res) {
    const { attempt_id: attemptId, answers, time_spent: timeSpent } = req.valid.body;
    const { result } = await submission.submit({
      userId: req.user._id,
      examId: req.valid.params.id,
      attemptId,
      answers,
      timeSpent,
    });
    return ok(res, result);
  },
});
