import { ApiError } from '../../shared/http/api-error.js';
import { created, ok, paginated } from '../../shared/http/respond.js';

/**
 * Đăng ký, hồ sơ và quản trị người dùng. Người thao tác luôn lấy từ phiên đăng
 * nhập (`req.user`). Các luồng xác thực ở `user-auth.controller.js`.
 */
export const createUserController = (service) => ({
  async register(req, res) {
    return created(res, await service.register(req.valid.body), { message: 'Đăng ký thành công' });
  },

  async profile(req, res) {
    return ok(res, await service.profile({ actor: req.user, userId: req.valid.params.id }));
  },

  async updateProfile(req, res) {
    const user = await service.updateProfile({ actor: req.user, userId: req.valid.params.id, changes: req.valid.body });
    return ok(res, user, { message: 'Cập nhật thông tin thành công' });
  },

  async setAvatar(req, res) {
    if (!req.file) throw ApiError.badRequest('Vui lòng chọn file ảnh.');
    const user = await service.setAvatar({ actor: req.user, userId: req.valid.params.userID, image: req.file.buffer });
    return ok(res, user, { message: 'Cập nhật ảnh đại diện thành công' });
  },

  async adminList(req, res) {
    return paginated(res, await service.adminList(req.valid.query));
  },

  async adminUpdate(req, res) {
    const user = await service.adminUpdate({ userId: req.valid.params.id, changes: req.valid.body });
    return ok(res, user, { message: 'Cập nhật người dùng thành công' });
  },

  async adminRemove(req, res) {
    await service.adminRemove({ actor: req.user, userId: req.valid.params.id });
    return ok(res, { deleted: true }, { message: 'Xóa người dùng thành công' });
  },

  async adminStats(_req, res) {
    return ok(res, await service.adminStats());
  },
});
