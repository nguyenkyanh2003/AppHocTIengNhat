import { created, ok, paginated } from '../../shared/http/respond.js';

/** Người giao dịch luôn lấy từ phiên đăng nhập (`req.user`), không bao giờ từ body. */
export const createTransactionController = (service) => ({
  async create(req, res) {
    const transaction = await service.create({ userId: req.user._id, input: req.valid.body });
    return created(res, transaction, { message: 'Đã tạo yêu cầu giao dịch.' });
  },

  async listAll(req, res) {
    return paginated(res, await service.listAll(req.valid.query));
  },

  async updateStatus(req, res) {
    const transaction = await service.updateStatus({ id: req.valid.params.id, ...req.valid.body });
    return ok(res, transaction, { message: 'Cập nhật trạng thái thành công.' });
  },
});
