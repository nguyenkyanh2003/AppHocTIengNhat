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
    async listEvents({ userId, cursor, limit, withXpOnly, asOf }) {
      calls.push(['listEvents', { userId, cursor, limit, withXpOnly, asOf }]);
      const visible = asOf ? events.filter((e) => new Date(e.occurred_at) <= asOf) : events;
      const start = cursor ? visible.findIndex((e) => e._id === cursor.id) + 1 : 0;
      return visible.slice(start, start + limit);
    },
    async listDays({ userId, from, to, cursor, limit }) {
      calls.push(['listDays', { userId, from, to, cursor, limit }]);
      const inRange = days.filter((d) => (!from || d.day_key >= from) && (!to || d.day_key <= to));
      const start = cursor ? inRange.findIndex((d) => d.day_key === cursor) + 1 : 0;
      return inRange.slice(start, start + limit);
    },
    async findFirstDayKey({ userId }) {
      calls.push(['findFirstDayKey', userId]);
      return days.length > 0 ? days[days.length - 1].day_key : null;
    },
    async findDay({ userId, dayKey }) {
      calls.push(['findDay', { userId, dayKey }]);
      return days.find((day) => day.day_key === dayKey) ?? null;
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

/** Cài đặt giả chỉ có đường đọc, cùng lý do với repository ở trên. */
const settingsRepositoryWith = (settings = null) => ({
  async findByUser() {
    return settings;
  },
});

const build = (repository, settings = null) =>
  createStreakReadService({
    repository,
    settingsRepository: settingsRepositoryWith(settings),
    clock: () => NOW,
  });

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

// --- xpHistoryPage ------------------------------------------------------------

const oid = (n) => n.toString(16).padStart(24, '0');

const xpEvents = (count) =>
  Array.from({ length: count }, (_, i) => ({
    _id: oid(count - i),
    type: 'srs.review',
    xp_delta: 2,
    occurred_at: new Date(NOW.getTime() - (i + 1) * 60_000),
  }));

test('xp history page returns one page and a cursor, then the rest', async () => {
  const service = build(readOnlyRepository({ events: xpEvents(5) }));

  const first = await service.xpHistoryPage(USER, { limit: 3 });
  assert.equal(first.data.length, 3);
  assert.equal(first.as_of, NOW.toISOString());
  assert.ok(first.next_cursor);
  assert.deepEqual(first.data[0], {
    amount: 2,
    reason: 'Ôn tập SRS',
    earned_at: xpEvents(5)[0].occurred_at,
    source: 'activity',
  });

  const second = await service.xpHistoryPage(USER, { limit: 3, cursor: first.next_cursor });
  assert.equal(second.data.length, 2);
  assert.equal(second.next_cursor, null);
  // Mọi trang của một lần đọc nhìn cùng một mốc thời gian.
  assert.equal(second.as_of, first.as_of);
});

test('xp history page does not hand out a cursor to an empty last page', async () => {
  const page = await build(readOnlyRepository({ events: xpEvents(3) })).xpHistoryPage(USER, { limit: 3 });
  assert.equal(page.data.length, 3);
  assert.equal(page.next_cursor, null);
});

test('xp history page continues into legacy entries after the journal, marked as legacy', async () => {
  const repository = readOnlyRepository({
    events: xpEvents(2),
    summary: {
      user: USER,
      xp_history: [
        { amount: 10, reason: 'Daily login', earned_at: new Date('2026-09-10T01:00:00Z') },
        { amount: 5, reason: 'Old lesson', earned_at: new Date('2026-09-12T01:00:00Z') },
      ],
    },
  });
  const service = build(repository);

  const first = await service.xpHistoryPage(USER, { limit: 3 });
  assert.deepEqual(first.data.map((row) => row.source), ['activity', 'activity', 'legacy']);
  assert.equal(first.data[2].reason, 'Old lesson');

  const second = await service.xpHistoryPage(USER, { limit: 3, cursor: first.next_cursor });
  assert.deepEqual(second.data.map((row) => row.reason), ['Daily login']);
  assert.equal(second.next_cursor, null);
});

test('xp history page marks imported legacy events and skips the old array', async () => {
  const repository = readOnlyRepository({
    legacyImported: true,
    events: [{ _id: oid(1), type: 'legacy.xp', reason: 'Daily login', xp_delta: 10, occurred_at: new Date('2026-09-10T01:00:00Z') }],
    summary: { user: USER, xp_history: [{ amount: 10, reason: 'Daily login', earned_at: new Date('2026-09-10T01:00:00Z') }] },
  });
  const page = await build(repository).xpHistoryPage(USER, { limit: 20 });

  assert.deepEqual(page.data, [
    { amount: 10, reason: 'Daily login', earned_at: new Date('2026-09-10T01:00:00Z'), source: 'legacy' },
  ]);
});

test('xp history page rejects a cursor that is malformed or belongs to someone else', async () => {
  const service = build(readOnlyRepository({ events: xpEvents(5) }));
  const { next_cursor: cursor } = await service.xpHistoryPage(USER, { limit: 2 });

  await assert.rejects(() => service.xpHistoryPage('someone-else', { limit: 2, cursor }), {
    code: 'INVALID_CURSOR',
    status: 400,
  });
  await assert.rejects(() => service.xpHistoryPage(USER, { limit: 2, cursor: 'not-a-cursor' }), {
    code: 'INVALID_CURSOR',
  });
});

// --- days -------------------------------------------------------------------

const calendar = [
  { day_key: '2026-09-19', status: 'studied', direct_xp: 4, review_count: 2, correct_self_reports: 1, wrong_self_reports: 1 },
  { day_key: '2026-09-18', status: 'frozen' },
  { day_key: '2026-09-15', status: 'legacy', origin: 'legacy_unverified' },
  { day_key: '2025-01-01', status: 'studied' },
];

test('days defaults to the 366 days ending today and fills missing counters', async () => {
  const repository = readOnlyRepository({ days: calendar });
  const result = await build(repository).days(USER, { limit: 100 });

  assert.equal(result.to, TODAY);
  assert.equal(result.from, '2025-09-19');
  assert.equal(result.next_cursor, null);
  assert.deepEqual(result.data.map((day) => day.day_key), ['2026-09-19', '2026-09-18', '2026-09-15']);
  assert.deepEqual(result.data[1], {
    day_key: '2026-09-18',
    status: 'frozen',
    origin: 'activity',
    direct_xp: 0,
    review_count: 0,
    correct_self_reports: 0,
    wrong_self_reports: 0,
  });
});

test('days pages with a day-key cursor', async () => {
  const service = build(readOnlyRepository({ days: calendar }));

  const first = await service.days(USER, { from: '2026-01-01', to: TODAY, limit: 2 });
  assert.equal(first.next_cursor, '2026-09-18');

  const second = await service.days(USER, { from: '2026-01-01', to: TODAY, limit: 2, cursor: first.next_cursor });
  assert.deepEqual(second.data.map((day) => day.day_key), ['2026-09-15']);
  assert.equal(second.next_cursor, null);
});

test('days rejects a reversed range or one longer than a leap year', async () => {
  const service = build(readOnlyRepository());

  await assert.rejects(() => service.days(USER, { from: '2026-09-19', to: '2026-09-18', limit: 10 }), {
    code: 'INVALID_DAY_RANGE',
  });
  await assert.rejects(() => service.days(USER, { from: '2025-09-18', to: '2026-09-19', limit: 10 }), {
    code: 'INVALID_DAY_RANGE',
  });
});

test('summary exposes the earliest calendar day for export', async () => {
  const view = await build(readOnlyRepository({ summary: { user: USER }, days: calendar })).summary(USER);
  assert.equal(view.first_day, '2025-01-01');
});

// --- Phần B: mục tiêu ngày và dự báo băng trong tóm tắt ---------------------------

test('summary reports today\'s goal progress from studied XP only', async () => {
  const repository = readOnlyRepository({
    summary: { user: USER, total_xp: 300, current_streak: 2, last_activity_day: TODAY },
    days: [{ day_key: TODAY, status: 'studied', direct_xp: 14 }],
  });
  const view = await build(repository).summary(USER);

  assert.deepEqual(view.daily_goal, {
    target_xp: 20,
    today_xp: 14,
    reached: false,
    next_target_xp: null,
    next_target_from: null,
  });
  // Tiến độ mục tiêu là XP học hôm nay, không phải tổng XP trọn đời.
  assert.notEqual(view.daily_goal.today_xp, view.total_xp);
});

test('summary shows a reached goal and a goal change waiting for tomorrow', async () => {
  const repository = readOnlyRepository({
    summary: { user: USER, total_xp: 40, current_streak: 1, last_activity_day: TODAY },
    days: [{ day_key: TODAY, status: 'studied', direct_xp: 22 }],
  });
  const settings = { daily_goal_xp: 30, previous_goal_xp: 20, goal_effective_from: '2026-09-20' };
  const view = await build(repository, settings).summary(USER);

  assert.equal(view.daily_goal.target_xp, 20);
  assert.equal(view.daily_goal.reached, true);
  assert.equal(view.daily_goal.next_target_xp, 30);
  assert.equal(view.daily_goal.next_target_from, '2026-09-20');
});

test('a user who has not studied today has 0 XP towards the goal', async () => {
  const view = await build(readOnlyRepository()).summary(USER);
  assert.equal(view.daily_goal.today_xp, 0);
  assert.equal(view.daily_goal.target_xp, 20);
  assert.equal(view.daily_goal.reached, false);
});

test('summary reports the stored inventory and the projected freeze use separately', async () => {
  // Nghỉ 17 và 18, hôm nay 19: đủ hai băng. Kho đã ghi vẫn là 2; sau khi học
  // lại sẽ còn 0. Hai con số khác nhau, không được gộp (spec §5.2).
  const repository = readOnlyRepository({
    summary: {
      user: USER,
      current_streak: 5,
      longest_streak: 5,
      last_activity_day: '2026-09-16',
      freezes_available: 2,
      tracking_started_day: '2026-09-01',
    },
  });
  const view = await build(repository).summary(USER);

  assert.equal(view.current_streak, 5);
  assert.equal(view.freezes_available, 2);
  assert.equal(view.max_freezes, 2);
  assert.equal(view.pending_freezes, 2);
  assert.deepEqual(view.pending_frozen_days, ['2026-09-17', '2026-09-18']);
  assert.equal(view.freezes_after_pending, 0);
  assert.equal(view.tracking_started_day, '2026-09-01');
});

test('a broken streak still lists the freezes that will be spent', async () => {
  const repository = readOnlyRepository({
    summary: { user: USER, current_streak: 5, last_activity_day: '2026-09-15', freezes_available: 1 },
  });
  const view = await build(repository).summary(USER);

  assert.equal(view.current_streak, 0);
  assert.deepEqual(view.pending_frozen_days, ['2026-09-16']);
  assert.equal(view.freezes_after_pending, 0);
});

test('a user with no streak yet has an empty inventory and nothing pending', async () => {
  const view = await build(readOnlyRepository()).summary(USER);
  assert.equal(view.freezes_available, 0);
  assert.equal(view.pending_freezes, 0);
  assert.deepEqual(view.pending_frozen_days, []);
  assert.equal(view.tracking_started_day, null);
});
