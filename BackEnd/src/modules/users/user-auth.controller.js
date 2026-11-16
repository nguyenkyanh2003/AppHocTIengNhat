import { ok } from '../../shared/http/respond.js';

/** Access token trong header `Authorization: Bearer ...`, nếu có. */
const bearerToken = (req) => {
  const [scheme, token] = String(req.headers.authorization ?? '').split(' ');
  return scheme === 'Bearer' && token ? token : undefined;
};

/**
 * Controller của các luồng xác thực: chỉ map HTTP <-> service.
 *
 * Phiên (`token`, `refreshToken`) và người dùng nằm trong `data` như mọi
 * response khác; thao tác không có tài nguyên trả một cờ cho biết đã xong.
 */
export const createUserAuthController = (service) => ({
  async login(req, res) {
    return ok(res, await service.login(req.valid.body), { message: 'Đăng nhập thành công' });
  },

  async refresh(req, res) {
    return ok(res, await service.refresh(req.valid.body));
  },

  /** Không qua middleware xác thực: access token hết hạn vẫn phải đăng xuất được. */
  async logout(req, res) {
    const { message } = await service.logout({
      refreshToken: req.valid.body.refreshToken,
      accessToken: bearerToken(req),
    });
    return ok(res, { loggedOut: true }, { message });
  },

  /** Cùng một câu trả lời dù email có tồn tại hay không. */
  async forgotPassword(req, res) {
    const { message } = await service.forgotPassword(req.valid.body);
    return ok(res, { requested: true }, { message });
  },

  async resetPassword(req, res) {
    const { message } = await service.resetPassword(req.valid.body);
    return ok(res, { reset: true }, { message });
  },

  async changePassword(req, res) {
    const { message } = await service.changePassword({
      actor: req.user,
      targetUserId: req.valid.params.id,
      ...req.valid.body,
    });
    return ok(res, { changed: true }, { message });
  },
});

export default createUserAuthController;
