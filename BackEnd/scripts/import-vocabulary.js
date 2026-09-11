import fs from 'node:fs/promises';
import path from 'node:path';

import mongoose from 'mongoose';
import dotenv from 'dotenv';

import Vocabulary from '../model/Vocabulary.js';
import Lesson from '../model/Lesson.js';
import { mapHeaders, reviewRows } from '../src/modules/vocabulary/vocabulary-import.review.js';
import { parseCsv, parseWorkbook } from '../src/modules/vocabulary/vocabulary-import.file.js';

dotenv.config();

/**
 * Nhập từ vựng từ CSV hoặc Excel — **không xoá gì bao giờ**.
 *
 * Thay cho `seed-vocabulary.js`, script này khác ở ba điểm, và cả ba đều là
 * lý do nó tồn tại:
 *
 * 1. **Không `deleteMany`.** Seed cũ xoá sạch collection rồi ghi lại, nên mọi
 *    `_id` đổi sau mỗi lần chạy. `SRSProgress.item_id` và
 *    `LessonProgress.learned_vocabulary_ids` trỏ bằng ObjectId trần, nên mỗi
 *    lần seed là một lần người học mất sạch tiến độ. Script này upsert theo
 *    khoá tự nhiên `(word, hiragana)`: chạy lại bao nhiêu lần, `_id` vẫn thế.
 * 2. **Báo lỗi từng dòng.** Seed cũ (và `toVocabularyRows`) lọc bỏ dòng thiếu
 *    cột trong im lặng.
 * 3. **Có `--dry-run`.** Xem trước toàn bộ báo cáo mà không ghi một byte nào.
 *
 * Cách dùng:
 *
 *   node scripts/import-vocabulary.js --file data/n5.csv --dry-run
 *   node scripts/import-vocabulary.js --file data/n5.xlsx --level N5
 *   node scripts/import-vocabulary.js --file data/n5.csv --lesson "Bài 1"
 *
 * Cờ:
 *   --file <path>    Bắt buộc. `.csv`, `.tsv` hoặc `.xlsx`.
 *   --dry-run        Kiểm và báo cáo, không ghi.
 *   --level <N5..N1> Cấp độ mặc định cho dòng không có cột cấp độ.
 *   --lesson <title> Gán mọi dòng vào một document `Lesson` có sẵn (theo
 *                    `title`). Khác với cột "Bài" trong file — cột đó chỉ là
 *                    nhãn của giáo trình, lưu vào `source_lesson`.
 *   --overwrite      Cho phép file ghi đè giá trị đã khác trong DB. Mặc định
 *                    tắt: giá trị khác nhau được báo là xung đột, không ghi.
 *   --max-errors <n> Số lỗi in ra trước khi rút gọn (mặc định 50).
 */

const LOG_LIMIT_DEFAULT = 50;

const parseArgs = (argv) => {
  const args = { dryRun: false, maxErrors: LOG_LIMIT_DEFAULT };

  for (let index = 0; index < argv.length; index += 1) {
    const flag = argv[index];
    const next = () => argv[(index += 1)];

    if (flag === '--dry-run') args.dryRun = true;
    else if (flag === '--file') args.file = next();
    else if (flag === '--level') args.level = next();
    else if (flag === '--lesson') args.lesson = next();
    else if (flag === '--max-errors') args.maxErrors = Number(next());
    else if (flag === '--overwrite') args.overwrite = true;
    else if (flag.startsWith('--')) throw new Error(`Cờ không nhận ra: ${flag}`);
  }

  if (!args.file) throw new Error('Thiếu --file <đường dẫn>.');
  return args;
};

const readFile = async (file) => {
  const extension = path.extname(file).toLowerCase();
  if (extension === '.xlsx' || extension === '.xlsm') {
    return parseWorkbook(await fs.readFile(file));
  }
  if (extension === '.csv' || extension === '.tsv' || extension === '.txt') {
    return parseCsv(await fs.readFile(file, 'utf8'));
  }
  throw new Error(`Định dạng không hỗ trợ: ${extension || '(không có đuôi)'}. Dùng .csv hoặc .xlsx.`);
};

const connect = async () => {
  const uri = process.env.MONGODB_URI;
  if (!uri) throw new Error('Thiếu MONGODB_URI trong .env.');
  await mongoose.connect(uri, { dbName: process.env.DB_NAME || 'AppHocTiengNhat' });
};

/**
 * Ghi một từ, trả về việc đã xảy ra: `created`, `updated` hay `unchanged`.
 *
 * Phân biệt `updated` với `unchanged` để báo cáo nói được sự thật. Chạy lại
 * cùng một file mà thấy "đã cập nhật 800 từ" thì không ai biết upsert có thật
 * sự idempotent hay không; thấy "800 không đổi" thì biết ngay.
 *
 * `$setOnInsert` cho `lesson`: đã gán bài rồi thì lần nhập sau không được
 * lặng lẽ gỡ ra chỉ vì file lần này không có cột bài học.
 */
const upsertWord = async (row, { lessonId, overwrite }) => {
  const key = { word: row.word, hiragana: row.hiragana };
  const existing = await Vocabulary.findOne(key).lean();

  // Chỉ ghi những trường file **thật sự có**. Ghi `null` đè lên giá trị đã có
  // nghĩa là một file thiếu cột sẽ xoá sạch dữ liệu của lần nhập trước — vd
  // nhập bổ sung cấp độ xong rồi nhập lại file gốc là mất hết Hán-Việt.
  const incoming = { meaning: row.meaning };
  if (row.usage_context) incoming.usage_context = row.usage_context;
  if (row.level) incoming.level = row.level;
  if (row.hanviet) incoming.hanviet = row.hanviet;
  if (row.verb_group) incoming.verb_group = row.verb_group;
  if (row.lessonTitle) incoming.source_lesson = row.lessonTitle;
  if (row.examples.length > 0) incoming.examples = row.examples;
  if (lessonId) incoming.lesson = lessonId;

  if (!existing) {
    await Vocabulary.updateOne(key, { $set: incoming }, { upsert: true, runValidators: true });
    return { outcome: 'created', conflicts: [] };
  }

  // Từ đã có: ba tình huống khác hẳn nhau.
  //
  // - Ô trong DB đang trống → điền vào. Đây là **bổ sung**, luôn an toàn.
  // - Giá trị giống hệt → không làm gì.
  // - Giá trị khác → **xung đột**, mặc định không ghi.
  //
  // Nhánh thứ ba là lý do cả khối này tồn tại. File N4 chứa 19 từ vốn là N5
  // được dạy lại với nghĩa mới (もう: "Đã, rồi" → "Không ~ nữa"). Ghi đè lặng
  // lẽ vừa hạ cấp độ xuống sai, vừa xoá mất nghĩa cũ — và không ai biết.
  const fields = {};
  const conflicts = [];
  for (const [field, value] of Object.entries(incoming)) {
    const current = existing[field];
    if (current === undefined || current === null || current === '') {
      fields[field] = value;
      continue;
    }

    const same =
      field === 'examples' || field === 'lesson'
        ? JSON.stringify(current) === JSON.stringify(value)
        : String(current) === String(value);
    if (same) continue;

    if (overwrite) fields[field] = value;
    else conflicts.push({ line: row.line, word: row.word, field, current, incoming: value });
  }

  if (Object.keys(fields).length === 0) {
    return { outcome: conflicts.length > 0 ? 'conflict' : 'unchanged', conflicts };
  }

  await Vocabulary.updateOne(key, { $set: fields }, { runValidators: true });
  return { outcome: conflicts.length > 0 ? 'conflict' : 'updated', conflicts };
};

/**
 * Tìm các cặp `(word, hiragana)` đã trùng sẵn trong DB.
 *
 * Phải chạy **trước** khi ghi. Unique index `(word, hiragana)` là thứ khiến
 * upsert an toàn, nhưng Mongoose không dựng được index đó nếu dữ liệu hiện có
 * đã vi phạm — và nó báo lỗi qua event `index` của model chứ không ném ra chỗ
 * gọi. Không kiểm ở đây thì kịch bản tệ nhất là: index không tồn tại, upsert
 * vẫn chạy, và bản sao cứ sinh ra trong im lặng đúng như công cụ cũ.
 */
const findExistingDuplicates = async () => {
  const groups = await Vocabulary.aggregate([
    { $group: { _id: { word: '$word', hiragana: '$hiragana' }, count: { $sum: 1 } } },
    { $match: { count: { $gt: 1 } } },
    { $sort: { count: -1 } },
    { $limit: 20 },
  ]);
  return groups;
};

const printErrors = (errors, limit) => {
  console.log(`\n❌ ${errors.length} dòng có lỗi:`);
  for (const error of errors.slice(0, limit)) {
    console.log(`   dòng ${String(error.line).padStart(4)} · ${error.field.padEnd(14)} ${error.message}`);
  }
  if (errors.length > limit) {
    console.log(`   … và ${errors.length - limit} lỗi nữa (tăng --max-errors để xem hết).`);
  }
};

const main = async () => {
  const args = parseArgs(process.argv.slice(2));

  const { headers, rows } = await readFile(args.file);
  if (rows.length === 0) {
    console.log('File không có dòng dữ liệu nào.');
    return;
  }

  const columns = mapHeaders(headers);
  if (columns.missing.length > 0) {
    // Thiếu cột là lỗi của cả file: báo một lần rồi dừng, thay vì in ra hàng
    // trăm dòng lỗi giống hệt nhau.
    console.error(`❌ File thiếu cột bắt buộc: ${columns.missing.join(', ')}.`);
    console.error(`   Header đọc được: ${headers.join(' | ')}`);
    process.exitCode = 1;
    return;
  }

  const { accepted, errors, skipped } = reviewRows(rows, { level: args.level, columns });

  console.log(`📄 ${path.basename(args.file)}`);
  console.log(`   ${rows.length} dòng · ${accepted.length} hợp lệ · ${errors.length} lỗi · ${skipped} dòng trống`);
  if (errors.length > 0) printErrors(errors, args.maxErrors);

  if (args.dryRun) {
    console.log('\n🔍 --dry-run: không ghi gì vào DB.');
    if (accepted.length > 0) {
      console.log('   Ví dụ ba dòng đầu sẽ được ghi:');
      for (const row of accepted.slice(0, 3)) {
        const marks = [row.level, row.hanviet, row.verb_group && `nhóm ${row.verb_group}`]
          .filter(Boolean)
          .join(' · ');
        console.log(`   · ${row.word} (${row.hiragana}) — ${row.meaning}${marks ? `  [${marks}]` : ''}`);
      }
    }
    return;
  }

  if (accepted.length === 0) {
    console.log('\nKhông có dòng nào hợp lệ để ghi.');
    process.exitCode = errors.length > 0 ? 1 : 0;
    return;
  }

  await connect();
  try {
    const duplicates = await findExistingDuplicates();
    if (duplicates.length > 0) {
      console.error(`\n❌ DB đang có ${duplicates.length} cặp (từ, cách đọc) bị trùng sẵn.`);
      console.error('   Phải dọn trước khi nhập, nếu không unique index không dựng được:');
      for (const group of duplicates) {
        console.error(`   · ${group._id.word} (${group._id.hiragana}) — ${group.count} bản ghi`);
      }
      process.exitCode = 1;
      return;
    }

    let lessonId = null;
    if (args.lesson) {
      const lesson = await Lesson.findOne({ title: args.lesson }).lean();
      // Không tự tạo bài học: một lỗi gõ tên sẽ sinh ra bài ma, và từ vựng
      // rơi vào đó thì không ai tìm thấy.
      if (!lesson) throw new Error(`Không tìm thấy bài học có title "${args.lesson}".`);
      lessonId = lesson._id;
    }

    const tally = { created: 0, updated: 0, unchanged: 0, conflict: 0 };
    const conflicts = [];
    for (const row of accepted) {
      const result = await upsertWord(row, { lessonId, overwrite: args.overwrite });
      tally[result.outcome] += 1;
      conflicts.push(...result.conflicts);
    }

    console.log(
      `
✅ Ghi xong: ${tally.created} thêm mới · ${tally.updated} cập nhật · ${tally.unchanged} không đổi`,
    );
    if (conflicts.length > 0) {
      console.log(`
⚠️  ${conflicts.length} giá trị khác với DB, KHÔNG ghi đè:`);
      for (const conflict of conflicts.slice(0, args.maxErrors)) {
        console.log(`   dòng ${String(conflict.line).padStart(4)} · ${conflict.word} · ${conflict.field}`);
        console.log(`        DB đang có : ${conflict.current}`);
        console.log(`        file muốn  : ${conflict.incoming}`);
      }
      if (conflicts.length > args.maxErrors) {
        console.log(`   … và ${conflicts.length - args.maxErrors} xung đột nữa.`);
      }
      console.log('   Thêm --overwrite nếu muốn file thắng.');
    }
    console.log(`   Tổng số từ trong DB: ${await Vocabulary.countDocuments()}`);
  } finally {
    await mongoose.disconnect();
  }

  if (errors.length > 0) process.exitCode = 1;
};

main().catch((error) => {
  console.error(`❌ ${error.message}`);
  process.exitCode = 1;
});
