/**
 * Sao lưu collection ra `backups/<thời điểm>/` trước migration (spec streak
 * §4.1 bước 3). Chỉ đọc database.
 *
 * Mỗi collection thành một file EJSON canonical kèm số bản ghi và checksum
 * trong `manifest.json`. File được đọc lại ngay sau khi ghi và so checksum;
 * bước "khôi phục thử" là `restore-collections.js` vào một database khác.
 *
 *   node scripts/backup-collections.js                        # bộ collection của migration streak
 *   node scripts/backup-collections.js --collections users,userstreaks
 *
 * `backups/` nằm trong `.gitignore`: bản sao lưu chứa dữ liệu người dùng.
 */
import { mkdir, readFile, writeFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';

import dotenv from 'dotenv';
import mongoose from 'mongoose';

import { checksumOf, parseDocuments, serializeDocuments, STREAK_MIGRATION_COLLECTIONS } from './backup-format.js';

dotenv.config({ quiet: true });

const collectionsArg = () => {
  const index = process.argv.indexOf('--collections');
  if (index === -1) return STREAK_MIGRATION_COLLECTIONS;
  const names = (process.argv[index + 1] ?? '').split(',').map((name) => name.trim()).filter(Boolean);
  if (names.length === 0) throw new Error('--collections cần danh sách tên, ngăn bằng dấu phẩy.');
  return names;
};

const main = async () => {
  const names = collectionsArg();
  const uri = process.env.MONGODB_URI;
  if (!uri) throw new Error('Thiếu MONGODB_URI trong .env');
  await mongoose.connect(uri, { dbName: process.env.DB_NAME || 'AppHocTiengNhat' });
  const { db } = mongoose.connection;

  const stamp = new Date().toISOString().replace(/[:.]/g, '-');
  const dir = new URL(`../backups/${stamp}/`, import.meta.url);
  await mkdir(dir, { recursive: true });

  const manifest = { database: mongoose.connection.name, created_at: new Date().toISOString(), collections: {} };

  try {
    for (const name of names) {
      const documents = await db.collection(name).find({}).toArray();
      const file = new URL(`${name}.ejson`, dir);
      await writeFile(file, serializeDocuments(documents), 'utf8');

      // Đọc lại từ đĩa: file ghi thiếu hay hỏng phải lộ ra bây giờ, không phải
      // lúc cần khôi phục.
      const readBack = parseDocuments(await readFile(file, 'utf8'));
      const checksum = checksumOf(documents);
      if (readBack.length !== documents.length || checksumOf(readBack) !== checksum) {
        throw new Error(`Đọc lại ${name} không khớp bản vừa ghi.`);
      }

      manifest.collections[name] = { count: documents.length, sha256: checksum };
      console.log(`💾 ${name.padEnd(18)} ${documents.length} bản ghi`);
    }

    await writeFile(new URL('manifest.json', dir), JSON.stringify(manifest, null, 2), 'utf8');
    console.log(`\n✅ Đã sao lưu và đọc lại khớp: ${fileURLToPath(dir)}`);
    console.log('   Bước tiếp: khôi phục thử vào database khác bằng restore-collections.js.');
  } finally {
    await mongoose.disconnect();
  }
};

main().catch((error) => {
  console.error('❌ Lỗi sao lưu:', error.message);
  process.exitCode = 1;
});
