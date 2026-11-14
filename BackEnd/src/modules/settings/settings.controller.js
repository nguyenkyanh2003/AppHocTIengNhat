import { ok } from '../../shared/http/respond.js';

/** Cài đặt luôn là của người đang đăng nhập (`req.user`), không bao giờ lấy từ body. */
export const createSettingsController = (service) => ({
  async get(req, res) {
    return ok(res, await service.get(req.user._id));
  },

  async save(req, res) {
    const settings = await service.save({ userId: req.user._id, settings: req.valid.body });
    return ok(res, settings, { message: 'Cài đặt đã được cập nhật.' });
  },
});
