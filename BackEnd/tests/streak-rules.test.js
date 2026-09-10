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
