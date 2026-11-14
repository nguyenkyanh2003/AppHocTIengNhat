import { created, ok, paginated } from '../../shared/http/respond.js';

/** Người gửi luôn lấy từ phiên đăng nhập (`req.user`), không bao giờ từ body. */
export const createReportController = (service) => ({
  async create(req, res) {
    const report = await service.create({ userId: req.user._id, input: req.valid.body });
    return created(res, report, { message: 'Gửi báo cáo thành công. Chúng tôi sẽ xử lý trong thời gian sớm nhất.' });
  },

  async listMine(req, res) {
    return paginated(res, await service.listMine({ userId: req.user._id, ...req.valid.query }));
  },

  async listAll(req, res) {
    const { page, limit, status, type, priority, user_id: userId } = req.valid.query;
    return paginated(res, await service.listAll({ page, limit, status, type, priority, userId }));
  },

  async updateStatus(req, res) {
    const { status, admin_response: adminResponse } = req.valid.body;
    const report = await service.updateStatus({ id: req.valid.params.id, status, adminResponse });
    return ok(res, report, { message: 'Cập nhật trạng thái báo cáo thành công.' });
  },

  async remove(req, res) {
    await service.remove(req.valid.params.id);
    return ok(res, { deleted: true }, { message: 'Xóa báo cáo thành công.' });
  },

  async stats(_req, res) {
    return ok(res, await service.stats());
  },
});
