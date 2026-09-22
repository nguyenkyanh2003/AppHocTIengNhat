import {
  DIFFICULTY_VALUES,
  TOPIC_CODES,
  TOPIC_LEVELS,
  WORD_TYPE_CODES,
} from './vocabulary-taxonomy.js';

/**
 * Kiểm file nhãn chia bộ (`data/vocabulary-tags.json`) và tính việc cần ghi.
 *
 * Tách khỏi script để test được không cần MongoDB, giống
 * `vocabulary-import.review.js`. File nhãn là dữ liệu soạn tay, nên mọi lỗi
 * phải chỉ ra đúng dòng — không được lọc bỏ trong im lặng.
 */

const LEVELS = ['N5', 'N4', 'N3', 'N2', 'N1'];
export const TAG_FIELDS = Object.freeze(['topic', 'word_type', 'difficulty']);

const keyOf = (row) => `${row.word}\u0000${row.hiragana}`;

const rowErrors = (row) => {
  if (row === null || typeof row !== 'object') return ['Dòng không phải object.'];

  const errors = [];
  if (typeof row.word !== 'string' || !row.word) errors.push('Thiếu `word`.');
  if (typeof row.hiragana !== 'string' || !row.hiragana) errors.push('Thiếu `hiragana`.');
  if (!LEVELS.includes(row.level)) errors.push(`Cấp độ không hợp lệ: ${row.level}.`);
  if (!WORD_TYPE_CODES.includes(row.word_type)) {
    errors.push(`Từ loại không hợp lệ: ${row.word_type}.`);
  }

  // Mỗi cấp chỉ mang đúng trường mà cách chia của nó dùng. Một từ N3 có
  // `topic` hay một từ N5 có `difficulty` là dấu hiệu file bị trộn nhầm cấp.
  if (TOPIC_LEVELS.includes(row.level)) {
    if (!TOPIC_CODES.includes(row.topic)) errors.push(`Chủ đề không hợp lệ: ${row.topic}.`);
    if (row.difficulty !== undefined) errors.push(`${row.level} chia theo chủ đề, không có \`difficulty\`.`);
  } else if (LEVELS.includes(row.level)) {
    if (!DIFFICULTY_VALUES.includes(row.difficulty)) {
      errors.push(`Độ khó không hợp lệ: ${row.difficulty}.`);
    }
    if (row.topic !== undefined) errors.push(`${row.level} chia theo từ loại, không có \`topic\`.`);
  }
  return errors;
};

/**
 * Trả về `{ accepted, errors }`. `errors[i].line` đánh số từ 1 theo vị trí
 * trong mảng, để người sửa tìm được dòng.
 */
export const reviewTagRows = (rows) => {
  if (!Array.isArray(rows)) {
    return { accepted: [], errors: [{ line: 0, messages: ['File phải là một mảng JSON.'] }] };
  }

  const accepted = [];
  const errors = [];
  const seen = new Map();

  rows.forEach((row, index) => {
    const line = index + 1;
    const messages = rowErrors(row);
    if (messages.length === 0) {
      const first = seen.get(keyOf(row));
      if (first) messages.push(`Trùng với dòng ${first} (cùng từ và cùng cách đọc).`);
      else seen.set(keyOf(row), line);
    }

    if (messages.length > 0) errors.push({ line, messages });
    else accepted.push(row);
  });

  return { accepted, errors };
};

const isEmpty = (value) => value === undefined || value === null || value === '';

/**
 * Tính trường cần ghi cho một từ đã có trong DB.
 *
 * Giống công cụ nhập từ vựng: ô trống thì điền, giá trị giống thì bỏ qua,
 * giá trị khác là **xung đột** và mặc định không ghi — trừ khi `overwrite`.
 * Nhờ vậy chạy lại file bao nhiêu lần cũng cho cùng kết quả, và nhãn ai đó đã
 * sửa tay trong DB không bị file cũ đè mất.
 *
 * Cấp độ khác nhau thì không ghi gì: nhãn được soạn theo cách chia của cấp
 * trong file, gắn vào một từ đang ở cấp khác là gắn sai cách chia.
 */
export const planTagUpdate = (existing, row, { overwrite = false } = {}) => {
  if (existing.level !== row.level) {
    return { set: {}, conflicts: [], levelMismatch: true };
  }

  const set = {};
  const conflicts = [];
  for (const field of TAG_FIELDS) {
    const value = row[field];
    if (value === undefined) continue;

    const current = existing[field];
    if (isEmpty(current)) set[field] = value;
    else if (current === value) continue;
    else if (overwrite) set[field] = value;
    else conflicts.push({ field, current, incoming: value });
  }
  return { set, conflicts, levelMismatch: false };
};

export const tagKey = keyOf;
