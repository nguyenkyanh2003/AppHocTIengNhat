import { created, ok, paginated } from '../../shared/http/respond.js';

/**
 * Controller chỉ map HTTP <-> service: người dùng luôn lấy từ phiên đăng nhập
 * (`req.user`), không bao giờ từ body hay query.
 */
export const createNotificationController = (service) => ({
  async list(req, res) {
    const result = await service.list({ userId: req.user._id, ...req.valid.query });
    return paginated(res, result);
  },

  async countUnread(req, res) {
    const unreadCount = await service.countUnread(req.user._id);
    return ok(res, { unread_count: unreadCount });
  },

  async markRead(req, res) {
    const notification = await service.markRead({ id: req.valid.params.id, userId: req.user._id });
    return ok(res, notification);
  },

  async markAllRead(req, res) {
    const updated = await service.markAllRead(req.user._id);
    return ok(res, { updated });
  },

  async remove(req, res) {
    await service.remove({ id: req.valid.params.id, userId: req.user._id });
    return ok(res, { deleted: true });
  },

  async send(req, res) {
    const { recipient_id: recipientId, ...content } = req.valid.body;
    const notification = await service.sendToUser({ recipientId, senderId: req.user._id, ...content });
    return created(res, notification);
  },

  async broadcast(req, res) {
    const sent = await service.broadcast({ senderId: req.user._id, ...req.valid.body });
    return created(res, { sent });
  },
});
