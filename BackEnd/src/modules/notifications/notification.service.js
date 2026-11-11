import { ApiError } from '../../shared/http/api-error.js';
import { notificationRepository } from './notification.repository.js';

const READ_FILTER = Object.freeze({ all: {}, read: { is_read: true }, unread: { is_read: false } });

/** Thông báo như client thấy (phase-2-plan A7 #6). */
export const toNotificationDto = (notification) => ({
  id: String(notification._id),
  title: notification.title,
  message: notification.message,
  type: notification.type,
  data: notification.data ?? {},
  is_read: Boolean(notification.is_read),
  read_at: notification.read_at ? new Date(notification.read_at).toISOString() : null,
  created_at: new Date(notification.createdAt).toISOString(),
});

const notFound = () => ApiError.notFound('Không tìm thấy thông báo.');

/** Nội dung thông báo nhận huy hiệu: mô tả là tiêu chí vừa đạt, kèm XP nếu có. */
const achievementMessage = ({ name, description }, xp) => {
  const reward = xp > 0 ? ` và được cộng ${xp} XP` : '';
  const criterion = description?.trim();
  return criterion
    ? `Bạn đã hoàn thành "${criterion}"${reward}.`
    : `Chúc mừng bạn đã nhận huy hiệu "${name}"${reward}.`;
};

/**
 * Thông báo cá nhân. Mọi thao tác của người dùng chỉ chạm bản ghi có
 * `recipient` là chính họ: thông báo của người khác trả 404 như không tồn tại.
 *
 * Service không biết `req`/`res` và không import model: truy vấn đi qua
 * repository được tiêm vào, nên test chỉ cần repository giả.
 */
export const createNotificationService = ({
  notificationRepository: repository,
  clock = () => new Date(),
}) => ({
  async list({ userId, page, limit, status, type }) {
    const filter = { recipient: userId, ...READ_FILTER[status], ...(type ? { type } : {}) };
    const [items, total] = await Promise.all([
      repository.findPage({ filter, skip: (page - 1) * limit, limit }),
      repository.count(filter),
    ]);
    return { items: items.map(toNotificationDto), page, limit, total };
  },

  countUnread(userId) {
    return repository.count({ recipient: userId, is_read: false });
  },

  /** Đọc lại một thông báo đã đọc không đổi `read_at` của lần đọc đầu. */
  async markRead({ id, userId }) {
    const owner = { id, recipient: userId };
    const notification =
      (await repository.markRead({ ...owner, readAt: clock() })) ?? (await repository.findOwned(owner));
    if (!notification) throw notFound();
    return toNotificationDto(notification);
  },

  /** Số thông báo vừa chuyển sang đã đọc; không còn gì chưa đọc là 0, không phải lỗi. */
  markAllRead(userId) {
    return repository.markAllRead({ recipient: userId, readAt: clock() });
  },

  async remove({ id, userId }) {
    const deleted = await repository.deleteOwned({ id, recipient: userId });
    if (deleted === 0) throw notFound();
  },

  async sendToUser({ recipientId, senderId, title, message, type }) {
    if (!(await repository.userExists(recipientId))) {
      throw ApiError.notFound('Không tìm thấy người nhận.');
    }
    const notification = await repository.create({ recipient: recipientId, sender: senderId, title, message, type });
    return toNotificationDto(notification);
  },

  /**
   * Báo người học vừa nhận một huy hiệu. Cổng ghi streak gọi trong **cùng
   * transaction** cấp huy hiệu (`session`): huy hiệu và thông báo cùng được ghi
   * hoặc cùng huỷ, và khoá cấp một lần của huy hiệu giữ thông báo chỉ một lần.
   */
  async achievementUnlocked({ userId, achievement, xp, session }) {
    const notification = await repository.create(
      {
        recipient: userId,
        sender: null,
        type: 'ACHIEVEMENT',
        title: `Huy hiệu mới: ${achievement.name}`,
        message: achievementMessage(achievement, xp),
        data: {
          achievement_id: achievement.id,
          name: achievement.name,
          icon: achievement.icon,
          rarity: achievement.rarity,
          xp,
        },
      },
      { session },
    );
    return toNotificationDto(notification);
  },

  /**
   * Một bản ghi cho mỗi người học còn hoạt động, để đọc/xoá của từng người độc
   * lập. Trả số người đã gửi; không có ai thì là 0.
   */
  async broadcast({ senderId, title, message, type }) {
    const recipients = await repository.findBroadcastRecipientIds();
    if (recipients.length === 0) return 0;
    return repository.insertMany(
      recipients.map((recipient) => ({ recipient, sender: senderId, title, message, type })),
    );
  },
});

export const notificationService = createNotificationService({ notificationRepository });
