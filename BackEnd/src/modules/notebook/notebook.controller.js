import { created, ok, paginated } from '../../shared/http/respond.js';

/** Chủ sổ tay luôn lấy từ phiên đăng nhập (`req.user`), không bao giờ từ body. */
export const createNotebookController = (service) => ({
  async list(req, res) {
    return paginated(res, await service.list({ userId: req.user._id, ...req.valid.query }));
  },

  async detail(req, res) {
    return ok(res, await service.detail({ userId: req.user._id, id: req.valid.params.id }));
  },

  async create(req, res) {
    const note = await service.create({ userId: req.user._id, input: req.valid.body });
    return created(res, note, { message: 'Tạo ghi chú thành công.' });
  },

  async update(req, res) {
    const note = await service.update({ userId: req.user._id, id: req.valid.params.id, changes: req.valid.body });
    return ok(res, note, { message: 'Cập nhật ghi chú thành công.' });
  },

  async remove(req, res) {
    await service.remove({ userId: req.user._id, id: req.valid.params.id });
    return ok(res, { deleted: true }, { message: 'Xóa ghi chú thành công.' });
  },
});
