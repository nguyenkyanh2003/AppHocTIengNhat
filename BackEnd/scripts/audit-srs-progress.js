/**
 * Audit **chỉ đọc** collection `srsprogresses` trước khi làm mốc 1.
 *
 * Spec SRS §3.7 yêu cầu chạy bước này trên dữ liệu thật trước khi cutover:
 * schema hiện tại không chứng minh dữ liệu lịch sử sạch, vì import trực tiếp
 * hoặc phiên bản model cũ có thể đã tạo document khác hình dạng.
 *
 * Script đọc qua **native collection** chứ không qua Mongoose model, để nhìn
 * thấy đúng dữ liệu thô — model sẽ che mất trường lạ và tự ép kiểu.
 *
 * Không ghi gì, không in nội dung document (tránh lộ dữ liệu cá nhân); chỉ in
 * tên database, collection, thời điểm và số lượng theo từng nhóm.
 *
 *   node scripts/audit-srs-progress.js
 */
import dotenv from 'dotenv';
import mongoose from 'mongoose';

dotenv.config();

const COLLECTION = 'srsprogresses';
const ITEM_TYPES = ['Vocabulary', 'Kanji'];

const main = async () => {
  const uri = process.env.MONGODB_URI;
  if (!uri) {
    console.error('❌ Thiếu MONGODB_URI trong .env');
    process.exit(1);
  }

  await mongoose.connect(uri, {
    dbName: process.env.DB_NAME || 'AppHocTiengNhat',
  });

  const db = mongoose.connection.db;
  const srs = db.collection(COLLECTION);

  console.log(`database   : ${mongoose.connection.name}`);
  console.log(`collection : ${COLLECTION}`);
  console.log(`thời điểm  : ${new Date().toISOString()}`);
  console.log('');

  const total = await srs.countDocuments();

  /** Đếm document tham chiếu tới một collection khác mà bản ghi đích không còn. */
  const danglingRefs = async (field, targetCollection, extraMatch = {}) => {
    const rows = await srs
      .aggregate([
        { $match: { [field]: { $exists: true }, ...extraMatch } },
        {
          $lookup: {
            from: targetCollection,
            localField: field,
            foreignField: '_id',
            as: 'target',
          },
        },
        { $match: { target: { $size: 0 } } },
        { $count: 'n' },
      ])
      .toArray();
    return rows[0]?.n ?? 0;
  };

  const duplicates = await srs
    .aggregate([
      { $group: { _id: { user: '$user', item: '$item_id' }, n: { $sum: 1 } } },
      { $match: { n: { $gt: 1 } } },
      { $count: 'n' },
    ])
    .toArray();

  const groups = {
    'tổng số bản ghi': total,

    'thiếu user': await srs.countDocuments({ user: { $exists: false } }),
    'user sai kiểu': await srs.countDocuments({
      user: { $exists: true, $not: { $type: 'objectId' } },
    }),
    'user không còn tồn tại': await danglingRefs('user', 'users'),

    'thiếu item_id': await srs.countDocuments({ item_id: { $exists: false } }),
    'item_id sai kiểu': await srs.countDocuments({
      item_id: { $exists: true, $not: { $type: 'objectId' } },
    }),
    'Vocabulary không còn tồn tại': await danglingRefs(
      'item_id',
      'vocabularies',
      { item_type: 'Vocabulary' },
    ),
    'Kanji không còn tồn tại': await danglingRefs('item_id', 'kanjis', {
      item_type: 'Kanji',
    }),

    'thiếu next_review': await srs.countDocuments({
      next_review: { $exists: false },
    }),
    'next_review null': await srs.countDocuments({ next_review: null }),
    'next_review sai kiểu Date': await srs.countDocuments({
      next_review: { $exists: true, $ne: null, $not: { $type: 'date' } },
    }),

    'item_type ngoài enum': await srs.countDocuments({
      item_type: { $nin: ITEM_TYPES },
    }),
    'item_type là Kanji (hợp lệ)': await srs.countDocuments({
      item_type: 'Kanji',
    }),

    'box ngoài 1..5': await srs.countDocuments({
      $or: [{ box: { $lt: 1 } }, { box: { $gt: 5 } }],
    }),
    'box không phải số nguyên': await srs.countDocuments({
      box: { $exists: true, $not: { $type: 'int' } },
    }),
    'streak âm': await srs.countDocuments({ streak: { $lt: 0 } }),

    'trường legacy user_id': await srs.countDocuments({
      user_id: { $exists: true },
    }),
    'trường legacy next_review_date': await srs.countDocuments({
      next_review_date: { $exists: true },
    }),
    'trường legacy interval/ease_factor/repetitions': await srs.countDocuments({
      $or: [
        { interval: { $exists: true } },
        { ease_factor: { $exists: true } },
        { repetitions: { $exists: true } },
      ],
    }),
    'trường legacy status': await srs.countDocuments({
      status: { $exists: true },
    }),

    'trùng (user, item_id)': duplicates[0]?.n ?? 0,
  };

  const width = Math.max(...Object.keys(groups).map((key) => key.length));
  let problems = 0;

  for (const [name, count] of Object.entries(groups)) {
    const informational =
      name === 'tổng số bản ghi' || name === 'item_type là Kanji (hợp lệ)';
    if (!informational && count > 0) problems += count;
    console.log(`${name.padEnd(width)} : ${count}`);
  }

  console.log('\nindex hiện có:');
  for (const index of await srs.indexes()) {
    console.log(`  ${index.name} ${JSON.stringify(index.key)}`);
  }

  console.log(
    problems === 0
      ? '\n✅ Không thấy bất thường — mốc 1 không cần script migrate.'
      : `\n⚠️  ${problems} bản ghi bất thường — bổ sung migration vào plan trước khi cutover.`,
  );

  await mongoose.disconnect();
};

main().catch((error) => {
  console.error('❌ Lỗi khi audit:', error.message);
  process.exitCode = 1;
});
