import Notification from '../../../model/Notification.js';
import User from '../../../model/User.js';

/** Người học còn nhận được thông báo chung: không phải admin, chưa bị khoá hay cấm. */
const BROADCAST_AUDIENCE = Object.freeze({ VaiTro: 'user', TrangThai: { $nin: ['locked', 'banned'] } });

/**
 * Mọi truy vấn Mongoose của thông báo. Thao tác trên một thông báo luôn kèm
 * `recipient` trong điều kiện, để không bao giờ chạm bản ghi của người khác.
 */
export const createNotificationRepository = ({ Notification: model, User: userModel }) => ({
  findPage({ filter, skip, limit }) {
    return model.find(filter).sort({ createdAt: -1, _id: -1 }).skip(skip).limit(limit).lean();
  },

  count(filter) {
    return model.countDocuments(filter);
  },

  /** Chỉ khớp bản **chưa đọc**, nên đọc lại không ghi đè `read_at`; `null` khi không khớp. */
  markRead({ id, recipient, readAt }) {
    return model
      .findOneAndUpdate(
        { _id: id, recipient, is_read: false },
        { $set: { is_read: true, read_at: readAt } },
        { new: true },
      )
      .lean();
  },

  findOwned({ id, recipient }) {
    return model.findOne({ _id: id, recipient }).lean();
  },

  async markAllRead({ recipient, readAt }) {
    const result = await model.updateMany(
      { recipient, is_read: false },
      { $set: { is_read: true, read_at: readAt } },
    );
    return result.modifiedCount;
  },

  async deleteOwned({ id, recipient }) {
    const result = await model.deleteOne({ _id: id, recipient });
    return result.deletedCount;
  },

  async create(doc) {
    const created = await model.create(doc);
    return created.toObject();
  },

  async insertMany(docs) {
    const created = await model.insertMany(docs);
    return created.length;
  },

  async userExists(id) {
    return Boolean(await userModel.exists({ _id: id }));
  },

  async findBroadcastRecipientIds() {
    const users = await userModel.find(BROADCAST_AUDIENCE).select('_id').lean();
    return users.map((user) => user._id);
  },
});

export const notificationRepository = createNotificationRepository({ Notification, User });
