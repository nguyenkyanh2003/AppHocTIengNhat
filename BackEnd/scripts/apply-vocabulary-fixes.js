import fs from 'node:fs/promises';

import mongoose from 'mongoose';
import dotenv from 'dotenv';

import Lesson from '../model/Lesson.js';
import LessonProgress from '../model/LessonProgress.js';
import NoteBook from '../model/NoteBook.js';
import SRSProgress from '../model/SRSProgress.js';
import Vocabulary from '../model/Vocabulary.js';
import { unitOfWork } from '../src/shared/db/unit-of-work.js';
import { keysToLoad, planFixes, reviewFixes } from '../src/modules/vocabulary/vocabulary-fixes.js';
import { vocabularyMergeRepository } from '../src/modules/vocabulary/vocabulary-merge.repository.js';
import { tagKey } from '../src/modules/vocabulary/vocabulary-tags.review.js';

dotenv.config();

/**
 * Áp file sửa kho từ vựng đã soát tay (`data/vocabulary-fixes.json`).
 *
 *   node scripts/apply-vocabulary-fixes.js --dry-run   # xem sẽ ghi gì
 *   node scripts/apply-vocabulary-fixes.js             # ghi
 *   node scripts/apply-vocabulary-fixes.js && node scripts/apply-vocabulary-tags.js
 *
 * Chạy lại bao nhiêu lần cũng được: dòng đã áp thì báo "đã xong" và không ghi
 * gì. DB khác lúc soát (nghĩa đã bị sửa tay, khoá mới đã là từ khác, từ được
 * viện dẫn không còn) thì **không ghi dòng nào** — một file sửa đúng một nửa
 * khó lần lại hơn một file chưa áp.
 *
 * Thứ tự ghi: các lệnh trên Vocabulary (thêm, sửa nghĩa, đổi khoá, xoá) trước,
 * rồi mỗi dòng gộp một transaction riêng.
 *
 * Từ mới chưa có nhãn chia bộ cho tới khi chạy `apply-vocabulary-tags.js`.
 */

const DEFAULT_FILE = 'data/vocabulary-fixes.json';
const STATUS_LABELS = Object.freeze({
  apply: 'sẽ ghi',
  done: 'đã xong',
  skip: 'không cần ghi',
  conflict: 'xung đột',
  missing: 'không tìm thấy',
});

const parseArgs = (argv) => {
  const args = { file: DEFAULT_FILE, dryRun: false };
  for (let index = 0; index < argv.length; index += 1) {
    const flag = argv[index];
    if (flag === '--dry-run') args.dryRun = true;
    else if (flag === '--file') args.file = argv[(index += 1)];
    else throw new Error(`Cờ không nhận ra: ${flag}`);
  }
  return args;
};

const describe = (fix) => {
  if (fix.action === 'rename') {
    return `${fix.from.word} (${fix.from.hiragana}) → ${fix.to.word} (${fix.to.hiragana})`;
  }
  return `${fix.word} (${fix.hiragana})`;
};

const loadExisting = async (fixes) => {
  const docs = await Vocabulary.find({ $or: keysToLoad(fixes) })
    .select('word hiragana meaning level lesson')
    .lean();
  return new Map(docs.map((doc) => [tagKey(doc), doc]));
};

/**
 * Nơi có thể trỏ tới một từ vựng bằng `_id`. Bản sao còn ai trỏ tới thì không
 * xoá: thẻ ôn của người học hay một bài học sẽ mất từ mà không ai biết.
 */
const REFERENCES = Object.freeze([
  ['thẻ ôn', (id) => SRSProgress.countDocuments({ item_type: 'Vocabulary', item_id: id })],
  ['bài học', (id) => Lesson.countDocuments({ vocabularies: id })],
  ['tiến độ bài học', (id) => LessonProgress.countDocuments({ learned_vocabulary_ids: id })],
  ['sổ tay', (id) => NoteBook.countDocuments({ $or: [{ related_item_id: id }, { 'items.item_id': id }] })],
  ['gắn với bài học', (id) => Vocabulary.countDocuments({ _id: id, lesson: { $ne: null } })],
]);

const referencesOf = async (id) => {
  const found = [];
  for (const [label, count] of REFERENCES) {
    const total = await count(id);
    if (total > 0) found.push(`${label} ${total}`);
  }
  return found;
};

const outcomeOf = (outcomes, action, filter) =>
  outcomes.find(({ fix }) => fix.action === action && fix.word === filter.word && fix.hiragana === filter.hiragana);

const markConflict = (outcome, detail) => {
  outcome.status = 'conflict';
  outcome.detail = detail;
};

/**
 * Kiểm phần planner thuần không thấy được vì phải hỏi các collection khác:
 * - `remove`: bản sao không được còn ai trỏ tới (nếu còn thì phải là `merge`);
 * - `merge`: không nơi nào trỏ tới **cả hai** bản (gộp sẽ sinh trùng).
 * Dòng vi phạm chuyển thành xung đột, và cả file không được ghi.
 */
const guardDuplicates = async (outcomes, operations) => {
  for (const operation of operations) {
    if (operation.deleteOne) {
      const { filter } = operation.deleteOne;
      const found = await referencesOf(filter._id);
      if (found.length > 0) {
        markConflict(outcomeOf(outcomes, 'remove', filter), `Bản sao vẫn còn được trỏ tới (${found.join(', ')}) — dùng merge.`);
      }
    }
    if (operation.merge) {
      const { fromId, intoId, filter } = operation.merge;
      const overlaps = await vocabularyMergeRepository.findOverlaps({ fromId, intoId });
      const found = Object.entries(overlaps).filter(([, count]) => count > 0);
      if (found.length > 0) {
        markConflict(
          outcomeOf(outcomes, 'merge', filter),
          `Có nơi trỏ tới cả hai bản (${found.map(([place, count]) => `${place} ${count}`).join(', ')}).`,
        );
      }
    }
  }
};

/** Mỗi dòng gộp một transaction: bước nào hỏng thì cả dòng đó huỷ. */
const runMerges = async (merges) => {
  const moved = { lessons: 0, progresses: 0, cards: 0, notes: 0 };
  for (const { merge } of merges) {
    const result = await unitOfWork.run(({ session }) => vocabularyMergeRepository.merge({ ...merge, session }));
    for (const [place, count] of Object.entries(result)) moved[place] += count;
  }
  return moved;
};

const printOutcomes = (outcomes) => {
  const counts = {};
  for (const { fix, status } of outcomes) {
    counts[status] ??= {};
    counts[status][fix.action] = (counts[status][fix.action] ?? 0) + 1;
  }
  for (const [status, byAction] of Object.entries(counts)) {
    const detail = Object.entries(byAction).map(([action, count]) => `${action} ${count}`).join(', ');
    console.log(`  ${STATUS_LABELS[status].padEnd(15)} ${detail}`);
  }

  const problems = outcomes.filter(({ status }) => status === 'conflict' || status === 'missing');
  for (const { fix, status, detail } of problems) {
    console.log(`  ✖ [${fix.source}] ${fix.action} ${describe(fix)} — ${STATUS_LABELS[status]}: ${detail}`);
  }
  return problems;
};

const main = async () => {
  const args = parseArgs(process.argv.slice(2));
  const raw = JSON.parse(await fs.readFile(args.file, 'utf8'));

  const { accepted, errors } = reviewFixes(raw);
  if (errors.length > 0) {
    console.error(`❌ ${args.file} có ${errors.length} dòng sai, chưa kết nối DB:`);
    for (const error of errors) {
      console.error(`   #${error.index} [${error.source ?? '?'}] ${error.messages.join(' ')}`);
    }
    process.exitCode = 1;
    return;
  }

  const uri = process.env.MONGODB_URI;
  if (!uri) throw new Error('Thiếu MONGODB_URI trong .env.');
  await mongoose.connect(uri, { dbName: process.env.DB_NAME || 'AppHocTiengNhat' });

  try {
    const { operations, outcomes } = planFixes(accepted, await loadExisting(accepted));
    await guardDuplicates(outcomes, operations);
    console.log(`📄 ${args.file}: ${accepted.length} dòng sửa`);
    const problems = printOutcomes(outcomes);

    if (problems.length > 0) {
      console.error(`\n❌ ${problems.length} dòng không khớp DB hiện tại — không ghi gì. Soát lại file sửa.`);
      process.exitCode = 1;
      return;
    }
    if (args.dryRun) {
      console.log(`\n🔍 --dry-run: ${operations.length} lệnh ghi, chưa ghi gì.`);
      return;
    }
    if (operations.length === 0) {
      console.log('\n✅ DB đã đúng theo file sửa, không có gì để ghi.');
      return;
    }

    const merges = operations.filter((operation) => operation.merge);
    const writes = operations.filter((operation) => !operation.merge);

    if (writes.length > 0) {
      const result = await Vocabulary.bulkWrite(writes, { ordered: true });
      const written = result.insertedCount + result.modifiedCount + result.deletedCount;
      console.log(`\n✅ Đã ghi: thêm ${result.insertedCount}, sửa ${result.modifiedCount}, xoá ${result.deletedCount}.`);
      if (written !== writes.length) {
        // Điều kiện ghi kèm giá trị cũ: lệnh không khớp nghĩa là DB vừa đổi giữa lúc đọc và lúc ghi.
        console.error(`⚠️  ${writes.length - written} lệnh không khớp bản ghi nào — chạy lại để xem trạng thái.`);
        process.exitCode = 1;
      }
    }
    if (merges.length > 0) {
      const moved = await runMerges(merges);
      console.log(`✅ Đã gộp ${merges.length} bản sao: chuyển ${moved.lessons} bài học, ` +
        `${moved.progresses} tiến độ bài, ${moved.cards} thẻ ôn, ${moved.notes} sổ tay.`);
    }
    console.log('Bước tiếp: node scripts/apply-vocabulary-tags.js (gắn nhãn chia bộ cho từ mới).');
  } finally {
    await mongoose.disconnect();
  }
};

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
