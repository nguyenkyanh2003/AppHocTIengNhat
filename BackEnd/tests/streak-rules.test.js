import assert from 'node:assert/strict';
import test from 'node:test';
import { dayKey, daysBetween, applyActivity, projectStreak } from '../src/modules/streaks/streak-rules.js';

const state = { currentStreak: 5, longestStreak: 9, lastActivityDay: '2026-09-09', freezesAvailable: 0 };
test('Vietnam calendar boundary is independent of host timezone', () => {
  assert.equal(dayKey(new Date('2026-09-09T16:59:00Z')), '2026-09-09');
  assert.equal(dayKey(new Date('2026-09-09T17:01:00Z')), '2026-09-10');
  assert.equal(dayKey(new Date('2026-09-09T17:01:00Z'), 'UTC'), '2026-09-09');
});
test('calendar differences validate dates and handle leap years', () => {
  assert.equal(daysBetween('2024-02-28', '2024-03-01'), 2);
  assert.equal(daysBetween('2026-12-31', '2027-01-01'), 1);
  assert.throws(() => daysBetween('2026-02-30', '2026-03-01'), RangeError);
});
test('first study, same day, consecutive day, and future state', () => {
  assert.equal(applyActivity({}, '2026-09-10').currentStreak, 1);
  assert.equal(applyActivity(state, '2026-09-09').currentStreak, 5);
  assert.equal(applyActivity(state, '2026-09-10').currentStreak, 6);
  assert.equal(applyActivity(state, '2026-09-08').lastActivityDay, '2026-09-09');
});
test('freeze covers ended days without adding them to studied streak length', () => {
  const next = applyActivity({ ...state, freezesAvailable: 2 }, '2026-09-12');
  assert.equal(next.currentStreak, 6);
  assert.equal(next.freezesUsed, 2);
  assert.deepEqual(next.frozenDays, ['2026-09-10', '2026-09-11']);
});
test('insufficient freezes consumes protected days and preserves longest streak', () => {
  const next = applyActivity({ ...state, freezesAvailable: 2 }, '2026-09-13');
  assert.equal(next.currentStreak, 1);
  assert.equal(next.longestStreak, 9);
  assert.equal(next.freezesUsed, 2);
  assert.equal(next.broken, true);
});
test('read projection never mutates or spends freezes', () => {
  const current = { ...state, freezesAvailable: 1 };
  assert.deepEqual(projectStreak(current, '2026-09-11'), { currentStreak: 5, broken: false });
  assert.deepEqual(projectStreak(current, '2026-09-12'), { currentStreak: 0, broken: true });
  assert.equal(current.freezesAvailable, 1);
});

test('day key is built from parts, not from a locale-specific string shape', () => {
  // `format('en-CA')` chỉ tình cờ trả ISO; thứ tự trường và dấu phân cách là
  // chi tiết của bản ICU đang chạy, không phải hợp đồng. Formatter giả dưới
  // đây trả đúng các phần mà một ICU khác có thể trả — đảo thứ tự, dấu `/`,
  // thiếu số 0 đứng đầu — và `dayKey` vẫn phải ra `YYYY-MM-DD`.
  const reversed = {
    formatToParts: () => [
      { type: 'day', value: '9' },
      { type: 'literal', value: '/' },
      { type: 'month', value: '3' },
      { type: 'literal', value: '/' },
      { type: 'year', value: '2026' },
    ],
  };
  // Ngày thật (21/7) cố ý khác ngày mà formatter giả trả về (9/3): nếu
  // `dayKey` vẫn tự định dạng thay vì đọc `parts`, khác biệt này lộ ra ngay.
  assert.equal(dayKey(new Date('2026-07-21T05:00:00Z'), 'UTC', reversed), '2026-03-09');
});

test('day key refuses a formatter that cannot supply a full calendar date', () => {
  const partial = { formatToParts: () => [{ type: 'year', value: '2026' }] };
  assert.throws(() => dayKey(new Date(), 'UTC', partial), RangeError);
});
