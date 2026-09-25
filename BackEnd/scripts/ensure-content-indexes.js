/**
 * Rà trùng, tạo và xác minh unique index khoá tự nhiên của nội dung học
 * (checklist P0 0.1). Mặc định **chỉ đọc**.
 *
 *   node scripts/ensure-content-indexes.js           # rà trùng + báo index đang có
 *   node scripts/ensure-content-indexes.js --apply   # tạo index còn thiếu rồi đọc lại xác minh
 *   node scripts/ensure-content-indexes.js --smoke   # chứng minh index chặn trùng thật, trên DB tạm riêng
 *
 * Không tạo index khi còn dữ liệu trùng: MongoDB sẽ từ chối, còn `autoIndex`
 * của Mongoose lúc khởi động server thì **nuốt lỗi đó im lặng** — app chạy tiếp
 * mà không có ràng buộc nào. Script này là chỗ lỗi đó hiện ra.
 */
import 'dotenv/config';
import mongoose from 'mongoose';

import { NATURAL_KEYS, duplicatePipeline, findNaturalKeyIndex } from './content-indexes.js';

const NAMESPACE_NOT_FOUND = 26;

const parseFlags = (argv = process.argv.slice(2)) => {
  const known = new Set(['--apply', '--smoke']);
  const unknown = argv.filter((flag) => !known.has(flag));
  if (unknown.length > 0) throw new Error(`Cờ không nhận ra: ${unknown.join(', ')}`);
  if (argv.includes('--apply') && argv.includes('--smoke')) {
    throw new Error('Chọn một trong --apply hoặc --smoke.');
  }
  return { apply: argv.includes('--apply'), smoke: argv.includes('--smoke') };
};

/** Index đang có; collection chưa tồn tại thì là danh sách rỗng, không phải lỗi. */
const indexesOf = async (db, collection) => {
  try {
    return await db.collection(collection).indexes();
  } catch (error) {
    if (error?.code === NAMESPACE_NOT_FOUND) return [];
    throw error;
  }
};

const audit = async (db) => {
  const report = [];
  for (const spec of NATURAL_KEYS) {
    const duplicates = await db.collection(spec.collection).aggregate(duplicatePipeline(spec.key)).toArray();
    const index = findNaturalKeyIndex(await indexesOf(db, spec.collection), spec);
    report.push({ spec, duplicates, index });

    console.log(`\n📚 ${spec.label} (${spec.collection}) — khoá ${Object.keys(spec.key).join(' + ')}`);
    console.log(`   nhóm trùng: ${duplicates.length}`);
    for (const group of duplicates.slice(0, 10)) {
      console.log(`     • ${JSON.stringify(group._id)} × ${group.count}`);
    }
    console.log(`   index ${spec.name}: ${index ? 'đã có (unique)' : 'CHƯA CÓ'}`);
  }
  return report;
};

const apply = async (db, report) => {
  const blocked = report.filter(({ duplicates }) => duplicates.length > 0);
  if (blocked.length > 0) {
    console.log('\n⛔ Còn dữ liệu trùng — không tạo index nào. Xử lý các nhóm trùng ở trên trước.');
    return false;
  }

  for (const { spec, index } of report) {
    if (index) continue;
    await db.collection(spec.collection).createIndex({ ...spec.key }, { unique: true, name: spec.name });
    console.log(`\n🔧 Đã tạo ${spec.name}`);
  }

  // Đọc lại từ DB chứ không tin vào việc lệnh tạo không ném lỗi.
  let ok = true;
  for (const spec of NATURAL_KEYS) {
    const index = findNaturalKeyIndex(await indexesOf(db, spec.collection), spec);
    console.log(`   xác minh ${spec.name}: ${index ? '✅ có, unique' : '❌ KHÔNG THẤY'}`);
    ok &&= Boolean(index);
  }
  return ok;
};

/** Bản ghi tối thiểu mang đúng các trường khoá, để thử chèn trùng. */
const sampleFor = (spec) =>
  Object.fromEntries(
    Object.keys(spec.key).map((field) => [
      field,
      field === 'lesson_id' ? new mongoose.Types.ObjectId('000000000000000000000001') : 'smoke',
    ]),
  );

/**
 * Chứng minh index chặn trùng **trên MongoDB thật**, không chỉ trên giấy:
 * tạo index trên collection rỗng của một DB tạm, chèn hai bản cùng khoá, bản
 * thứ hai phải nhận E11000. DB tạm bị xoá dù kết quả thế nào.
 */
const smoke = async (mainDbName) => {
  const smokeDbName = `${mainDbName}_index_smoke`;
  const db = mongoose.connection.useDb(smokeDbName, { useCache: false }).db;
  if (db.databaseName === mainDbName) throw new Error('DB smoke trùng DB chính — dừng.');

  let ok = true;
  try {
    for (const spec of NATURAL_KEYS) {
      const collection = db.collection(spec.collection);
      await collection.createIndex({ ...spec.key }, { unique: true, name: spec.name });
      await collection.insertOne(sampleFor(spec));
      let rejected = false;
      try {
        await collection.insertOne(sampleFor(spec));
      } catch (error) {
        rejected = error?.code === 11000;
        if (!rejected) throw error;
      }
      console.log(`   ${spec.name}: ${rejected ? '✅ chặn bản trùng' : '❌ ĐỂ LỌT bản trùng'}`);
      ok &&= rejected;
    }
  } finally {
    await db.dropDatabase();
    console.log(`   🧹 đã xoá DB tạm ${smokeDbName}`);
  }
  return ok;
};

const run = async () => {
  const flags = parseFlags();
  const dbName = process.env.DB_NAME || 'AppHocTiengNhat';
  await mongoose.connect(process.env.MONGODB_URI, { dbName });
  console.log(`✅ Đã kết nối ${mongoose.connection.name}`);

  try {
    if (flags.smoke) {
      console.log('\n🧪 Smoke trên DB tạm riêng:');
      return await smoke(dbName);
    }
    const report = await audit(mongoose.connection.db);
    if (!flags.apply) {
      console.log('\n🔍 Chỉ đọc. Chạy lại với --apply để tạo index còn thiếu.');
      return report.every(({ duplicates }) => duplicates.length === 0);
    }
    return await apply(mongoose.connection.db, report);
  } finally {
    // `await` ở hai nhánh trên là bắt buộc: `return promise` trong `try` cho
    // `finally` chạy ngay, ngắt kết nối khi lệnh còn đang chạy.
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
