import fs from 'node:fs/promises';

import mongoose from 'mongoose';
import dotenv from 'dotenv';

import Vocabulary from '../model/Vocabulary.js';
import {
  planTagUpdate,
  reviewTagRows,
  tagKey,
} from '../src/modules/vocabulary/vocabulary-tags.review.js';

dotenv.config();

/**
 * Gắn nhãn chia bộ (`topic`, `word_type`, `difficulty`) cho từ vựng đã có.
 *
 * Chỉ **cập nhật** từ đã tồn tại, khớp theo khoá tự nhiên `(word, hiragana)`
 * — không tạo từ mới, không xoá gì, không đổi `_id`, nên tiến độ SRS giữ
 * nguyên. Từ có trong file mà không có trong DB được báo ra, không tự thêm:
 * file nhãn không có nghĩa, nhập từ là việc của `import-vocabulary.js`.
 *
 * Cách dùng:
 *
 *   node scripts/apply-vocabulary-tags.js --dry-run
 *   node scripts/apply-vocabulary-tags.js
 *   node scripts/apply-vocabulary-tags.js --file data/vocabulary-tags.json --overwrite
 *
 * Cờ:
 *   --file <path>  Mặc định `data/vocabulary-tags.json`.
 *   --dry-run      Báo cáo, không ghi.
 *   --overwrite    Cho phép ghi đè nhãn đã khác trong DB (mặc định: báo xung đột).
 */

const DEFAULT_FILE = 'data/vocabulary-tags.json';
const LOG_LIMIT = 30;

const parseArgs = (argv) => {
  const args = { file: DEFAULT_FILE, dryRun: false, overwrite: false };
  for (let index = 0; index < argv.length; index += 1) {
    const flag = argv[index];
    if (flag === '--dry-run') args.dryRun = true;
    else if (flag === '--overwrite') args.overwrite = true;
    else if (flag === '--file') args.file = argv[(index += 1)];
    else throw new Error(`Cờ không nhận ra: ${flag}`);
  }
  return args;
};

const printSample = (title, items, format) => {
  if (items.length === 0) return;
  console.log(`\n${title} (${items.length}):`);
  items.slice(0, LOG_LIMIT).forEach((item) => console.log(`  ${format(item)}`));
  if (items.length > LOG_LIMIT) console.log(`  ... và ${items.length - LOG_LIMIT} dòng nữa`);
};

const main = async () => {
  const args = parseArgs(process.argv.slice(2));
  const rows = JSON.parse(await fs.readFile(args.file, 'utf8'));

  const { accepted, errors } = reviewTagRows(rows);
  printSample('Dòng lỗi, bỏ qua', errors, (e) => `dòng ${e.line}: ${e.messages.join(' ')}`);

  const uri = process.env.MONGODB_URI;
  if (!uri) throw new Error('Thiếu MONGODB_URI trong .env.');
  await mongoose.connect(uri, { dbName: process.env.DB_NAME || 'AppHocTiengNhat' });

  try {
    const existing = await Vocabulary.find({})
      .select('word hiragana level topic word_type difficulty')
      .lean();
    const byKey = new Map(existing.map((doc) => [tagKey(doc), doc]));

    const missing = [];
    const mismatched = [];
    const conflicts = [];
    const writes = [];
    let unchanged = 0;

    for (const row of accepted) {
      const doc = byKey.get(tagKey(row));
      if (!doc) {
        missing.push(row);
        continue;
      }

      const plan = planTagUpdate(doc, row, { overwrite: args.overwrite });
      if (plan.levelMismatch) {
        mismatched.push({ row, level: doc.level });
        continue;
      }
      plan.conflicts.forEach((conflict) => conflicts.push({ row, ...conflict }));
      if (Object.keys(plan.set).length === 0) {
        if (plan.conflicts.length === 0) unchanged += 1;
        continue;
      }
      writes.push({ updateOne: { filter: { _id: doc._id }, update: { $set: plan.set } } });
    }

    printSample('Không có trong DB', missing, (r) => `${r.word} (${r.hiragana}) ${r.level}`);
    printSample('Khác cấp độ, không ghi', mismatched, (m) =>
      `${m.row.word} (${m.row.hiragana}): file ${m.row.level}, DB ${m.level}`);
    printSample('Xung đột, không ghi (dùng --overwrite nếu chắc chắn)', conflicts, (c) =>
      `${c.row.word} (${c.row.hiragana}) ${c.field}: DB "${c.current}" ≠ file "${c.incoming}"`);

    if (!args.dryRun && writes.length > 0) {
      await Vocabulary.bulkWrite(writes, { ordered: false });
    }

    const verb = args.dryRun ? 'sẽ cập nhật' : 'đã cập nhật';
    console.log(`\nTổng: ${rows.length} dòng — ${verb} ${writes.length}, không đổi ${unchanged}, ` +
      `xung đột ${conflicts.length}, khác cấp ${mismatched.length}, ` +
      `không có trong DB ${missing.length}, lỗi ${errors.length}.`);
    if (args.dryRun) console.log('(--dry-run: chưa ghi gì)');
  } finally {
    await mongoose.disconnect();
  }
};

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
