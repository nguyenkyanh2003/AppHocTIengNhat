import dotenv from 'dotenv';
import { fileURLToPath } from 'url';

const envFile = fileURLToPath(new URL('../../.env', import.meta.url));

dotenv.config({ path: envFile });

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

  if (!Number.isInteger(env.port) || env.port < 1 || env.port > 65535) {
    throw new Error('PORT không hợp lệ.');
  }
};

export default env;
