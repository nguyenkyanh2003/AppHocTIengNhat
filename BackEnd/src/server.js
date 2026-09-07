import path from 'path';
import { fileURLToPath } from 'url';

import app from './app.js';
import env from './config/env.js';
import { validateEnvironment } from './config/env.js';
import { connectDatabase, disconnectDatabase } from './config/database.js';

const __filename = fileURLToPath(import.meta.url);
let server;
let shuttingDown = false;

export const startServer = async () => {
  validateEnvironment();
  await connectDatabase();

  server = app.listen(env.port, () => {
    console.log(`🚀 Server đang chạy trên cổng ${env.port}`);
  });

  return server;
};

export const shutdownServer = async (signal = 'SIGINT') => {
  if (shuttingDown) return;
  shuttingDown = true;

  if (server) {
    await new Promise((resolve) => server.close(resolve));
  }

  console.log(`\n🛑 Nhận ${signal}, đang đóng kết nối MongoDB...`);
  await disconnectDatabase();
  console.log('✅ Đã đóng kết nối MongoDB');
};

const isMainModule = process.argv[1]
  && path.resolve(process.argv[1]) === path.resolve(__filename);

if (isMainModule) {
  startServer().catch((error) => {
    console.error('❌ Lỗi khởi động máy chủ:', error.message);
    process.exit(1);
  });

  process.on('SIGINT', async () => {
    await shutdownServer('SIGINT');
    process.exit(0);
  });

  process.on('SIGTERM', async () => {
    await shutdownServer('SIGTERM');
    process.exit(0);
  });

  process.on('unhandledRejection', (error) => {
    console.error('Unhandled promise rejection:', error);
  });

  process.on('uncaughtException', (error) => {
    console.error('Uncaught exception:', error);
    process.exit(1);
  });
}
