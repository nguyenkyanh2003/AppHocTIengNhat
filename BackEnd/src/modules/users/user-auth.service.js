import { createHash, randomBytes } from 'node:crypto';

import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';

import env from '../../config/env.js';
import { ApiError } from '../../shared/http/api-error.js';
import { getVietnamTime } from '../../shared/utils/timezone.js';
import { authSessionRepository } from './auth-session.repository.js';
import { passwordResetMailer } from './user-auth.mailer.js';
import { PASSWORD_MIN_LENGTH } from './user.schema.js';
import { userRepository } from './user.repository.js';

/**
 * Access token ngắn hạn, refresh token dài hạn. Access token hết hạn thì client
 * dùng refresh token đổi cặp mới, nên 15 phút không bắt người dùng đăng nhập
 * lại; còn một access token lọt ra ngoài chỉ dùng được tối đa 15 phút.
 */
const ACCESS_TOKEN_TTL = '15m';
const REFRESH_TOKEN_TTL_MS = 30 * 24 * 60 * 60 * 1000;
/** Thời gian token vừa bị thay vẫn được nhận như một lần thử lại; dài hơn timeout 20 giây của client. */
const REFRESH_RETRY_GRACE_MS = 60 * 1000;
const ROTATE_ATTEMPTS = 3;
const RESET_TOKEN_TTL = '1h';
const BCRYPT_ROUNDS = 10;

const ACCESS_TOKEN_TYPE = 'access';
const RESET_TOKEN_TYPE = 'password-reset';

/** Một thông báo cho cả sai tên lẫn sai mật khẩu: không cho dò tên đăng nhập nào tồn tại. */
const INVALID_CREDENTIALS = 'Tên đăng nhập hoặc mật khẩu không đúng.';

/**
 * Bcrypt hash của một chuỗi ngẫu nhiên không ai biết. Tên không tồn tại vẫn so
 * mật khẩu với hash này, để thời gian phản hồi bằng với trường hợp sai mật khẩu
 * — không thì đo thời gian cũng dò ra được tên nào có thật.
 */
const TIMING_DUMMY_HASH = '$2b$10$38S5ewDbTRPsW5LhHCMD1eKQrpNlrDnu6UZ9gHQd595qxYHLTp/3G';

const SESSION_ENDED = 'Phiên đăng nhập đã kết thúc. Vui lòng đăng nhập lại.';

/** Cùng mã với middleware: client nhận mã này thì dọn phiên và về màn đăng nhập. */
const sessionEnded = () => ApiError.unauthorized(SESSION_ENDED, { code: 'SESSION_EXPIRED' });

const defaultTokens = {
  generate: () => randomBytes(32).toString('base64url'),
  hash: (token) => createHash('sha256').update(token).digest('hex'),
};

/** Đúng token vừa bị thay (không phải token bị thay trong lúc ân hạn), còn trong khoảng ân hạn. */
const isRetryInGrace = (session, hash, at) =>
  session.previous_token_hash === hash
  && Boolean(session.previous_retired_at)
  && at.getTime() - new Date(session.previous_retired_at).getTime() <= REFRESH_RETRY_GRACE_MS;

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
  sessionRepository: sessions = authSessionRepository,
  mailer = passwordResetMailer,
  passwordHasher = defaultHasher,
  jwtSecret = env.jwtSecret,
  frontendUrl = env.frontendUrl,
  now = getVietnamTime,
  tokens = defaultTokens,
} = {}) => {
  /**
   * Access token mang version tại thời điểm phát (đổi mật khẩu tăng version, mọi
   * token cũ mất hiệu lực), mã phiên `sid` (đăng xuất thu hồi đúng phiên đó) và số
   * lần phiên đã xoay token `rotation` (client biết cặp token nào mới hơn).
   */
  const issueAccessToken = (user, session) =>
    jwt.sign(
      {
        id: String(user._id),
        username: user.TenDangNhap,
        role: user.VaiTro,
        type: ACCESS_TOKEN_TYPE,
        tokenVersion: versionOf(user),
        sid: String(session._id),
        rotation: session.rotation,
      },
      jwtSecret,
      { expiresIn: ACCESS_TOKEN_TTL, subject: String(user._id) },
    );

  const expiryFrom = (at) => new Date(at.getTime() + REFRESH_TOKEN_TTL_MS);

  /** Phiên của một tài khoản đã đổi mật khẩu thì không làm mới được nữa. */
  const revokeAllSessions = (userId) =>
    sessions.revokeAllForUser({ userId, reason: 'password_changed', at: now() });

  return {
    async login({ username, password }) {
      const user = await repository.findByUsername(username);
      const matched = await passwordHasher.compare(password, user?.MatKhau ?? TIMING_DUMMY_HASH);
      if (!user || !matched) {
        throw ApiError.unauthorized(INVALID_CREDENTIALS, { code: 'INVALID_CREDENTIALS' });
      }

      // Xét trạng thái **sau** mật khẩu: chỉ ai biết đúng mật khẩu mới biết tài
      // khoản bị khoá — người dò tên chỉ nhận thông báo chung.
      if (user.TrangThai !== 'active') {
        throw ApiError.forbidden('Tài khoản hiện không hoạt động.');
      }

      const at = now();
      const updated = (await repository.touchLastLogin({ id: user._id, at })) ?? user;
      const streak = await repository.readStreakSummary(user._id);

      const refreshToken = tokens.generate();
      const session = await sessions.create({
        userId: user._id,
        tokenHash: tokens.hash(refreshToken),
        expiresAt: expiryFrom(at),
      });

      return { user: publicUser(updated), token: issueAccessToken(user, session), refreshToken, streak };
    },

    /**
     * Đổi refresh token lấy cặp token mới (xoay vòng).
     *
     * Token vừa bị thay vẫn được nhận trong [REFRESH_RETRY_GRACE_MS]: server đã
     * đổi token mà phản hồi không về tới máy thì client chỉ còn token cũ, và
     * đăng xuất người dùng vì một lần mất mạng là sai. Khoảng này tính từ lần
     * thay **đầu tiên**, thử lại không kéo dài được. Quá khoảng đó, hoặc token bị
     * thay trong lúc ân hạn lại xuất hiện, nghĩa là hai bên cùng giữ phiên: thu
     * hồi cả phiên.
     */
    async refresh({ refreshToken }) {
      const hash = tokens.hash(refreshToken);

      for (let attempt = 0; attempt < ROTATE_ATTEMPTS; attempt += 1) {
        const at = now();
        const current = await sessions.findByTokenHash(hash);
        const session = current ?? (await sessions.findByRetiredHash(hash));

        if (!session) throw sessionEnded();
        if (session.revoked_at || new Date(session.expires_at) <= at) throw sessionEnded();

        if (!current && !isRetryInGrace(session, hash, at)) {
          await sessions.revoke({ id: session._id, reason: 'reuse_detected', at });
          throw sessionEnded();
        }

        const user = await repository.findById(session.user);
        if (!user || user.TrangThai !== 'active') {
          await sessions.revoke({ id: session._id, reason: 'account_inactive', at });
          throw sessionEnded();
        }

        const next = tokens.generate();
        const rotated = await sessions.rotate({
          id: session._id,
          fromHash: session.refresh_token_hash,
          toHash: tokens.hash(next),
          previousHash: hash,
          previousRetiredAt: current ? at : session.previous_retired_at,
          supersededHash: current ? session.superseded_token_hash : session.refresh_token_hash,
          expiresAt: expiryFrom(at),
          at,
        });
        if (rotated) return { token: issueAccessToken(user, rotated), refreshToken: next };

        // Thua lệnh ghi có điều kiện: request khác vừa đổi token. Đọc lại — lần
        // này token đang cầm là token vừa bị thay, nằm trong khoảng ân hạn.
      }

      throw ApiError.conflict('Phiên đang được làm mới. Vui lòng thử lại.', { code: 'REFRESH_CONFLICT' });
    },

    /**
     * Đóng phiên của thiết bị đang đăng xuất, nhận diện bằng refresh token hoặc
     * access token (kể cả access token đã hết hạn nhưng đúng chữ ký). Luôn thành
     * công: đăng xuất không được kẹt chỉ vì token đã hỏng.
     */
    async logout({ refreshToken, accessToken } = {}) {
      const at = now();
      if (refreshToken) {
        await sessions.revokeByTokenHash({ hash: tokens.hash(refreshToken), reason: 'logout', at });
      }
      if (accessToken) {
        let sessionId;
        try {
          sessionId = jwt.verify(accessToken, jwtSecret, { ignoreExpiration: true }).sid;
        } catch {
          sessionId = undefined;
        }
        if (sessionId) await sessions.revoke({ id: sessionId, reason: 'logout', at });
      }
      return { message: 'Đăng xuất thành công' };
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
      await revokeAllSessions(user._id);

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
            `Vui lòng cung cấp mật khẩu cũ và mật khẩu mới (mật khẩu tối thiểu ${PASSWORD_MIN_LENGTH} ký tự).`,
          );
        }

        const matched = await passwordHasher.compare(oldPassword, user.MatKhau);
        if (!matched) throw ApiError.unauthorized('Mật khẩu cũ không chính xác.');
      }

      const passwordHash = await passwordHasher.hash(newPassword);

      // Tăng version của **tài khoản đích**. Admin đổi mật khẩu người khác vì thế
      // thu hồi phiên của người đó mà không đụng tới phiên của chính admin.
      await repository.replacePassword({ id: user._id, passwordHash });
      await revokeAllSessions(user._id);

      return { message: 'Đổi mật khẩu thành công.' };
    },
  };
};

export const userAuthService = createUserAuthService();

export default userAuthService;
