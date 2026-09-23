/**
 * Khôi phục một bản sao lưu của `backup-collections.js`, rồi so số bản ghi và
 * checksum với manifest.
 *
 * Hai công dụng:
 *
 * - **Khôi phục thử** (bắt buộc trước migration): vào một database khác, ví dụ
 *   `AppHocTiengNhat_restore_check`. Thành công thì manifest được đánh dấu
 *   `restore_checked_at`, và migration mới chấp nhận bản sao lưu này.
 * - **Đường lui** sau migration hỏng: vào chính database gốc, kèm `--drop`.
 *
 * Không bao giờ ghi đè collection đang có dữ liệu nếu thiếu `--drop`.
 *
 *   node scripts/restore-collections.js --dir backups/<thời điểm> --target-db AppHocTiengNhat_restore_check
 *   node scripts/restore-collections.js --dir backups/<thời điểm> --target-db AppHocTiengNhat --drop
 */
import { readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';

import dotenv from 'dotenv';
import mongoose from 'mongoose';

import { checksumOf, parseDocuments } from './backup-format.js';

dotenv.config({ quiet: true });

const argValue = (flag) => {
  const index = process.argv.indexOf(flag);
  return index === -1 ? undefined : process.argv[index + 1];
};

const main = async () => {
  const dir = argValue('--dir');
  const targetDb = argValue('--target-db');
  const drop = process.argv.includes('--drop');
  if (!dir || !targetDb) throw new Error('Cần --dir <thư mục sao lưu> và --target-db <tên database>.');

  const manifestPath = path.join(dir, 'manifest.json');
  const manifest = JSON.parse(await readFile(manifestPath, 'utf8'));
  const isRehearsal = targetDb !== manifest.database;

  const uri = process.env.MONGODB_URI;
  if (!uri) throw new Error('Thiếu MONGODB_URI trong .env');
  await mongoose.connect(uri, { dbName: targetDb });
  const { db } = mongoose.connection;

  try {
    for (const [name, expected] of Object.entries(manifest.collections)) {
      const collection = db.collection(name);
      const existing = await collection.countDocuments();
      if (existing > 0 && !drop) {
        throw new Error(`${targetDb}.${name} đang có ${existing} bản ghi. Thêm --drop nếu thật sự muốn ghi đè.`);
      }
      if (existing > 0) await collection.deleteMany({});

      const documents = parseDocuments(await readFile(path.join(dir, `${name}.ejson`), 'utf8'));
      if (documents.length > 0) await collection.insertMany(documents, { ordered: true });

      const restored = await collection.find({}).toArray();
      if (restored.length !== expected.count || checksumOf(restored) !== expected.sha256) {
        throw new Error(`Khôi phục ${name} không khớp manifest.`);
      }
      console.log(`♻️  ${name.padEnd(18)} ${restored.length} bản ghi, checksum khớp`);
    }

    if (isRehearsal) {
      manifest.restore_checked_at = new Date().toISOString();
      manifest.restore_checked_into = targetDb;
      await writeFile(manifestPath, JSON.stringify(manifest, null, 2), 'utf8');
      console.log(`\n✅ Khôi phục thử vào ${targetDb} thành công; đã ghi vào manifest.`);
      console.log(`   Xoá database thử khi không cần nữa: db.getSiblingDB('${targetDb}').dropDatabase()`);
    } else {
      console.log(`\n✅ Đã khôi phục ${manifest.database} từ bản sao lưu ${manifest.created_at}.`);
    }
  } finally {
    await mongoose.disconnect();
  }
};

main().catch((error) => {
  console.error('❌ Lỗi khôi phục:', error.message);
  process.exitCode = 1;
});
