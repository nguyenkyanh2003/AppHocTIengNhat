import { isIP } from 'node:net';

import dotenv from 'dotenv';
import { fileURLToPath } from 'url';

const envFile = fileURLToPath(new URL('../../.env', import.meta.url));

dotenv.config({ path: envFile });

/**
 * `TRUST_PROXY` → giá trị `trust proxy` của Express, quyết định `req.ip` (và
 * vì thế giới hạn đăng nhập theo IP) lấy địa chỉ nào.
 *
 * - Bỏ trống: server nhận kết nối thẳng, `req.ip` là địa chỉ kết nối.
 * - Một số `n`: tin `n` proxy đứng trước server (Nginx, Render, Railway… thường là 1).
 *   Không đặt thì sau proxy mọi người dùng chung IP của proxy và chung một hạn mức.
 * - Danh sách IP/CIDR hoặc `loopback`, `linklocal`, `uniquelocal`: tin đúng các proxy đó.
 *
 * Giá trị khác (kể cả `true`) trả `null`: app chạy như không có proxy và
 * `validateEnvironment` dừng server với lời giải thích. Không để Express tự
 * đọc, vì nó ném lỗi khó hiểu ngay lúc nạp `app.js`.
 */
export const parseTrustProxy = (raw) => {
  const value = raw?.trim();
  if (!value || value === 'false') return false;
  if (/^[0-9]+$/.test(value)) return Number(value);
  const entries = value.split(',').map((entry) => entry.trim());
  return entries.every(isProxyEntry) ? entries.join(',') : null;
};

const PROXY_KEYWORDS = new Set(['loopback', 'linklocal', 'uniquelocal']);

/** Một mục của danh sách: từ khoá Express hiểu, hoặc IP / CIDR. */
const isProxyEntry = (entry) => {
  if (PROXY_KEYWORDS.has(entry)) return true;
  const [address, prefix, ...rest] = entry.split('/');
  return rest.length === 0 && isIP(address) !== 0 && (prefix === undefined || /^[0-9]{1,3}$/.test(prefix));
};

const env = Object.freeze({
  mongoUri: process.env.MONGODB_URI,
  databaseName: process.env.DB_NAME || 'AppHocTiengNhat',
  port: Number.parseInt(process.env.PORT || '3000', 10),
  nodeEnv: process.env.NODE_ENV || 'development',
  bypassAuth: process.env.BYPASS_AUTH === 'true',
  jwtSecret: process.env.JWT_SECRET,
  emailUser: process.env.EMAIL_USER,
  emailPassword: process.env.EMAIL_PASSWORD,
  frontendUrl: process.env.FRONTEND_URL || 'http://localhost:8080',
  trustProxySetting: process.env.TRUST_PROXY,
  trustProxy: parseTrustProxy(process.env.TRUST_PROXY) ?? false,
  corsOrigins: (process.env.CORS_ORIGINS || process.env.FRONTEND_URL || 'http://localhost:8080,http://localhost:3000')
    .split(',')
    .map((origin) => origin.trim())
    .filter(Boolean),
});

export const validateEnvironment = () => {
  if (!env.mongoUri) {
    throw new Error('MONGODB_URI không được cấu hình.');
  }

  if (!env.jwtSecret || env.jwtSecret.length < 32) {
    throw new Error('JWT_SECRET phải có ít nhất 32 ký tự.');
  }

  if (env.nodeEnv === 'production' && env.bypassAuth) {
    throw new Error('BYPASS_AUTH không được phép bật trong production.');
  }

  if (parseTrustProxy(env.trustProxySetting) === null) {
    // Tin mọi proxy thì ai cũng tự gửi X-Forwarded-For giả để đổi IP, né giới hạn đăng nhập.
    throw new Error(env.trustProxySetting.trim() === 'true'
      ? 'TRUST_PROXY=true tin mọi proxy nên IP giả được. Ghi số proxy đứng trước server (thường là 1).'
      : `TRUST_PROXY không hợp lệ: "${env.trustProxySetting}". Dùng số proxy (vd 1), loopback, hoặc danh sách IP/CIDR.`);
  }

  if (!Number.isInteger(env.port) || env.port < 1 || env.port > 65535) {
    throw new Error('PORT không hợp lệ.');
  }
};

export default env;
