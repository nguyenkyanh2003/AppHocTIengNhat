import { isDeepStrictEqual } from 'node:util';

/**
 * Nhập nội dung học (Kanji, ngữ pháp, đề JLPT, bài tập mẫu) **không xoá gì bao giờ**.
 *
 * Các seed cũ gọi `deleteMany({})` rồi `insertMany`, nên mỗi lần chạy mọi
 * `_id` đổi: `SRSProgress.item_id`, `LessonProgress.learned_*_ids`,
 * `ExerciseResult.exercise_id` và `LearningHistory.exam` cùng trỏ vào hư
 * không. Ở đây bản ghi được nhận ra bằng **khoá tự nhiên** của nó, nên chạy
 * lại bao nhiêu lần `_id` vẫn thế — cùng khuôn với `import-vocabulary.js`:
 *
 * - chưa có → tạo;
 * - đã có và giống hệt → không làm gì;
 * - đã có nhưng khác → **báo xung đột, không ghi**, trừ khi chạy `--overwrite`.
 *
 * `planUpserts` là hàm thuần để test không cần MongoDB; `applyPlan` là nơi
 * duy nhất ghi.
 */

/** Bỏ `_id` của subdocument và đổi ObjectId/Date về chuỗi để so nội dung. */
const comparable = (value) => {
  if (Array.isArray(value)) return value.map(comparable);
  if (value instanceof Date) return value.toISOString();
  if (value && typeof value === 'object') {
    if (typeof value.toHexString === 'function') return value.toHexString();
    return Object.fromEntries(
      Object.entries(value)
        .filter(([key]) => key !== '_id')
        .map(([key, inner]) => [key, comparable(inner)]),
    );
  }
  return value;
};

/** Những trường file có mà giá trị trong DB khác. Trường file không có thì không xét. */
export const changedFields = (row, existing) =>
  Object.keys(row).filter((field) => !isDeepStrictEqual(comparable(row[field]), comparable(existing[field])));

/**
 * @param rows      Nội dung đọc từ file/seed.
 * @param existing  Bản ghi đang có trong DB, cùng khoá tự nhiên.
 * @param keyOf     Khoá tự nhiên của một bản ghi, dạng chuỗi.
 */
export const planUpserts = ({ rows, existing, keyOf }) => {
  const byKey = new Map(existing.map((doc) => [keyOf(doc), doc]));
  const seen = new Set();
  const plan = { create: [], update: [], unchanged: [], duplicates: [] };

  for (const row of rows) {
    const key = keyOf(row);
    if (seen.has(key)) {
      plan.duplicates.push(key);
      continue;
    }
    seen.add(key);

    const doc = byKey.get(key);
    if (!doc) {
      plan.create.push(row);
      continue;
    }
    const fields = changedFields(row, doc);
    if (fields.length === 0) plan.unchanged.push(key);
    else plan.update.push({ key, id: doc._id, row, fields });
  }

  return plan;
};

/** Ghi kế hoạch: tạo bản ghi mới; chỉ ghi đè bản ghi khác nhau khi được phép. */
export const applyPlan = async ({ model, plan, overwrite }) => {
  if (plan.create.length > 0) await model.insertMany(plan.create, { ordered: true });
  if (!overwrite) return;
  for (const { id, row } of plan.update) {
    await model.updateOne({ _id: id }, { $set: row }, { runValidators: true });
  }
};

/** In báo cáo số bản ghi theo từng nhóm, kèm tên trường khác nhau của bản ghi xung đột. */
export const printPlan = (label, plan, { overwrite = false, dryRun = false } = {}) => {
  console.log(`\n📊 ${label}`);
  console.log(`   tạo mới      ${plan.create.length}`);
  console.log(`   không đổi    ${plan.unchanged.length}`);
  console.log(`   ${overwrite ? 'ghi đè     ' : 'xung đột   '}  ${plan.update.length}`);
  for (const { key, fields } of plan.update) console.log(`     • ${key}: ${fields.join(', ')}`);
  if (plan.duplicates.length > 0) {
    console.log(`   trùng trong file (bỏ qua) ${plan.duplicates.length}: ${plan.duplicates.join(', ')}`);
  }
  if (dryRun) console.log('   🔍 --dry-run: không ghi gì.');
  else if (plan.update.length > 0 && !overwrite) {
    console.log('   ⚠️  Bản ghi khác nhau được giữ nguyên. Chạy lại với --overwrite để ghi đè.');
  }
};

/** Cờ dùng chung của các script nhập nội dung. */
export const parseFlags = (argv = process.argv.slice(2)) => {
  const known = new Set(['--dry-run', '--overwrite']);
  const unknown = argv.filter((flag) => !known.has(flag));
  if (unknown.length > 0) throw new Error(`Cờ không nhận ra: ${unknown.join(', ')}`);
  return { dryRun: argv.includes('--dry-run'), overwrite: argv.includes('--overwrite') };
};
