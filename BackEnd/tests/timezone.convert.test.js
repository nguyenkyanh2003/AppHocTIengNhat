import assert from 'node:assert/strict';
import test from 'node:test';

import { convertDatesToVietnam } from '../src/shared/utils/timezone.js';

test('giá trị chuỗi đi qua nguyên vẹn, không bị tách thành object ký tự', () => {
  assert.equal(convertDatesToVietnam('restaurant'), 'restaurant');
});

test('mảng chuỗi giữ nguyên từng phần tử', () => {
  assert.deepEqual(
    convertDatesToVietnam(['restaurant', 'supermarket', 'train']),
    ['restaurant', 'supermarket', 'train'],
  );
});

test('số và boolean đi qua nguyên vẹn', () => {
  assert.equal(convertDatesToVietnam(42), 42);
  assert.equal(convertDatesToVietnam(true), true);
});

test('vẫn convert đúng field date trong object như trước', () => {
  const result = convertDatesToVietnam({
    title: 'Bài 1',
    createdAt: new Date('2026-09-14T03:00:00Z'),
  });

  assert.equal(result.title, 'Bài 1');
  assert.equal(typeof result.createdAt, 'string');
  assert.match(result.createdAt, /^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$/);
});

test('mảng object vẫn được convert từng phần tử như trước', () => {
  const result = convertDatesToVietnam([
    { title: 'A', createdAt: new Date('2026-09-14T03:00:00Z') },
    { title: 'B' },
  ]);

  assert.equal(result.length, 2);
  assert.equal(typeof result[0].createdAt, 'string');
  assert.equal(result[1].title, 'B');
});

test('mảng chuỗi lồng trong object vẫn nguyên vẹn (vỏ { data })', () => {
  const result = convertDatesToVietnam({ can_do_goals: ['Gọi được món'] });

  assert.deepEqual(result.can_do_goals, ['Gọi được món']);
});
