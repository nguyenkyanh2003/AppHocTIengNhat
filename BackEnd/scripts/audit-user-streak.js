/**
 * Audit **chỉ đọc** dữ liệu streak cũ trước migration (spec streak §4.1 bước
 * 1–2), cùng khuôn với `audit-srs-progress.js`.
 *
 * Đọc qua native collection để thấy đúng dữ liệu thô — model sẽ che trường lạ
 * và tự ép kiểu. Không ghi gì, không in nội dung document; chỉ in database,
 * collection, thời điểm và số lượng theo nhóm.
 *
 *   node scripts/audit-user-streak.js
 */
import dotenv from 'dotenv';
import mongoose from 'mongoose';

import { auditUserStreaks } from './streak-legacy.js';

dotenv.config({ quiet: true });

const COLLECTIONS = ['userstreaks', 'activityevents', 'streakdays'];

const printIndexes = async (db) => {
  console.log('\nIndex hiện có:');
  for (const name of COLLECTIONS) {
    const exists = (await db.listCollections({ name }).toArray()).length > 0;
    if (!exists) {
      console.log(`  ${name}: (chưa có collection)`);
      continue;
    }
    const indexes = await db.collection(name).indexes();
    for (const index of indexes) {
      console.log(`  ${name}: ${JSON.stringify(index.key)}${index.unique ? ' unique' : ''}`);
    }
  }
};

const main = async () => {
  const uri = process.env.MONGODB_URI;
  if (!uri) throw new Error('Thiếu MONGODB_URI trong .env');
  await mongoose.connect(uri, { dbName: process.env.DB_NAME || 'AppHocTiengNhat' });
  const { db } = mongoose.connection;

  try {
    const [streaks, users, completedAchievements, rewardStates] = await Promise.all([
      db.collection('userstreaks').find({}).toArray(),
      db.collection('users').find({}, { projection: { _id: 1 } }).toArray(),
      db.collection('userachievements').countDocuments({ is_completed: true }),
      db
        .collection('lessonprogresses')
        .aggregate([{ $group: { _id: '$completion_reward_state', count: { $sum: 1 } } }])
        .toArray(),
    ]);
    const report = auditUserStreaks({
      streaks,
      userIds: new Set(users.map((user) => user._id.toHexString())),
    });

    console.log(`database   : ${mongoose.connection.name}`);
    console.log('collection : userstreaks, userachievements, lessonprogresses');
    console.log(`thời điểm  : ${new Date().toISOString()}\n`);
    console.log(`Tổng document userstreaks            ${report.total}`);
    console.log(`  user thiếu/sai kiểu                ${report.userMissingOrWrongType}`);
    console.log(`  user không còn tồn tại             ${report.userDangling}`);
    console.log(`  trùng user                         ${report.duplicateUsers}`);
    console.log(`  last_activity_date trống           ${report.lastActivityDateMissing}`);
    console.log(`  last_activity_date sai kiểu Date   ${report.lastActivityDateInvalid}`);
    console.log(`  total_xp âm/sai kiểu               ${report.totalXpInvalid}`);
    console.log(`  current/longest âm                 ${report.streakNegative}`);
    console.log(`  current > longest                  ${report.currentAboveLongest}`);
    console.log(`  dòng xp_history thiếu amount/ngày  ${report.xpHistoryEntriesInvalid}`);
    console.log(`  đã ghi qua đường mới               ${report.alreadyOnNewPath}`);
    for (const [field, stats] of Object.entries(report.arrays)) {
      console.log(`  ${field.padEnd(15)} min ${stats.min} · max ${stats.max} · tổng ${stats.total}`);
    }

    console.log('\nGiờ:phút UTC của activity_dates + last_activity_date (5 nhóm nhiều nhất):');
    for (const { time, count } of report.timeOfDay) console.log(`  ${time}  ${count}`);
    console.log(
      report.suggestedTimeZone
        ? `  → gợi ý --legacy-tz ${report.suggestedTimeZone.timeZone} (${Math.round(report.suggestedTimeZone.share * 100)}% mốc khớp nửa đêm)`
        : '  → KHÔNG xác định được múi giờ: các mốc không tụ về một nửa đêm. Không đoán; xử lý nhóm này bằng tay.',
    );

    console.log(`\nUserAchievement đã hoàn thành        ${completedAchievements}`);
    console.log('LessonProgress theo completion_reward_state:');
    for (const { _id: state, count } of rewardStates) console.log(`  ${state ?? '(chưa có)'}  ${count}`);

    await printIndexes(db);
  } finally {
    await mongoose.disconnect();
  }
};

main().catch((error) => {
  console.error('❌ Lỗi audit:', error.message);
  process.exitCode = 1;
});
