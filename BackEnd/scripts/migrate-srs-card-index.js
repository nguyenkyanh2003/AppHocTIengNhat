import 'dotenv/config';
import mongoose from 'mongoose';

import { duplicatePipeline } from './content-indexes.js';
import { CARD_KEY, planCardIndex, SRS_COLLECTION } from './srs-card-index.js';

/**
 * Chuyển unique index của thẻ ôn từ `(user, item_id)` sang
 * `(user, item_type, item_id)` (spec Kanji SRS §2, #6).
 *
 *   node scripts/migrate-srs-card-index.js           # chỉ đọc: in kế hoạch
 *   node scripts/migrate-srs-card-index.js --apply   # tạo khoá mới, rồi xoá khoá cũ
 *
 * Không đụng tới document nào. Chạy lại an toàn: đã chuyển xong thì không làm gì.
 */

const parseFlags = (argv = process.argv.slice(2)) => {
  const unknown = argv.filter((flag) => flag !== '--apply');
  if (unknown.length > 0) throw new Error(`Cờ không nhận ra: ${unknown.join(', ')}`);
  return { apply: argv.includes('--apply') };
};

const audit = async (collection) => {
  const duplicates = await collection.aggregate(duplicatePipeline(CARD_KEY.key)).toArray();
  const plan = planCardIndex(await collection.indexes());

  console.log(`\n🗂  ${SRS_COLLECTION}: ${await collection.countDocuments()} thẻ`);
  console.log(`   nhóm trùng theo khoá mới: ${duplicates.length}`);
  for (const group of duplicates.slice(0, 10)) console.log(`     • ${JSON.stringify(group._id)} × ${group.count}`);
  console.log(`   tạo ${CARD_KEY.name}: ${plan.create ? 'CẦN' : 'đã có'}`);
  console.log(`   xoá khoá cũ: ${plan.drop.length > 0 ? plan.drop.join(', ') : 'không còn'}`);

  return { duplicates, plan };
};

const apply = async (collection, { duplicates, plan }) => {
  if (duplicates.length > 0) {
    console.log('\n⛔ Có thẻ trùng theo khoá mới — không đổi index nào. Xử lý các nhóm trùng ở trên trước.');
    return false;
  }

  // Thứ tự là bắt buộc: khoá mới phải có trước khi khoá cũ biến mất.
  if (plan.create) {
    await collection.createIndex({ ...CARD_KEY.key }, { unique: true, name: CARD_KEY.name });
    console.log(`\n🔧 Đã tạo ${CARD_KEY.name}`);
  }
  for (const name of plan.drop) {
    await collection.dropIndex(name);
    console.log(`🔧 Đã xoá ${name}`);
  }

  // Đọc lại từ DB chứ không tin vào việc lệnh không ném lỗi.
  const after = planCardIndex(await collection.indexes());
  const ok = !after.create && after.drop.length === 0;
  console.log(`   xác minh: ${ok ? '✅ chỉ còn khoá mới' : `❌ ${JSON.stringify(after)}`}`);
  return ok;
};

const run = async () => {
  const flags = parseFlags();
  await mongoose.connect(process.env.MONGODB_URI, { dbName: process.env.DB_NAME || 'AppHocTiengNhat' });
  console.log(`✅ Đã kết nối ${mongoose.connection.name}`);

  try {
    const collection = mongoose.connection.db.collection(SRS_COLLECTION);
    const report = await audit(collection);
    if (!flags.apply) {
      console.log('\n🔍 Chỉ đọc. Chạy lại với --apply để chuyển index.');
      return report.duplicates.length === 0;
    }
    return await apply(collection, report);
  } finally {
    await mongoose.disconnect();
  }
};

run()
  .then((ok) => {
    if (!ok) process.exitCode = 1;
  })
  .catch((error) => {
    console.error('❌', error.message);
    process.exitCode = 1;
  });
