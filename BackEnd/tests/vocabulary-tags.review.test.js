import assert from 'node:assert/strict';
import fs from 'node:fs';
import test from 'node:test';

import {
  planTagUpdate,
  reviewTagRows,
} from '../src/modules/vocabulary/vocabulary-tags.review.js';

const n5 = (over = {}) => ({
  word: '学生', hiragana: 'がくせい', level: 'N5', topic: 'school', word_type: 'n', ...over,
});
const n3 = (over = {}) => ({
  word: '努力', hiragana: 'どりょく', level: 'N3', word_type: 'n', difficulty: 1, ...over,
});

// --- kiểm dòng -----------------------------------------------------------

test('dòng hợp lệ của cả hai cách chia đều được nhận', () => {
  const { accepted, errors } = reviewTagRows([n5(), n3()]);
  assert.equal(accepted.length, 2);
  assert.deepEqual(errors, []);
});

test('mã chủ đề, từ loại, độ khó lạ bị báo đúng dòng', () => {
  const { accepted, errors } = reviewTagRows([
    n5({ topic: 'sport' }),
    n5({ word: '先生', hiragana: 'せんせい', word_type: 'noun' }),
    n3({ difficulty: 4 }),
  ]);
  assert.equal(accepted.length, 0);
  assert.deepEqual(errors.map((e) => e.line), [1, 2, 3]);
});

test('cấp chia theo chủ đề không được mang độ khó và ngược lại', () => {
  // Dấu hiệu file bị trộn nhầm cấp — nhận vào là gắn sai cách chia.
  const { errors } = reviewTagRows([n5({ difficulty: 1 }), n3({ topic: 'work' })]);
  assert.equal(errors.length, 2);
});

test('N5 thiếu chủ đề hoặc N3 thiếu độ khó bị từ chối', () => {
  const { errors } = reviewTagRows([n5({ topic: undefined }), n3({ difficulty: undefined })]);
  assert.equal(errors.length, 2);
});

test('trùng từ và cách đọc: giữ dòng đầu, báo dòng sau', () => {
  const { accepted, errors } = reviewTagRows([n5(), n5({ topic: 'people' })]);
  assert.equal(accepted.length, 1);
  assert.equal(errors[0].line, 2);
  assert.match(errors[0].messages[0], /dòng 1/);
});

test('file không phải mảng bị từ chối cả file', () => {
  const { accepted, errors } = reviewTagRows({ word: '学生' });
  assert.equal(accepted.length, 0);
  assert.equal(errors.length, 1);
});

// --- tính việc cần ghi ---------------------------------------------------

test('ô trống thì điền, giá trị giống thì bỏ qua', () => {
  const plan = planTagUpdate({ level: 'N5', word_type: 'n' }, n5());
  assert.deepEqual(plan.set, { topic: 'school' });
  assert.deepEqual(plan.conflicts, []);
});

test('giá trị khác là xung đột, không ghi nếu không có overwrite', () => {
  const existing = { level: 'N5', topic: 'work', word_type: 'n' };
  const safe = planTagUpdate(existing, n5());
  assert.deepEqual(safe.set, {});
  assert.deepEqual(safe.conflicts, [{ field: 'topic', current: 'work', incoming: 'school' }]);

  const forced = planTagUpdate(existing, n5(), { overwrite: true });
  assert.deepEqual(forced.set, { topic: 'school' });
});

test('từ đang ở cấp khác thì không ghi gì', () => {
  const plan = planTagUpdate({ level: 'N4' }, n5());
  assert.equal(plan.levelMismatch, true);
  assert.deepEqual(plan.set, {});
});

test('chạy lại trên dữ liệu đã gắn nhãn không ghi thêm gì', () => {
  const plan = planTagUpdate({ level: 'N3', word_type: 'n', difficulty: 1 }, n3());
  assert.deepEqual(plan.set, {});
  assert.deepEqual(plan.conflicts, []);
});

// --- file dữ liệu thật ---------------------------------------------------

test('data/vocabulary-tags.json hợp lệ toàn bộ', () => {
  const rows = JSON.parse(fs.readFileSync(new URL('../data/vocabulary-tags.json', import.meta.url), 'utf8'));
  const { accepted, errors } = reviewTagRows(rows);
  assert.deepEqual(errors, []);
  assert.equal(accepted.length, rows.length);
});
