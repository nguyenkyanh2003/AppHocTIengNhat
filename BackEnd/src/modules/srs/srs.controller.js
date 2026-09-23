import { ok } from '../../shared/http/respond.js';

/**
 * HTTP của SRS: chỉ map request sang service. User luôn lấy từ phiên đăng
 * nhập, không bao giờ từ body hay query.
 *
 * Đợt thẻ đến hạn là ngoại lệ có chủ đích với phân trang chung: `{ data,
 * limit }`, không `page`/`totalPages` — luồng ôn lấy lại đợt đầu kèm tập loại
 * trừ thay vì lật trang (spec SRS §3.4, §6).
 */
export const createSrsController = (service) => ({
  async getDue(req, res) {
    const { item_type: itemType, limit, exclude_item_ids: excludeItemIds } = req.valid.query;
    const batch = await service.dueBatch({ userId: req.user._id, itemType, limit, excludeItemIds });
    ok(res, batch.cards, { limit: batch.limit });
  },

  async getDueCount(req, res) {
    ok(res, await service.dueCount({ userId: req.user._id, itemType: req.valid.query.item_type }));
  },

  async getStats(req, res) {
    ok(res, await service.stats({ userId: req.user._id, itemType: req.valid.query.item_type }));
  },

  async postReview(req, res) {
    const { item_id: itemId, item_type: itemType, is_correct: isCorrect, expected_next_review: expected } =
      req.valid.body;
    const progress = await service.review({
      userId: req.user._id,
      itemId,
      itemType,
      isCorrect,
      expectedNextReview: expected,
    });
    ok(res, progress);
  },

  async postReset(req, res) {
    const { item_type: itemType, expected_next_review: expected } = req.valid.body;
    const progress = await service.reset({
      userId: req.user._id,
      itemId: req.valid.params.itemId,
      itemType,
      expectedNextReview: expected,
    });
    ok(res, progress);
  },

  async deleteItem(req, res) {
    const result = await service.remove({
      userId: req.user._id,
      itemId: req.valid.params.itemId,
      itemType: req.valid.query.item_type,
    });
    ok(res, result);
  },
});

export default createSrsController;
