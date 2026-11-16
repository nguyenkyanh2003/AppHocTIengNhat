import User from '../../../model/User.js';
import UserStreak from '../../../model/UserStreak.js';
import { dayKey, projectStreak } from '../streaks/streak-rules.js';

/**
 * `tokenVersion` khai báo `select: false` trong model, nên mọi truy vấn phục vụ
 * xác thực phải xin thêm trường này một cách tường minh.
 */
const WITH_TOKEN_VERSION = '+tokenVersion';

/** Hồ sơ trả ra ngoài: không bao giờ kèm mật khẩu. */
const PUBLIC_FIELDS = '-MatKhau';
const NEWEST_FIRST = { NgayTao: -1, _id: -1 };

/** Số người theo từng giá trị của `field`: `[{ _id: giá trị, count }]`. */
const countBy = (model, field) =>
  model.aggregate([{ $group: { _id: `$${field}`, count: { $sum: 1 } } }, { $sort: { _id: 1 } }]);

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

  async usernameTaken(username) {
    return Boolean(await userModel.exists({ TenDangNhap: username }));
  },

  async emailTaken({ email, excludeId }) {
    return Boolean(await userModel.exists({ Email: email, ...(excludeId && { _id: { $ne: excludeId } }) }));
  },

  async create(doc) {
    return (await userModel.create(doc)).toObject();
  },

  findPublicById(id) {
    return userModel.findById(id).select(PUBLIC_FIELDS).lean();
  },

  updateById({ id, set }) {
    return userModel.findByIdAndUpdate(id, { $set: set }, { new: true, runValidators: true }).select(PUBLIC_FIELDS).lean();
  },

  deleteById(id) {
    return userModel.findByIdAndDelete(id).select(PUBLIC_FIELDS).lean();
  },

  findPage({ filter, skip, limit }) {
    return userModel.find(filter).select(PUBLIC_FIELDS).sort(NEWEST_FIRST).skip(skip).limit(limit).lean();
  },

  count(filter = {}) {
    return userModel.countDocuments(filter);
  },

  /** Đếm theo vai trò và trình độ, 10 tài khoản mới nhất và 10 người đăng nhập gần nhất. */
  async stats() {
    const [totalUsers, byRole, byStatus, byLevel, recentUsers, activeUsers] = await Promise.all([
      userModel.countDocuments(),
      countBy(userModel, 'VaiTro'),
      countBy(userModel, 'TrangThai'),
      countBy(userModel, 'TrinhDo'),
      userModel.find().select(PUBLIC_FIELDS).sort(NEWEST_FIRST).limit(10).lean(),
      userModel.find().select(PUBLIC_FIELDS).sort({ LanDangNhapCuoi: -1, _id: -1 }).limit(10).lean(),
    ]);
    return { totalUsers, byRole, byStatus, byLevel, recentUsers, activeUsers };
  },

  /**
   * Tóm tắt streak để trả kèm response đăng nhập — **chỉ đọc**.
   *
   * Bản cũ nối chuỗi và cộng 10 XP "Daily login" ở đây, nên đăng nhập một lần
   * mỗi ngày là đủ giữ chuỗi mà không cần học. Spec §3.4 bỏ khoản đó: đăng
   * nhập 0 XP, không phải hoạt động học, và không được tạo document hay ghi
   * đè chuỗi đã đứt. Chuỗi hiển thị là phép chiếu tại thời điểm đọc.
   */
  async readStreakSummary(userId, now = new Date()) {
    const streak = await streakModel.findOne({ user: userId }).lean();
    if (!streak) {
      return { current: 0, longest: 0, total_xp: 0, is_new_day: false, streak_broken: false };
    }

    const view = projectStreak(
      {
        currentStreak: streak.current_streak ?? 0,
        lastActivityDay: streak.last_activity_day ?? null,
        freezesAvailable: streak.freezes_available ?? 0,
      },
      dayKey(now),
    );

    return {
      current: view.currentStreak,
      longest: streak.longest_streak ?? 0,
      total_xp: streak.total_xp ?? 0,
      is_new_day: false,
      streak_broken: view.broken,
    };
  },
});

export const userRepository = createUserRepository();

export default userRepository;
