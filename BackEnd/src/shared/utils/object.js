/**
 * Bỏ các khoá mang giá trị `undefined`, giữ nguyên `null`, `0`, `''` và `false`.
 *
 * Với Mongo, `{ status: undefined }` vẫn là một điều kiện lọc và `$set` một
 * `undefined` là xoá nội dung cũ — nên tham số không truyền phải bị bỏ hẳn.
 */
export const withoutUndefined = (object) =>
  Object.fromEntries(Object.entries(object).filter(([, value]) => value !== undefined));
