import User from '../../../model/User.js';
import UserStreak from '../../../model/UserStreak.js';

/**
 * `tokenVersion` khai báo `select: false` trong model, nên mọi truy vấn phục vụ
 * xác thực phải xin thêm trường này một cách tường minh.
 */
const WITH_TOKEN_VERSION = '+tokenVersion';

/**
 * Điều kiện khớp version cho lệnh ghi có điều kiện.
 *
 * Document tạo trước khi `tokenVersion` tồn tại không có trường này. Chính sách
 * đã chọn là coi "thiếu version" bằng `0`, nên khi kỳ vọng version 0 thì cả
 * document thiếu trường cũng phải khớp.
 */
const versionMatch = (expectedVersion) =>
  expectedVersion === 0
    ? { $or: [{ tokenVersion: 0 }, { tokenVersion: { $exists: false } }] }
    : { tokenVersion: expectedVersion };

/**
 * Mọi truy vấn Mongoose của domain người dùng.
 *
 * Repository trả về **plain object** (`.lean()`) để service không cầm document
 * Mongoose và không gọi method của model; nhờ vậy test service chỉ cần một
 * object thường.
 */
export const createUserRepository = ({
  User: userModel = User,
  UserStreak: streakModel = UserStreak,
} = {}) => ({
  findByUsername(username) {
    return userModel
      .findOne({ TenDangNhap: username })
      .select(WITH_TOKEN_VERSION)
      .lean();
  },

  findByEmail(email) {
    return userModel.findOne({ Email: email }).select(WITH_TOKEN_VERSION).lean();
  },

  findById(id) {
    return userModel.findById(id).select(WITH_TOKEN_VERSION).lean();
  },

  touchLastLogin({ id, at }) {
    return userModel
      .findOneAndUpdate(
        { _id: id },
        { $set: { LanDangNhapCuoi: at } },
        { new: true },
      )
      .select(WITH_TOKEN_VERSION)
      .lean();
  },

  /**
   * Đổi mật khẩu và thu hồi phiên cũ trong **một** lệnh ghi có điều kiện.
   *
   * Điều kiện version biến token đặt lại mật khẩu thành dùng-một-lần thật sự:
   * hai request cùng cầm một token thì chỉ request đầu khớp version, request
   * sau không tìm thấy document nào để ghi và nhận `null`.
   */
  replacePasswordIfVersionMatches({ id, expectedVersion, passwordHash }) {
    return userModel
      .findOneAndUpdate(
        { _id: id, ...versionMatch(expectedVersion) },
        { $set: { MatKhau: passwordHash }, $inc: { tokenVersion: 1 } },
        { new: true },
      )
      .select(WITH_TOKEN_VERSION)
      .lean();
  },

  /**
   * Đổi mật khẩu không qua token đặt lại: không cần khớp version, nhưng vẫn
   * tăng version để mọi access token đã phát của tài khoản đích hết hiệu lực.
   */
  replacePassword({ id, passwordHash }) {
    return userModel
      .findOneAndUpdate(
        { _id: id },
        { $set: { MatKhau: passwordHash }, $inc: { tokenVersion: 1 } },
        { new: true },
      )
      .select(WITH_TOKEN_VERSION)
      .lean();
  },

  /**
   * Ghi nhận hoạt động đăng nhập và trả về tóm tắt streak.
   *
   * Toàn bộ phần dùng method của model (`updateStreakOnActivity`, `addXP`) nằm
   * ở đây để service không phải cầm document Mongoose.
   */
  async recordLoginStreak(userId) {
    let streak = await streakModel.findOne({ user: userId });

    if (!streak) {
      streak = await streakModel.create({
        user: userId,
        current_streak: 0,
        longest_streak: 0,
        total_xp: 0,
        level: 1,
      });
    }

    const result = streak.updateStreakOnActivity();
    if (result.is_new_day) {
      streak.addXP(10, 'Daily login');
      await streak.save();
    }

    return {
      current: streak.current_streak,
      longest: streak.longest_streak,
      total_xp: streak.total_xp,
      is_new_day: result.is_new_day,
      streak_broken: result.streak_broken || false,
    };
  },
});

export const userRepository = createUserRepository();

export default userRepository;
