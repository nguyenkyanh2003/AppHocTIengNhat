import { createHash } from 'node:crypto';

import mongoose from 'mongoose';

/**
 * Định dạng file sao lưu: mảng EJSON **canonical**, sắp theo `_id`.
 *
 * Không dùng `JSON.stringify` như bản sao lưu bài học cũ: JSON thường biến
 * ObjectId và Date thành chuỗi, nên khôi phục ra dữ liệu **khác kiểu** — một
 * `user` kiểu chuỗi không khớp `user` kiểu ObjectId ở bất kỳ truy vấn nào. EJSON
 * canonical giữ đúng kiểu BSON, và vì sắp theo `_id` nên cùng dữ liệu luôn ra
 * cùng một checksum — đó là cách so bản sao lưu với bản khôi phục.
 */
const { EJSON } = mongoose.mongo.BSON;

const byId = (a, b) => String(a._id).localeCompare(String(b._id));

export const serializeDocuments = (documents) =>
  EJSON.stringify([...documents].sort(byId), { relaxed: false });

export const parseDocuments = (text) => EJSON.parse(text, { relaxed: false });

export const checksumOf = (documents) =>
  createHash('sha256').update(serializeDocuments(documents)).digest('hex');

/** Collection mà migration streak đọc hoặc ghi — mặc định của bản sao lưu. */
export const STREAK_MIGRATION_COLLECTIONS = Object.freeze([
  'userstreaks',
  'activityevents',
  'streakdays',
  'userachievements',
  'achievements',
  'lessonprogresses',
  'srsprogresses',
]);

/**
 * Bản sao lưu dùng được cho migration khi có đủ collection và **đã khôi phục
 * thử** thành công ở một database khác — đọc lại được file chưa đủ chứng minh
 * dựng lại được dữ liệu.
 */
export const backupProblems = (manifest, required = STREAK_MIGRATION_COLLECTIONS) => {
  if (!manifest) return ['Không đọc được manifest.json của bản sao lưu.'];
  const problems = required
    .filter((name) => !manifest.collections?.[name])
    .map((name) => `Bản sao lưu thiếu collection ${name}.`);
  if (!manifest.restore_checked_at) {
    problems.push('Bản sao lưu chưa được khôi phục thử (chạy restore-collections.js vào một database khác).');
  }
  return problems;
};
