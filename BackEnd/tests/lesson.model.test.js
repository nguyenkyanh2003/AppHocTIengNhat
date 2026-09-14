import assert from 'node:assert/strict';
import test from 'node:test';

import Lesson from '../model/Lesson.js';
import { SITUATIONS } from '../src/modules/lessons/situation-catalog.js';

test('SITUATIONS là danh sách cố định, không rỗng, không trùng giá trị', () => {
  assert.ok(Array.isArray(SITUATIONS));
  assert.ok(SITUATIONS.length > 0);
  assert.equal(new Set(SITUATIONS).size, SITUATIONS.length);
});

test('Lesson.situation là enum theo SITUATIONS, optional, mặc định null, có index', () => {
  const path = Lesson.schema.path('situation');
  assert.ok(path, 'field situation phải tồn tại trên schema');
  assert.deepEqual(path.enumValues, SITUATIONS);
  assert.equal(path.options.default, null);
  assert.ok(!path.isRequired, 'situation không được là field bắt buộc');

  const indexes = Lesson.schema.indexes();
  const hasSituationIndex = indexes.some(([fields]) => 'situation' in fields);
  assert.ok(hasSituationIndex, 'situation phải có index vì dùng để lọc danh sách');
});

test('level/title vẫn giữ đúng ràng buộc cũ sau khi thêm field mới', () => {
  assert.deepEqual(Lesson.schema.path('level').enumValues, ['N5', 'N4', 'N3', 'N2', 'N1']);
  assert.equal(Lesson.schema.path('title').isRequired, true);
});
