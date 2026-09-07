import mongoose from 'mongoose';
import env from './env.js';

export const connectDatabase = async () => {
  if (!env.mongoUri) {
    throw new Error('MONGODB_URI không được định nghĩa trong file .env');
  }

  await mongoose.connect(env.mongoUri, {
    dbName: env.databaseName,
  });

  console.log(`✅ Kết nối MongoDB Database '${mongoose.connection.name}' thành công!`);
};

export const disconnectDatabase = async () => {
  await mongoose.connection.close();
};

