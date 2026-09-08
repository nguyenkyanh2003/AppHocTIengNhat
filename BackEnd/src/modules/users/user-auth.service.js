import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';

import env from '../../config/env.js';
import { ApiError } from '../../shared/http/api-error.js';
import { getVietnamTime } from '../../shared/utils/timezone.js';
import { passwordResetMailer } from './user-auth.mailer.js';
import { userRepository } from './user.repository.js';

const ACCESS_TOKEN_TTL = '24h';
const RESET_TOKEN_TTL = '1h';
const BCRYPT_ROUNDS = 10;

const ACCESS_TOKEN_TYPE = 'access';
const RESET_TOKEN_TYPE = 'password-reset';

/** Một thông báo duy nhất cho cả email tồn tại lẫn không tồn tại. */
const FORGOT_PASSWORD_MESSAGE =
  'Nếu email tồn tại, hướng dẫn đặt lại mật khẩu sẽ được gửi.';

const INVALID_RESET_TOKEN = 'Token không hợp lệ hoặc đã hết hạn.';
const CONSUMED_RESET_TOKEN = 'Token đã được sử dụng hoặc không còn hợp lệ.';

/**
 * Dựng URL đặt lại mật khẩu cho Flutter Web.
 *
 * Client web đang chạy hash routing (không nơi nào gọi `usePathUrlStrategy`),
 * nên URL thật của màn reset là `<base>/#/reset-password?token=...`. Link thiếu
 * `#` sẽ được trình duyệt hỏi thẳng web server: tùy cấu hình host mà trả 404
 * hoặc mở app ở route mặc định, và cả hai đều không tới được form đặt lại.
 *
 * Base URL được chuẩn hóa để `http://host`, `http://host/` và `http://host/app/`
 * đều sinh ra link dùng được.
 */
export const buildResetLink = (frontendUrl, token) => {
  const base = String(frontendUrl ?? '').replace(/\/+$/, '');
  const query = new URLSearchParams({ token }).toString();

  return `${base}/#/reset-password?${query}`;
};

/** Bỏ mật khẩu và version khỏi user trước khi trả ra ngoài. */
const publicUser = (user) => {
  if (!user) return null;

  const { MatKhau, tokenVersion, __v, ...rest } = user;
  return rest;
};

/** Document tạo trước khi có `tokenVersion` được coi như version 0. */
const versionOf = (user) => user?.tokenVersion ?? 0;

const defaultHasher = {
  hash: (plain) => bcrypt.hash(plain, BCRYPT_ROUNDS),
  compare: (plain, hashed) => bcrypt.compare(plain, hashed),
};

/**
 * Rule nghiệp vụ của bốn luồng xác thực: đăng nhập, quên mật khẩu, đặt lại
 * mật khẩu và đổi mật khẩu.
 *
 * Mọi phụ thuộc có tác dụng phụ (database, SMTP, bcrypt, đồng hồ) đều nhận qua
 * tham số, nên test dựng được chuỗi "đăng nhập → đổi mật khẩu → token cũ bị từ
 * chối" mà không cần MongoDB hay mail server.
 */
export const createUserAuthService = ({
  userRepository: repository = userRepository,
  mailer = passwordResetMailer,
  passwordHasher = defaultHasher,
  jwtSecret = env.jwtSecret,
  frontendUrl = env.frontendUrl,
  now = getVietnamTime,
} = {}) => ({
  async login({ username, password }) {
    const user = await repository.findByUsername(username);
    if (!user) throw ApiError.unauthorized('Tên đăng nhập không tồn tại.');

    if (user.TrangThai !== 'active') {
      throw ApiError.forbidden('Tài khoản hiện không hoạt động.');
    }

    const matched = await passwordHasher.compare(password, user.MatKhau);
    if (!matched) throw ApiError.unauthorized('Mật khẩu không đúng.');

    const updated =
      (await repository.touchLastLogin({ id: user._id, at: now() })) ?? user;
    const streak = await repository.recordLoginStreak(user._id);

    // Access token mang theo version tại thời điểm phát: đổi mật khẩu sẽ tăng
    // version trong database và mọi token phát trước đó mất hiệu lực ngay.
    const token = jwt.sign(
      {
        id: String(user._id),
        username: user.TenDangNhap,
        role: user.VaiTro,
        type: ACCESS_TOKEN_TYPE,
        tokenVersion: versionOf(user),
      },
      jwtSecret,
      { expiresIn: ACCESS_TOKEN_TTL, subject: String(user._id) },
    );

    return { user: publicUser(updated), token, streak };
  },

  /**
   * Kiểm tra cấu hình email **trước** khi tra cứu người dùng.
   *
   * Nếu kiểm tra sau, email chưa cấu hình sẽ trả 503 cho địa chỉ có thật và 200
   * cho địa chỉ không có, biến chính thông báo chung thành công cụ dò tài khoản.
   */
  async forgotPassword({ email }) {
    if (!mailer.isConfigured()) {
      throw new ApiError(503, 'Dịch vụ email chưa được cấu hình.', {
        code: 'EMAIL_NOT_CONFIGURED',
      });
    }

    const user = await repository.findByEmail(email);

    if (user) {
      const token = jwt.sign(
        {
          id: String(user._id),
          type: RESET_TOKEN_TYPE,
          tokenVersion: versionOf(user),
        },
        jwtSecret,
        { expiresIn: RESET_TOKEN_TTL },
      );

      // Địa chỉ nhận luôn đọc từ database, không bao giờ từ request.
      await mailer.sendPasswordReset({
        to: user.Email,
        fullName: user.HoTen,
        resetLink: buildResetLink(frontendUrl, token),
      });
    }

    return { message: FORGOT_PASSWORD_MESSAGE };
  },

  async resetPassword({ token, newPassword }) {
    let decoded;
    try {
      decoded = jwt.verify(token, jwtSecret);
    } catch {
      throw ApiError.unauthorized(INVALID_RESET_TOKEN);
    }

    if (decoded.type !== RESET_TOKEN_TYPE) {
      throw ApiError.unauthorized(INVALID_RESET_TOKEN);
    }

    const user = await repository.findById(decoded.id);
    if (!user) throw ApiError.notFound('Người dùng không tồn tại.');

    const expectedVersion = decoded.tokenVersion;
    if (
      typeof expectedVersion !== 'number' ||
      expectedVersion !== versionOf(user)
    ) {
      throw ApiError.unauthorized(CONSUMED_RESET_TOKEN);
    }

    const passwordHash = await passwordHasher.hash(newPassword);

    // Ghi có điều kiện version: hai request cùng cầm một token thì chỉ request
    // đầu tiên khớp, request còn lại không tìm thấy document để ghi.
    const updated = await repository.replacePasswordIfVersionMatches({
      id: user._id,
      expectedVersion,
      passwordHash,
    });

    if (!updated) throw ApiError.unauthorized(CONSUMED_RESET_TOKEN);

    return { message: 'Đặt lại mật khẩu thành công.' };
  },

  async changePassword({ actor, targetUserId, oldPassword, newPassword }) {
    const isAdmin = actor.VaiTro === 'admin';
    const isSelf = String(actor._id) === String(targetUserId);

    if (!isAdmin && !isSelf) {
      throw ApiError.forbidden('Bạn không có quyền đổi mật khẩu.');
    }

    const user = await repository.findById(targetUserId);
    if (!user) throw ApiError.notFound('Người dùng không tồn tại.');

    if (!isAdmin) {
      if (!oldPassword) {
        throw ApiError.badRequest(
          'Vui lòng cung cấp mật khẩu cũ và mật khẩu mới (mật khẩu tối thiểu 8 ký tự.)',
        );
      }

      const matched = await passwordHasher.compare(oldPassword, user.MatKhau);
      if (!matched) throw ApiError.unauthorized('Mật khẩu cũ không chính xác.');
    }

    const passwordHash = await passwordHasher.hash(newPassword);

    // Tăng version của **tài khoản đích**. Admin đổi mật khẩu người khác vì thế
    // thu hồi phiên của người đó mà không đụng tới phiên của chính admin.
    await repository.replacePassword({ id: user._id, passwordHash });

    return { message: 'Đổi mật khẩu thành công.' };
  },
});

export const userAuthService = createUserAuthService();

export default userAuthService;
