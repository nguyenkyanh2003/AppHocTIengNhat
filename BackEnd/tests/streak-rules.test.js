import assert from 'node:assert/strict';
import test from 'node:test';
import { addDays, dayKey, daysBetween, applyActivity, projectStreak } from '../src/modules/streaks/streak-rules.js';

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
  assert.deepEqual(projectStreak(current, '2026-09-11'), {
    currentStreak: 5,
    broken: false,
    pendingFrozenDays: ['2026-09-10'],
    freezesAfter: 0,
  });
  assert.deepEqual(projectStreak(current, '2026-09-12'), {
    currentStreak: 0,
    broken: true,
    pendingFrozenDays: ['2026-09-10'],
    freezesAfter: 0,
  });
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

// --- Phần B: dự báo băng trên đường đọc ---------------------------------------

test('projection names the missed days freezes would protect, without spending them', () => {
  const current = { currentStreak: 5, lastActivityDay: '2026-09-10', freezesAvailable: 2 };
  // Nghỉ 11 và 12, hôm nay 13: đủ hai băng, chuỗi vẫn còn.
  assert.deepEqual(projectStreak(current, '2026-09-13'), {
    currentStreak: 5,
    broken: false,
    pendingFrozenDays: ['2026-09-11', '2026-09-12'],
    freezesAfter: 0,
  });
  assert.equal(current.freezesAvailable, 2);
});

test('with too few freezes the projection still lists the days they will cover', () => {
  // Spec §5.2: thiếu băng vẫn tiêu số đã bảo vệ các ngày đầu. Màn hình phải
  // báo trước điều đó, không được hứa là chuỗi còn.
  const current = { currentStreak: 5, lastActivityDay: '2026-09-10', freezesAvailable: 2 };
  assert.deepEqual(projectStreak(current, '2026-09-14'), {
    currentStreak: 0,
    broken: true,
    pendingFrozenDays: ['2026-09-11', '2026-09-12'],
    freezesAfter: 0,
  });
});

test('an unbroken or empty streak has nothing pending', () => {
  assert.deepEqual(
    projectStreak({ currentStreak: 3, lastActivityDay: '2026-09-12', freezesAvailable: 1 }, '2026-09-13'),
    { currentStreak: 3, broken: false, pendingFrozenDays: [], freezesAfter: 1 },
  );
  assert.deepEqual(projectStreak({}, '2026-09-13'), {
    currentStreak: 0,
    broken: false,
    pendingFrozenDays: [],
    freezesAfter: 0,
  });
  // Hôm nay chưa kết thúc nên không phải ngày nghỉ.
  assert.deepEqual(
    projectStreak({ currentStreak: 3, lastActivityDay: '2026-09-13', freezesAvailable: 2 }, '2026-09-13'),
    { currentStreak: 3, broken: false, pendingFrozenDays: [], freezesAfter: 2 },
  );
});

test('the projection matches exactly what applyActivity will spend', () => {
  // Đường đọc và đường ghi phải kể cùng một câu chuyện: ngày màn hình báo
  // "băng sẽ che" phải đúng là ngày được ghi `frozen` khi người học quay lại.
  for (const freezesAvailable of [0, 1, 2]) {
    for (const gap of [1, 2, 3, 4, 10]) {
      const current = { currentStreak: 4, longestStreak: 4, lastActivityDay: '2026-09-10', freezesAvailable };
      const today = addDays('2026-09-10', gap);
      const view = projectStreak(current, today);
      const next = applyActivity(current, today);

      assert.deepEqual(view.pendingFrozenDays, next.frozenDays, `gap ${gap}, băng ${freezesAvailable}`);
      assert.equal(view.freezesAfter, freezesAvailable - next.freezesUsed);
      assert.equal(view.broken, next.broken);
    }
  }
});
