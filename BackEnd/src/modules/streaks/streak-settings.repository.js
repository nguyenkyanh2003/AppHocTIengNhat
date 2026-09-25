import StreakSettings from '../../../model/StreakSettings.js';
import { isDuplicateKeyError } from '../../shared/db/duplicate-key.js';

/**
 * Truy cập cài đặt mục tiêu ngày và nhắc học.
 *
 * Không chạy trong transaction: mỗi lần lưu chỉ đụng một document, và chống
 * ghi đè giữa hai thiết bị đã có CAS trên `revision`.
 */
export const createStreakSettingsRepository = ({
  StreakSettings: settingsModel = StreakSettings,
} = {}) => ({
  findByUser({ userId }) {
    return settingsModel.findOne({ user: userId }).lean();
  },

  /**
   * Tạo bản cài đặt đầu tiên. Trả `null` khi một request khác vừa tạo trước —
   * caller đọc lại rồi đi đường CAS. Mảng `[doc]` để `create` luôn trả mảng,
   * cùng một hình dạng dù chèn một hay nhiều.
   */
  async create({ userId, fields }) {
    try {
      const [created] = await settingsModel.create([{ user: userId, ...fields, revision: 1 }]);
      return created.toObject();
    } catch (error) {
      if (isDuplicateKeyError(error)) return null;
      throw error;
    }
  },

  /** Ghi có điều kiện: chỉ thành công khi `revision` vẫn đúng bằng giá trị vừa đọc. */
  cas({ userId, expectedRevision, patch }) {
    return settingsModel.findOneAndUpdate(
      { user: userId, revision: expectedRevision },
      { $set: patch, $inc: { revision: 1 } },
      { new: true, runValidators: true, lean: true },
    );
  },
});

export const streakSettingsRepository = createStreakSettingsRepository();

export default streakSettingsRepository;
