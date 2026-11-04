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

test('chuỗi ISO 8601 đã có múi giờ giữ nguyên — nó đã chỉ đúng một thời điểm', () => {
  const result = convertDatesToVietnam({
    created_at: '2026-11-04T08:00:00.000Z',
    updatedAt: '2026-11-04T15:00:00+07:00',
    completed_at: '2026-11-04T15:00:00+0700',
  });

  assert.deepEqual(result, {
    created_at: '2026-11-04T08:00:00.000Z',
    updatedAt: '2026-11-04T15:00:00+07:00',
    completed_at: '2026-11-04T15:00:00+0700',
  });
});

test('Date và chuỗi chưa có múi giờ vẫn đổi sang giờ Việt Nam như trước', () => {
  const result = convertDatesToVietnam({
    createdAt: new Date('2026-11-04T08:00:00Z'),
    NgayTao: '2026-11-04 08:00:00',
  });

  assert.equal(result.createdAt, '2026-11-04 15:00:00');
  assert.match(result.NgayTao, /^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$/);
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
