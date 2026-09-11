import assert from 'node:assert/strict';
import test from 'node:test';

import { createStreakService } from '../src/modules/streaks/streak.service.js';
import { POLICY_VERSION } from '../src/modules/streaks/streak-policy.js';

const NOW = new Date('2026-09-11T03:00:00.000Z'); // 10:00 giờ Việt Nam.
const TODAY = '2026-09-11';

/**
 * Repository giả mô phỏng đúng hai thứ mà cả thiết kế dựa vào: unique index
 * trên `(user, event_key)` và CAS trên `revision`.
 *
 * Mô phỏng chứ không chỉ ghi lại lời gọi — nếu chỉ ghi lại, test sẽ khẳng
 * định được "có gọi insertEvent" nhưng không khẳng định được điều thật sự
 * quan trọng: gửi lại cùng một khoá thì **không** có gì được cộng thêm.
 */
const fakeRepository = ({ summary = {}, failCasTimes = 0 } = {}) => {
  const state = {
    revision: 0,
    current_streak: 0,
    longest_streak: 0,
    last_activity_day: null,
    total_xp: 0,
    total_active_days: 0,
    freezes_available: 0,
    ...summary,
  };
  const eventKeys = new Set();
  const calls = [];
  let casFailuresLeft = failCasTimes;

  return {
    state,
    calls,
    events: [],
    days: [],
    async ensureSummary({ userId, session }) {
      calls.push(['ensureSummary', { userId, session }]);
      return { ...state };
    },
    async findByUser({ userId, session }) {
      calls.push(['findByUser', { userId, session }]);
      return { ...state };
    },
    async insertEvent(args) {
      calls.push(['insertEvent', args]);
      if (eventKeys.has(args.eventKey)) return null;
      eventKeys.add(args.eventKey);
      const saved = { _id: `e${eventKeys.size}`, ...args };
      this.events.push(saved);
      return saved;
    },
    async casSummary({ userId, expectedRevision, patch, inc, session }) {
      calls.push(['casSummary', { userId, expectedRevision, patch, inc, session }]);
      if (casFailuresLeft > 0) {
        casFailuresLeft -= 1;
        // Một request khác vừa ghi: revision tiến lên, CAS này thua.
        state.revision += 1;
        return null;
      }
      if (expectedRevision !== state.revision) return null;
      Object.assign(state, patch);
      for (const [field, amount] of Object.entries(inc ?? {})) {
        state[field] = (state[field] ?? 0) + amount;
      }
      state.revision += 1;
      return { ...state };
    },
    async upsertDay(args) {
      calls.push(['upsertDay', args]);
      this.days.push(args);
      return { matchedCount: 1 };
    },
  };
};

const namesOf = (repository) => repository.calls.map(([name]) => name);
const callsTo = (repository, name) =>
  repository.calls.filter(([called]) => called === name).map(([, args]) => args);

const activity = (over = {}) => ({
  userId: 'u1',
  type: 'lesson.complete',
  sourceId: 'l1',
  occurrenceKey: 'lesson-complete:l1',
  ...over,
});

// --- chữ ký và xác thực đầu vào -------------------------------------------

test('recordActivity takes the activity and its transaction context separately', async () => {
  const repository = fakeRepository();
  const service = createStreakService({ repository });

  const result = await service.recordActivity(activity(), { session: 'sess', now: NOW });

  assert.equal(result.xpAwarded, 20);
  assert.equal(result.currentStreak, 1);
  assert.equal(result.isNewDay, true);
  assert.equal(result.duplicate, false);
});

test('an activity without an occurrence key is refused, not given an invented one', async () => {
  // Bịa khoá từ `type:sourceId` là đúng cái làm cho `srs.review` không thể
  // chống trùng: một thẻ được ôn lại nhiều lần, nên ID thẻ không định danh
  // được lượt ôn. Caller là service nghiệp vụ — nó biết khoá thật.
  const service = createStreakService({ repository: fakeRepository() });
  await assert.rejects(
    service.recordActivity(activity({ occurrenceKey: undefined }), { now: NOW }),
    (error) => error.status === 400 && error.code === 'MISSING_OCCURRENCE_KEY',
  );
});

test('an unknown activity type is a 400 before anything is written', async () => {
  const repository = fakeRepository();
  const service = createStreakService({ repository });
  await assert.rejects(
    service.recordActivity(activity({ type: 'lesson.finish' }), { now: NOW }),
    (error) => error.status === 400,
  );
  assert.equal(repository.events.length, 0);
  assert.equal(namesOf(repository).includes('casSummary'), false);
});

// --- chống trùng -----------------------------------------------------------

test('replaying the same occurrence key changes nothing at all', async () => {
  const repository = fakeRepository();
  const service = createStreakService({ repository });

  const first = await service.recordActivity(activity(), { now: NOW });
  const before = { ...repository.state };
  repository.calls.length = 0;

  const second = await service.recordActivity(activity(), { now: NOW });

  assert.equal(first.xpAwarded, 20);
  assert.equal(second.xpAwarded, 0);
  assert.equal(second.duplicate, true);
  // Trạng thái phải đứng yên tuyệt đối — kể cả `revision`.
  assert.deepEqual(repository.state, before);
  assert.equal(namesOf(repository).includes('casSummary'), false);
  assert.equal(namesOf(repository).includes('upsertDay'), false);
});

test('a duplicate still reports the streak the user actually has', async () => {
  const repository = fakeRepository();
  const service = createStreakService({ repository });
  await service.recordActivity(activity(), { now: NOW });

  const second = await service.recordActivity(activity(), { now: NOW });
  assert.equal(second.currentStreak, 1);
});

test('two different activities on one day both earn XP but make one study day', async () => {
  const repository = fakeRepository();
  const service = createStreakService({ repository });

  await service.recordActivity(activity(), { now: NOW });
  await service.recordActivity(
    activity({
      type: 'exercise.submit',
      sourceId: 'ex1',
      occurrenceKey: 'exercise:att-1',
      context: { outcome: { passed: true } },
    }),
    { now: NOW },
  );

  // 20 (hoàn thành bài) + 10 (bài tập đạt) — không bên nào đè mất bên nào.
  assert.equal(repository.state.total_xp, 30);
  assert.equal(repository.state.current_streak, 1);
  assert.equal(repository.state.total_active_days, 1);
  assert.equal(repository.days.length, 2);
  assert.ok(repository.days.every((day) => day.dayKey === TODAY));
});

test('the duplicate guard is the event key alone, never a list read from the summary', async () => {
  const repository = fakeRepository();
  const service = createStreakService({ repository });
  await service.recordActivity(activity(), { now: NOW });
  repository.calls.length = 0;
  await service.recordActivity(activity(), { now: NOW });

  // Không đọc lại tóm tắt để tra một mảng khoá: khe hở giữa lúc đọc và lúc
  // ghi chính là lỗi mà thiết kế này loại bỏ.
  const insertIndex = namesOf(repository).indexOf('insertEvent');
  assert.ok(insertIndex >= 0);
  assert.equal(namesOf(repository).slice(0, insertIndex).includes('findByUser'), false);
});

// --- thứ tự ghi ------------------------------------------------------------

test('the event is written before the summary is touched', async () => {
  const repository = fakeRepository();
  const service = createStreakService({ repository });
  await service.recordActivity(activity(), { now: NOW });

  const order = namesOf(repository);
  assert.ok(order.indexOf('insertEvent') < order.indexOf('casSummary'), order.join(' → '));
  assert.ok(order.indexOf('insertEvent') < order.indexOf('upsertDay'), order.join(' → '));
});

test('the event carries the day, the policy stamp and the graded XP', async () => {
  const repository = fakeRepository();
  const service = createStreakService({ repository });
  await service.recordActivity(
    activity({
      type: 'exercise.submit',
      sourceId: 'ex1',
      occurrenceKey: 'exercise:att-1',
      context: { outcome: { passed: false } },
    }),
    { now: NOW },
  );

  const [event] = repository.events;
  assert.equal(event.eventKey, 'exercise:att-1');
  assert.equal(event.dayKey, TODAY);
  assert.equal(event.xpDelta, 5);
  assert.equal(event.countsAsStudy, true);
  assert.equal(event.policyVersion, POLICY_VERSION);
  assert.equal(event.occurredAt, NOW);
});

test('a receipt from the caller is stored on the event for retry reads', async () => {
  const repository = fakeRepository();
  const service = createStreakService({ repository });
  await service.recordActivity(
    activity({
      type: 'jlpt.submit',
      sourceId: 'exam1',
      occurrenceKey: 'jlpt:att-9',
      context: { receipt: { score: 88 } },
    }),
    { now: NOW },
  );
  assert.deepEqual(repository.events[0].receipt, { score: 88 });
});

test('every repository call carries the session it was handed', async () => {
  const repository = fakeRepository();
  const service = createStreakService({ repository });
  await service.recordActivity(activity(), { session: 'sess', now: NOW });

  for (const [name, args] of repository.calls) {
    assert.equal(args.session, 'sess', `${name} phải chạy trong cùng transaction`);
  }
});

// --- cạnh tranh CAS --------------------------------------------------------

test('losing the revision race retries instead of dropping the event', async () => {
  // Event đã nằm trong DB rồi; bỏ cuộc ở đây nghĩa là XP của nó biến mất
  // vĩnh viễn và lần gửi lại sau sẽ bị chặn bởi chính khoá đó.
  const repository = fakeRepository({ failCasTimes: 2 });
  const service = createStreakService({ repository });

  const result = await service.recordActivity(activity(), { now: NOW });

  assert.equal(result.xpAwarded, 20);
  assert.equal(repository.state.total_xp, 20);
  assert.equal(callsTo(repository, 'casSummary').length, 3);
  assert.equal(repository.events.length, 1, 'không được ghi event lần hai khi thử lại');
});

test('each CAS attempt re-reads the revision instead of reusing a stale one', async () => {
  const repository = fakeRepository({ failCasTimes: 1 });
  const service = createStreakService({ repository });
  await service.recordActivity(activity(), { now: NOW });

  const attempts = callsTo(repository, 'casSummary');
  assert.notEqual(attempts[0].expectedRevision, attempts[1].expectedRevision);
});

test('a summary that never stops moving fails loudly instead of looping forever', async () => {
  const repository = fakeRepository({ failCasTimes: Number.MAX_SAFE_INTEGER });
  const service = createStreakService({ repository });

  await assert.rejects(
    service.recordActivity(activity(), { now: NOW }),
    (error) => error.status === 409 && error.code === 'STREAK_WRITE_CONFLICT',
  );
});

// --- ngày và chuỗi ---------------------------------------------------------

test('a consecutive day extends the streak and counts one more active day', async () => {
  const repository = fakeRepository({
    summary: { current_streak: 5, longest_streak: 9, last_activity_day: '2026-09-10', total_active_days: 5 },
  });
  const service = createStreakService({ repository });

  const result = await service.recordActivity(activity(), { now: NOW });

  assert.equal(result.currentStreak, 6);
  assert.equal(repository.state.longest_streak, 9);
  assert.equal(repository.state.total_active_days, 6);
});

test('a second activity on the same day does not count the day twice', async () => {
  const repository = fakeRepository();
  const service = createStreakService({ repository });
  await service.recordActivity(activity(), { now: NOW });
  await service.recordActivity(
    activity({ type: 'srs.review', sourceId: 'c1', occurrenceKey: 'srs:c1:2026-09-11' }),
    { now: NOW },
  );
  assert.equal(repository.state.total_active_days, 1);
});

test('the first activity ever starts the tracking window', async () => {
  const repository = fakeRepository();
  const service = createStreakService({ repository });
  await service.recordActivity(activity(), { now: NOW });
  assert.equal(repository.state.tracking_started_day, TODAY);
});

test('an existing tracking start is never moved forward', async () => {
  const repository = fakeRepository({
    summary: { current_streak: 5, last_activity_day: '2026-09-10', tracking_started_day: '2026-01-01' },
  });
  const service = createStreakService({ repository });
  await service.recordActivity(activity(), { now: NOW });
  assert.equal(repository.state.tracking_started_day, '2026-01-01');
});

test('the day record gets the counters that belong to the activity', async () => {
  const repository = fakeRepository();
  const service = createStreakService({ repository });
  await service.recordActivity(
    activity({
      type: 'srs.review',
      sourceId: 'c1',
      occurrenceKey: 'srs:c1:2026-09-11',
      context: { outcome: { remembered: true } },
    }),
    { now: NOW },
  );

  const [day] = repository.days;
  assert.equal(day.status, 'studied');
  assert.equal(day.dayKey, TODAY);
  assert.equal(day.incDirectXp, 2);
  assert.equal(day.incReviewCount, 1);
  assert.equal(day.incCorrect, 1);
  assert.equal(day.incWrong, 0);
});

test('a wrong self report is counted as wrong but still earns the review XP', async () => {
  const repository = fakeRepository();
  const service = createStreakService({ repository });
  await service.recordActivity(
    activity({
      type: 'srs.review',
      sourceId: 'c1',
      occurrenceKey: 'srs:c1:2026-09-11',
      context: { outcome: { remembered: false } },
    }),
    { now: NOW },
  );
  const [day] = repository.days;
  assert.equal(day.incCorrect, 0);
  assert.equal(day.incWrong, 1);
  assert.equal(day.incDirectXp, 2);
});

// --- hoạt động 0 XP --------------------------------------------------------

test('logging in is recorded but is not a study day and earns nothing', async () => {
  const repository = fakeRepository();
  const service = createStreakService({ repository });

  const result = await service.recordActivity(
    activity({ type: 'login', sourceId: 'u1', occurrenceKey: 'login:u1:2026-09-11' }),
    { now: NOW },
  );

  assert.equal(result.xpAwarded, 0);
  assert.equal(result.currentStreak, 0, 'đăng nhập không được mở chuỗi');
  assert.equal(repository.state.total_xp, 0);
  assert.equal(repository.state.current_streak, 0);
  assert.equal(repository.state.last_activity_day, null);
  assert.equal(repository.days.length, 0, 'không ghi ngày học cho lần đăng nhập');
});

test('a non-study activity is still journalled so it cannot be replayed', async () => {
  const repository = fakeRepository();
  const service = createStreakService({ repository });
  await service.recordActivity(
    activity({ type: 'login', sourceId: 'u1', occurrenceKey: 'login:u1:2026-09-11' }),
    { now: NOW },
  );
  assert.equal(repository.events.length, 1);
  assert.equal(repository.events[0].countsAsStudy, false);
});

// --- mốc huy hiệu ----------------------------------------------------------

test('crossing a milestone emits exactly one reward event that is not study', async () => {
  const repository = fakeRepository({
    summary: { current_streak: 6, longest_streak: 6, last_activity_day: '2026-09-10' },
  });
  const service = createStreakService({ repository });

  const result = await service.recordActivity(activity(), { now: NOW });

  assert.deepEqual(result.milestonesReached, [7]);
  const reward = repository.events.find((event) => event.type === 'streak.milestone');
  assert.ok(reward, 'phải có event thưởng');
  assert.equal(reward.countsAsStudy, false);
  assert.equal(reward.eventKey, 'streak-milestone:u1:7');
  // Event thưởng không được làm phát sinh thêm ngày học hay thêm event nào.
  assert.equal(repository.days.length, 1);
  assert.equal(repository.events.length, 2);
});

test('a milestone is never awarded twice, even after the streak breaks and rebuilds', async () => {
  const repository = fakeRepository({
    summary: { current_streak: 6, longest_streak: 6, last_activity_day: '2026-09-10' },
  });
  const service = createStreakService({ repository });
  await service.recordActivity(activity(), { now: NOW });

  // Chuỗi đứt rồi leo lại đúng mốc 7 — khoá thưởng đã tồn tại nên không cấp lại.
  Object.assign(repository.state, { current_streak: 6, last_activity_day: '2026-09-11' });
  await service.recordActivity(activity({ occurrenceKey: 'lesson-complete:l2', sourceId: 'l2' }), {
    now: new Date('2026-09-12T03:00:00.000Z'),
  });

  const rewards = repository.events.filter((event) => event.type === 'streak.milestone');
  assert.equal(rewards.length, 1);
});

test('no milestone means no reward event', async () => {
  const repository = fakeRepository();
  const service = createStreakService({ repository });
  const result = await service.recordActivity(activity(), { now: NOW });
  assert.deepEqual(result.milestonesReached, []);
  assert.equal(repository.events.length, 1);
});

// --- đường đọc -------------------------------------------------------------

test('reading the summary never writes, never spends, never rewards', async () => {
  const repository = fakeRepository({
    summary: { current_streak: 5, last_activity_day: '2026-09-05', total_xp: 40 },
  });
  const service = createStreakService({ repository });

  const view = await service.readSummary({ userId: 'u1', now: NOW });

  assert.equal(view.current_streak, 0, 'nghỉ quá lâu thì hiển thị chuỗi đã đứt');
  assert.equal(view.total_xp, 40);
  assert.deepEqual(namesOf(repository), ['findByUser']);
});

test('a user who has never studied reads as all zeroes, not as an error', async () => {
  const repository = fakeRepository();
  repository.findByUser = async () => null;
  const service = createStreakService({ repository });

  const view = await service.readSummary({ userId: 'u1', now: NOW });
  assert.equal(view.current_streak, 0);
  assert.equal(view.total_xp, 0);
});

test('a freeze that protects a gap is actually spent, not reused forever', async () => {
  // Băng thuộc Phần B nên chưa có đường nào phát băng. Nhánh này vẫn phải
  // đúng: ghi ngày `frozen` vào lịch mà không trừ kho băng nghĩa là băng vô
  // hạn — chuỗi không bao giờ đứt được nữa.
  const repository = fakeRepository({
    summary: {
      current_streak: 5,
      longest_streak: 5,
      last_activity_day: '2026-09-09',
      freezes_available: 2,
    },
  });
  const service = createStreakService({ repository });

  await service.recordActivity(activity(), { now: NOW });

  assert.equal(repository.state.current_streak, 6);
  assert.equal(repository.state.freezes_available, 1);
  const frozen = repository.days.filter((day) => day.status === 'frozen');
  assert.deepEqual(frozen.map((day) => day.dayKey), ['2026-09-10']);
});
