import { isDeepStrictEqual } from 'node:util';

/**
 * Khoá tự nhiên của nội dung học — đúng khoá mà các script nhập dùng để nhận
 * ra "bản ghi này đã có": `seed-grammar.js` (`level:title`),
 * `seed-exercises.js` (`lesson_id:title`), `seed-jlpt.js` và
 * `import-jlpt-n3-2024-07.js` (`title`).
 *
 * Model khai báo unique index trên đúng các khoá này; `ensure-content-indexes.js`
 * rà trùng rồi tạo và xác minh chúng trên DB thật. Test giữ ba nơi khớp nhau:
 * lệch một chỗ thì script nhập coi hai bản là một trong khi DB coi là hai, hoặc
 * ngược lại.
 */
export const NATURAL_KEYS = Object.freeze([
  Object.freeze({
    label: 'Ngữ pháp',
    collection: 'grammars',
    name: 'grammar_natural_key',
    key: Object.freeze({ level: 1, title: 1 }),
  }),
  Object.freeze({
    label: 'Bài tập',
    collection: 'exercises',
    name: 'exercise_natural_key',
    key: Object.freeze({ lesson_id: 1, title: 1 }),
  }),
  Object.freeze({
    label: 'Đề JLPT',
    collection: 'jlpts',
    name: 'jlpt_natural_key',
    key: Object.freeze({ title: 1 }),
  }),
]);

/** Pipeline gom các nhóm bản ghi trùng khoá tự nhiên, nhóm đông nhất trước. */
export const duplicatePipeline = (key) => [
  {
    $group: {
      _id: Object.fromEntries(Object.keys(key).map((field) => [field, `$${field}`])),
      count: { $sum: 1 },
      ids: { $push: '$_id' },
    },
  },
  { $match: { count: { $gt: 1 } } },
  { $sort: { count: -1 } },
];

/**
 * Index khoá tự nhiên đã có thật chưa — phải đúng trường **và** có cờ unique.
 * Một index thường trên cùng trường chỉ tăng tốc đọc, không chặn trùng.
 */
export const findNaturalKeyIndex = (indexes, spec) =>
  indexes.find((index) => index.unique === true && isDeepStrictEqual(index.key, { ...spec.key })) ??
  null;
