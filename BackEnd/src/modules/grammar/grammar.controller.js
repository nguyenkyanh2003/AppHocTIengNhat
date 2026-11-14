import { created, ok, paginated } from '../../shared/http/respond.js';

/** Controller chỉ map HTTP <-> service; lỗi do asyncHandler + errorHandler lo. */
export const createGrammarController = (service) => ({
  async list(req, res) {
    return paginated(res, await service.list(req.valid.query));
  },

  async detail(req, res) {
    return ok(res, await service.getDetail(req.valid.params.id));
  },

  async create(req, res) {
    const { grammar, revived } = await service.create(req.valid.body);
    const message = revived ? 'Đã khôi phục ngữ pháp đã xoá với nội dung mới.' : 'Thêm ngữ pháp thành công.';
    return created(res, grammar, { message });
  },

  async update(req, res) {
    const grammar = await service.update(req.valid.params.id, req.valid.body);
    return ok(res, grammar, { message: 'Cập nhật ngữ pháp thành công.' });
  },

  async remove(req, res) {
    await service.remove(req.valid.params.id);
    return ok(res, { deleted: true }, { message: 'Xóa ngữ pháp thành công.' });
  },
});
