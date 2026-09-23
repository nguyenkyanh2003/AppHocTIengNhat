import mongoose from 'mongoose';
import dotenv from 'dotenv';
import Achievement from '../model/Achievement.js';
import { ACHIEVEMENTS as achievements } from './achievement-catalog.js';

dotenv.config({ quiet: true });

/**
 * Upsert theo `name` (unique index) — **không** xoá rồi tạo lại.
 *
 * Bản cũ gọi `deleteMany({})` trước `insertMany`, nên mỗi lần chạy mọi huy
 * hiệu đổi `_id`: `UserAchievement.achievement` và khoá chống cấp lại
 * `achievement:<user>:<id>` trong nhật ký cùng trỏ vào hư không, và người học
 * nhận lại thưởng cho huy hiệu đã có. Chạy lại bao nhiêu lần `_id` vẫn giữ.
 *
 *   node scripts/seedAchievements.js --dry-run
 *   node scripts/seedAchievements.js
 */
const dryRun = process.argv.includes('--dry-run');

async function seedAchievements() {
  const mongoURI = process.env.MONGODB_URI;
  if (!mongoURI) throw new Error('MONGODB_URI not defined in .env');

  await mongoose.connect(mongoURI, { dbName: process.env.DB_NAME || 'AppHocTiengNhat' });
  console.log(`✅ Connected to MongoDB${dryRun ? ' (--dry-run, không ghi)' : ''}`);

  try {
    const existing = new Set(
      (await Achievement.find({ name: { $in: achievements.map((a) => a.name) } }).select('name').lean()).map(
        (a) => a.name,
      ),
    );
    const created = achievements.filter((a) => !existing.has(a.name)).length;

    if (!dryRun) {
      await Achievement.bulkWrite(
        achievements.map((achievement) => ({
          updateOne: {
            filter: { name: achievement.name },
            update: { $set: achievement, $setOnInsert: { is_active: true } },
            upsert: true,
          },
        })),
      );
    }

    console.log(`✨ ${achievements.length} huy hiệu: tạo mới ${created}, cập nhật ${achievements.length - created}`);
  } finally {
    await mongoose.connection.close();
  }
}

seedAchievements().catch((error) => {
  console.error('❌ Error seeding achievements:', error);
  process.exit(1);
});
