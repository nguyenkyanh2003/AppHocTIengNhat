import { ApiError } from '../../shared/http/api-error.js';
import { created, list, ok, paginated } from '../../shared/http/respond.js';

/** Người học luôn lấy từ phiên đăng nhập (`req.user`), không bao giờ từ body. */
export const createKanjiController = (service) => ({
  async list(req, res) {
    return paginated(res, await service.list(req.valid.query));
  },

  async search(req, res) {
    return list(res, await service.search(req.valid.query));
  },

  async getById(req, res) {
    return ok(res, await service.getDetail({ id: req.valid.params.id, userId: req.user._id }));
  },

  async markLearned(req, res) {
    const { progress, created: isNew } = await service.markLearned({ id: req.valid.params.id, userId: req.user._id });
    return ok(res, progress, {
      message: isNew ? 'Đã thêm chữ này vào lịch ôn tập.' : 'Chữ này đã có trong lịch ôn tập.',
    });
  },

  async unmarkLearned(req, res) {
    await service.unmarkLearned({ id: req.valid.params.id, userId: req.user._id });
    return ok(res, { deleted: true }, { message: 'Đã gỡ chữ này khỏi lịch ôn tập.' });
  },

  async create(req, res) {
    return created(res, await service.create(req.valid.body), { message: 'Thêm Kanji thành công.' });
  },

  async update(req, res) {
    const kanji = await service.update(req.valid.params.id, req.valid.body);
    return ok(res, kanji, { message: 'Cập nhật Kanji thành công.' });
  },

  async importSheet(req, res) {
    if (!req.file) throw ApiError.badRequest('Vui lòng tải lên file Excel.');
    const result = await service.importSheet(req.file.buffer);
    return created(res, result, { message: `Đã thêm ${result.insertedCount} chữ Kanji từ file Excel.` });
  },

  async deleteById(req, res) {
    await service.remove(req.valid.params.id);
    return ok(res, { deleted: true }, { message: 'Xóa Kanji thành công.' });
  },
});
