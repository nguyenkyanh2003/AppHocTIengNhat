import assert from 'node:assert/strict';
import test from 'node:test';

import { createStreakReadService } from '../src/modules/streaks/streak-read.service.js';

const NOW = new Date('2026-09-19T03:00:00.000Z'); // 10:00 giờ Việt Nam.
const TODAY = '2026-09-19';
const USER = 'u1';

/**
 * Repository giả **chỉ có đường đọc**. Không khai báo bất kỳ hàm ghi nào: nếu
 * service đọc lỡ gọi `ensureSummary`/`casSummary`/`insertEvent` thì test nổ
 * ngay với "is not a function" — đó chính là khẳng định "đọc không ghi gì".
 */
const readOnlyRepository = ({
  summary = null,
  events = [],
  days = [],
  legacyImported = false,
  summaries = [],
  eventTotals = [],
  legacyTotals = [],
  migratedUsers = [],
  users = [],
  rankedAbove = 0,
} = {}) => {
  const calls = [];
  return {
    calls,
    async findByUser({ userId }) {
      calls.push(['findByUser', userId]);
      return summary;
    },
    async listEvents({ userId, cursor, limit, withXpOnly }) {
      calls.push(['listEvents', { userId, cursor, limit, withXpOnly }]);
      const start = cursor ? events.findIndex((e) => e._id === cursor.id) + 1 : 0;
      return events.slice(start, start + limit);
    },
    async listDays({ userId, cursor, limit }) {
      calls.push(['listDays', { userId, cursor, limit }]);
      const start = cursor ? days.findIndex((d) => d.day_key === cursor) + 1 : 0;
      return days.slice(start, start + limit);
    },
    async hasLegacyImport({ userId }) {
      calls.push(['hasLegacyImport', userId]);
      return legacyImported;
    },
    async topByTotalXp({ limit }) {
      calls.push(['topByTotalXp', limit]);
      return summaries.slice(0, limit);
    },
    async countRankedAbove(args) {
      calls.push(['countRankedAbove', args]);
      return rankedAbove;
    },
    async sumXpByUserBetween(args) {
      calls.push(['sumXpByUserBetween', args]);
      return eventTotals;
    },
    async usersWithLegacyImport() {
      calls.push(['usersWithLegacyImport']);
      return migratedUsers;
    },
    async sumLegacyXpByUserSince(args) {
      calls.push(['sumLegacyXpByUserSince', args]);
      return legacyTotals;
    },
    async findSummaries({ userIds }) {
      calls.push(['findSummaries', userIds]);
      return summaries.filter((s) => userIds.map(String).includes(String(s.user)));
    },
    async findUsersByIds(ids) {
      calls.push(['findUsersByIds', ids]);
      return users.filter((u) => ids.map(String).includes(String(u._id)));
    },
  };
};

const build = (repository) => createStreakReadService({ repository, clock: () => NOW });

// --- summary ----------------------------------------------------------------

test('summary of a user with no streak yet is all zeros and writes nothing', async () => {
  const repository = readOnlyRepository();
  const view = await build(repository).summary(USER);

  assert.equal(view.current_streak, 0);
  assert.equal(view.longest_streak, 0);
  assert.equal(view.total_xp, 0);
  assert.equal(view.level, 1);
  assert.equal(view.xp_to_next_level, 100);
  assert.equal(view.last_activity_day, null);
  assert.equal(view.studied_today, false);
  assert.deepEqual(view.activity_dates, []);
});

test('summary derives level from total_xp instead of trusting the stored level', async () => {
  // Đường ghi mới chỉ cộng `total_xp`; `level` lưu trong document là của cơ chế
  // cũ và sẽ đứng yên. Đọc nó ra là hiển thị level sai.
  const repository = readOnlyRepository({
    summary: { _id: 's1', user: USER, total_xp: 253, level: 1, current_streak: 2, longest_streak: 4, last_activity_day: TODAY },
  });
  const view = await build(repository).summary(USER);

  assert.equal(view.level, 3);
  assert.equal(view.xp_to_next_level, 47);
  assert.equal(view.longest_streak, 4);
});

test('summary projects a lapsed streak to 0 without saving anything', async () => {
  const repository = readOnlyRepository({
    summary: { user: USER, total_xp: 10, current_streak: 5, longest_streak: 5, last_activity_day: '2026-09-10' },
  });
  const view = await build(repository).summary(USER);

  assert.equal(view.current_streak, 0);
  assert.equal(view.longest_streak, 5);
  assert.equal(view.studied_today, false);
});

test('summary keeps a streak that is still alive and flags studying today', async () => {
  const repository = readOnlyRepository({
    summary: { user: USER, total_xp: 10, current_streak: 3, longest_streak: 3, last_activity_day: TODAY },
  });
  const view = await build(repository).summary(USER);

  assert.equal(view.current_streak, 3);
  assert.equal(view.studied_today, true);
  // Client cũ parse `last_activity_date`; ngày học mới được đưa ra dạng ngày.
  assert.equal(view.last_activity_date, TODAY);
});

test('summary activity dates merge studied days with legacy dates, newest days last', async () => {
  const legacy = new Date('2026-09-01T02:00:00.000Z');
  const repository = readOnlyRepository({
    summary: { user: USER, total_xp: 0, activity_dates: [legacy] },
    days: [
      { day_key: '2026-09-19', status: 'studied' },
      { day_key: '2026-09-18', status: 'studied' },
      { day_key: '2026-09-17', status: 'frozen' },
    ],
  });
  const view = await build(repository).summary(USER);

  // Ngày băng không phải ngày học. Ngày cũ giữ nguyên như client đã quen đọc.
  assert.deepEqual(view.activity_dates, [legacy.toISOString(), '2026-09-18', '2026-09-19']);
});

test('summary pages through every calendar page, not just the first', async () => {
  const days = Array.from({ length: 450 }, (_, i) => ({
    day_key: `2025-${String((i % 12) + 1).padStart(2, '0')}-${String((i % 28) + 1).padStart(2, '0')}#${i}`,
    status: 'studied',
  }));
  const repository = readOnlyRepository({ summary: { user: USER, total_xp: 0 }, days });
  const view = await build(repository).summary(USER);

  assert.equal(view.activity_dates.length, 450);
});

test('activityDates exposes the same merged days that dashboards draw', async () => {
  const repository = readOnlyRepository({
    summary: { user: USER },
    days: [{ day_key: '2026-09-18', status: 'studied' }, { day_key: '2026-09-17', status: 'frozen' }],
  });
  assert.deepEqual(await build(repository).activityDates(USER), ['2026-09-18']);
});

// --- xpHistory --------------------------------------------------------------

test('xp history reads events newest first with readable reasons', async () => {
  const repository = readOnlyRepository({
    events: [
      { _id: 'e2', type: 'lesson.complete', xp_delta: 20, occurred_at: new Date('2026-09-19T02:00:00Z') },
      { _id: 'e1', type: 'exercise.submit', xp_delta: 10, occurred_at: new Date('2026-09-18T02:00:00Z') },
    ],
  });
  const history = await build(repository).xpHistory(USER);

  assert.deepEqual(history, [
    { amount: 20, reason: 'Hoàn thành bài học', earned_at: new Date('2026-09-19T02:00:00Z') },
    { amount: 10, reason: 'Làm bài tập', earned_at: new Date('2026-09-18T02:00:00Z') },
  ]);
  const [, args] = repository.calls.find(([name]) => name === 'listEvents');
  assert.equal(args.withXpOnly, true);
});

test('xp history keeps legacy entries until the migration has copied them', async () => {
  const repository = readOnlyRepository({
    summary: {
      user: USER,
      xp_history: [{ amount: 10, reason: 'Daily login', earned_at: new Date('2026-09-15T01:00:00Z') }],
    },
    events: [
      { _id: 'e1', type: 'srs.review', xp_delta: 2, occurred_at: new Date('2026-09-19T01:00:00Z') },
    ],
  });
  const history = await build(repository).xpHistory(USER);

  assert.deepEqual(
    history.map((entry) => entry.reason),
    ['Ôn tập SRS', 'Daily login'],
  );
});

test('xp history drops legacy entries once they exist as imported events', async () => {
  // Sau migration, lịch sử cũ đã nằm trong nhật ký dưới dạng event; đọc thêm
  // mảng cũ nữa là hiện mỗi dòng hai lần.
  const repository = readOnlyRepository({
    legacyImported: true,
    summary: {
      user: USER,
      xp_history: [{ amount: 10, reason: 'Daily login', earned_at: new Date('2026-09-15T01:00:00Z') }],
    },
  });
  assert.deepEqual(await build(repository).xpHistory(USER), []);
});

test('xp history returns everything for export, across many pages', async () => {
  const events = Array.from({ length: 450 }, (_, i) => ({
    _id: `e${i}`,
    type: 'srs.review',
    xp_delta: 2,
    occurred_at: new Date(Date.UTC(2026, 0, 1) + (450 - i) * 60_000),
  }));
  const history = await build(readOnlyRepository({ events })).xpHistory(USER);
  assert.equal(history.length, 450);
});

// --- leaderboard ------------------------------------------------------------

test('all-time leaderboard ranks by total XP and derives level', async () => {
  const repository = readOnlyRepository({
    summary: { _id: 's1', user: USER, total_xp: 30, current_streak: 0 },
    summaries: [
      { user: 'u2', total_xp: 250, current_streak: 1, longest_streak: 4, last_activity_day: TODAY, level: 1 },
      { user: USER, total_xp: 30, current_streak: 0, longest_streak: 1 },
    ],
    users: [{ _id: 'u2', TenDangNhap: 'hai' }, { _id: USER, TenDangNhap: 'mot' }],
    rankedAbove: 1,
  });
  const board = await build(repository).leaderboard({ userId: USER, period: 'all', limit: 50 });

  assert.equal(board.user_rank, 2);
  assert.equal(board.leaderboard[0].rank, 1);
  assert.equal(board.leaderboard[0].user.TenDangNhap, 'hai');
  assert.equal(board.leaderboard[0].level, 3);
  assert.equal(board.leaderboard[0].current_streak, 1);
  // Rank của mình dùng đúng thứ tự của danh sách: XP rồi tới chuỗi.
  const [, rankArgs] = repository.calls.find(([name]) => name === 'countRankedAbove');
  assert.deepEqual(rankArgs, { totalXp: 30, currentStreak: 0, id: 's1' });
});

test('weekly leaderboard sums XP over the last 7 Vietnamese days including today', async () => {
  const repository = readOnlyRepository({
    summaries: [
      { user: 'u2', total_xp: 500, current_streak: 0 },
      { user: USER, total_xp: 40, current_streak: 0 },
    ],
    eventTotals: [
      { _id: USER, total: 40 },
      { _id: 'u2', total: 12 },
    ],
    users: [{ _id: 'u2' }, { _id: USER }],
  });
  const board = await build(repository).leaderboard({ userId: USER, period: 'week', limit: 50 });

  const [, range] = repository.calls.find(([name]) => name === 'sumXpByUserBetween');
  assert.deepEqual(range, { fromDay: '2026-09-13', toDay: TODAY });
  // Kỳ tuần xếp theo XP trong kỳ, không theo tổng XP trọn đời.
  assert.deepEqual(board.leaderboard.map((row) => [String(row.user._id), row.period_xp]), [
    [USER, 40],
    ['u2', 12],
  ]);
  assert.equal(board.user_rank, 1);
});

test('monthly leaderboard adds legacy XP only for users not yet migrated', async () => {
  const repository = readOnlyRepository({
    summaries: [{ user: 'u2', total_xp: 100 }, { user: 'u3', total_xp: 100 }],
    eventTotals: [{ _id: 'u2', total: 5 }],
    migratedUsers: ['u3'],
    legacyTotals: [{ _id: 'u2', total: 20 }],
    users: [{ _id: 'u2' }, { _id: 'u3' }],
  });
  const board = await build(repository).leaderboard({ userId: USER, period: 'month', limit: 50 });

  const [, range] = repository.calls.find(([name]) => name === 'sumXpByUserBetween');
  assert.equal(range.fromDay, '2026-08-21');
  const [, legacyArgs] = repository.calls.find(([name]) => name === 'sumLegacyXpByUserSince');
  assert.deepEqual(legacyArgs.excludeUserIds, ['u3']);
  assert.equal(legacyArgs.since.toISOString(), '2026-08-20T17:00:00.000Z');

  assert.deepEqual(board.leaderboard.map((row) => row.period_xp), [25]);
  // Người không có XP trong kỳ thì không có hạng trong kỳ đó.
  assert.equal(board.user_rank, null);
});

test('period leaderboard honours the limit but ranks against everyone', async () => {
  const repository = readOnlyRepository({
    summaries: [{ user: 'a' }, { user: 'b' }, { user: USER }],
    eventTotals: [
      { _id: 'a', total: 30 },
      { _id: 'b', total: 20 },
      { _id: USER, total: 10 },
    ],
    users: [{ _id: 'a' }, { _id: 'b' }, { _id: USER }],
  });
  const board = await build(repository).leaderboard({ userId: USER, period: 'week', limit: 2 });

  assert.equal(board.leaderboard.length, 2);
  assert.equal(board.user_rank, 3);
});
