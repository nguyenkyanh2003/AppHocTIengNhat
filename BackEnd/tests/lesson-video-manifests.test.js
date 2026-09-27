import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import test from 'node:test';

import { allManifestNames, manifestsByLesson, parseLevel, parseManifestName } from '../scripts/lesson-video-manifests.js';

test('tên file mô tả cho biết trình độ và số bài', () => {
  assert.deepEqual(parseManifestName('n4-16-job-hunting.json'), { level: 'N4', lesson: 16 });
  assert.deepEqual(parseManifestName('n5-01-greeting.json'), { level: 'N5', lesson: 1 });
  assert.equal(parseManifestName('n5-01-greeting.txt'), null);
  assert.equal(parseManifestName('ghi-chu.json'), null);
});

test('--level nhận cả chữ thường, sai thì báo các giá trị hợp lệ', () => {
  assert.equal(parseLevel('n4'), 'N4');
  assert.throws(() => parseLevel('N6'), /N5, N4, N3, N2, N1/);
});

test('cùng số bài ở hai trình độ không lẫn vào nhau; danh sách chung sắp N5 trước', () => {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'manifests-'));
  for (const name of ['n4-02-b.json', 'n5-02-a.json', 'n4-10-c.json', 'n5-02-a.txt']) fs.writeFileSync(path.join(dir, name), '{}');

  assert.deepEqual([...manifestsByLesson('N4', dir)], [[2, 'n4-02-b.json'], [10, 'n4-10-c.json']]);
  assert.deepEqual([...manifestsByLesson('N5', dir)], [[2, 'n5-02-a.json']]);
  assert.deepEqual(allManifestNames(dir), ['n5-02-a.json', 'n4-02-b.json', 'n4-10-c.json']);
  fs.rmSync(dir, { recursive: true });
});
