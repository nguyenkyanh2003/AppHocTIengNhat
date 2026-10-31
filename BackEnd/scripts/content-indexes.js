import { isDeepStrictEqual } from 'node:util';

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
