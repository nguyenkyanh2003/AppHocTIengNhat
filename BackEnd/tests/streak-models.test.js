import assert from 'node:assert/strict';
import test from 'node:test';
import StreakDay from '../model/StreakDay.js';
import UserStreak from '../model/UserStreak.js';

const day = StreakDay.schema;
const summary = UserStreak.schema;
const enumOf = (schema, field) => schema.path(field).options.enum;

test('a study day records what actually happened on it', () => {
  for (const field of [
    'user',
    'day_key',
    'status',
    'origin',
    'direct_xp',
    'review_count',
    'correct_self_reports',
    'wrong_self_reports',
  ]) {
    assert.ok(day.path(field), `StreakDay thiếu ${field}`);
  }
});

test('a legacy day is a third status, not a studied day we cannot prove', () => {
  // Ngày cũ dựng lại từ `activity_dates` không chứng minh được là có học —
  // gọi nó là `studied` là bịa dữ liệu, bỏ nó đi là mất chuỗi của người dùng.
  assert.deepEqual(enumOf(day, 'status').slice().sort(), ['frozen', 'legacy', 'studied']);
  assert.ok(enumOf(day, 'origin').includes('activity'));
  assert.ok(enumOf(day, 'origin').includes('legacy_unverified'));
});

test('day counters default to zero so $inc never meets undefined', () => {
  for (const field of ['direct_xp', 'review_count', 'correct_self_reports', 'wrong_self_reports']) {
    assert.equal(day.path(field).defaultValue, 0, `${field} phải mặc định 0`);
  }
});

test('one day per user stays a unique constraint', () => {
  const index = day.indexes().find(([keys]) => keys.user === 1 && keys.day_key === 1);
  assert.ok(index);
  assert.equal(index[1].unique, true);
});

test('the summary carries the fields the new write path needs', () => {
  for (const field of [
    'total_active_days',
    'legacy_day_count',
    'tracking_started_day',
    'revision',
    'policy_version',
  ]) {
    assert.ok(summary.path(field), `UserStreak thiếu ${field}`);
  }
  assert.equal(summary.path('revision').defaultValue, 0);
  assert.equal(summary.path('total_active_days').defaultValue, 0);
  assert.equal(summary.path('legacy_day_count').defaultValue, 0);
});

test('legacy arrays stay until migration has actually run', () => {
  // Bỏ ba mảng này trước Bước 4 là xoá mất nguồn duy nhất để dựng lại chuỗi
  // của người dùng cũ. Chúng chỉ được gỡ sau khi §4.1 bước 8 kiểm đạt.
  for (const field of ['xp_history', 'activity_dates', 'reward_keys']) {
    assert.ok(summary.path(field), `UserStreak không được bỏ ${field} ở bước này`);
  }
});
