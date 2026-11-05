import { convertUserDatesToVietnam } from '../../shared/utils/timezone.js';

/**
 * Controller của bốn luồng xác thực: chỉ map HTTP <-> service.
 *
 * Vỏ response (`{ message, user, token, streak }`) giữ nguyên như bản cũ vì
 * Flutter client đang đọc trực tiếp `token` và `user` ở mức trên cùng; đổi sang
 * `{ data }` sẽ làm gãy đăng nhập mà không đem lại lợi ích nào cho phạm vi này.
 */
/** Access token trong header `Authorization: Bearer ...`, nếu có. */
const bearerToken = (req) => {
  const [scheme, token] = String(req.headers.authorization ?? '').split(' ');
  return scheme === 'Bearer' && token ? token : undefined;
};

export const createUserAuthController = (service) => ({
  async login(req, res) {
    const { user, token, refreshToken, streak } = await service.login(req.valid.body);

    return res.json({
      message: 'Đăng nhập thành công',
      user: convertUserDatesToVietnam(user),
      token,
      refreshToken,
      streak,
    });
  },

  /** Cùng vỏ `{ token, refreshToken }` ở mức trên cùng như đăng nhập. */
  async refresh(req, res) {
    const { token, refreshToken } = await service.refresh(req.valid.body);
    return res.json({ token, refreshToken });
  },

  /** Không qua middleware xác thực: access token hết hạn vẫn phải đăng xuất được. */
  async logout(req, res) {
    const result = await service.logout({
      refreshToken: req.valid.body.refreshToken,
      accessToken: bearerToken(req),
    });
    return res.json(result);
  },

  async forgotPassword(req, res) {
    const result = await service.forgotPassword(req.valid.body);
    return res.json(result);
  },

  async resetPassword(req, res) {
    const result = await service.resetPassword(req.valid.body);
    return res.json(result);
  },

  async changePassword(req, res) {
    const result = await service.changePassword({
      actor: req.user,
      targetUserId: req.valid.params.id,
      ...req.valid.body,
    });

    return res.json(result);
  },
});

export default createUserAuthController;
