import assert from 'node:assert/strict';
import test from 'node:test';

import { createSrsService } from '../src/modules/srs/srs.service.js';

const DAY = 24 * 60 * 60 * 1000;
const NOW = new Date('2026-09-20T03:00:00.000Z');
const USER = 'u1';
const OTHER_USER = 'u2';
const TYPE = 'Vocabulary';

const card = (overrides = {}) => ({
  _id: 'p1',
  user: USER,
  item_id: 'v1',
  item_type: TYPE,
  box: 1,
  streak: 0,
  next_review: new Date(NOW.getTime() - DAY),
  ...overrides,
});

const clone = (value) => (value ? structuredClone(value) : value);

/**
 * Repository trong bộ nhớ mô phỏng đúng thứ service dựa vào: lọc theo user và
 * CAS so trạng thái đã đọc. Chỉ ghi lại lời gọi thì không kiểm được điều cốt
 * lõi — hai lượt ghi cùng một kỳ ôn chỉ một bên thắng.
 */
const memoryRepository = ({ rows = [card()], contents = [{ _id: 'v1', word: '学生' }] } = {}) => {
  const store = { rows: rows.map(clone) };
  const calls = [];
  const matches = ({ userId, itemId, itemType }) => (row) =>
    row.user === userId && row.item_id === itemId && row.item_type === itemType;

  return {
    store,
    calls,
    /** Chạy trước lần CAS kế tiếp — mô phỏng một request khác ghi chen vào giữa. */
    beforeNextWrite: null,
    /** Ghi của request khác đã commit riêng: rollback của request này không xoá được. */
    committedElsewhere: [],
    async findProgress(args) {
      calls.push(['findProgress', args]);
      return clone(store.rows.find(matches(args)) ?? null);
    },
    async findDueBatch({ userId, itemType, now, excludeItemIds, limit }) {
      calls.push(['findDueBatch', { userId, itemType, now, excludeItemIds, limit }]);
      return store.rows
        .filter((row) => row.user === userId && row.item_type === itemType && row.next_review <= now)
        .filter((row) => !excludeItemIds.includes(row.item_id))
        .sort((a, b) => a.next_review - b.next_review || a._id.localeCompare(b._id))
        .slice(0, limit)
        .map(clone);
    },
    async countDue({ userId, itemType, now }) {
      return store.rows.filter((r) => r.user === userId && r.item_type === itemType && r.next_review <= now).length;
    },
    async countByBox({ userId, itemType }) {
      const counts = new Map();
      for (const row of store.rows.filter((r) => r.user === userId && r.item_type === itemType)) {
        counts.set(row.box, (counts.get(row.box) ?? 0) + 1);
      }
      return [...counts].map(([box, count]) => ({ _id: box, count }));
    },
    async compareAndSet({ progress, expectedNextReview, dueBy, next, session }) {
      calls.push(['compareAndSet', { expectedNextReview, dueBy, session }]);
      if (this.beforeNextWrite) {
        const intrude = this.beforeNextWrite;
        this.beforeNextWrite = null;
        intrude(store);
        this.committedElsewhere.push(intrude);
      }
      const row = store.rows.find(
        (r) =>
          r._id === progress._id &&
          r.user === progress.user &&
          r.box === progress.box &&
          r.streak === progress.streak &&
          r.next_review.getTime() === new Date(expectedNextReview).getTime() &&
          (!dueBy || r.next_review <= dueBy),
      );
      if (!row) return null;
      Object.assign(row, next);
      return clone(row);
    },
    async deleteProgress(args) {
      const index = store.rows.findIndex(matches(args));
      if (index === -1) return 0;
      store.rows.splice(index, 1);
      return 1;
    },
    async findContentByIds({ ids }) {
      return contents.filter((item) => ids.includes(item._id));
    },
    async contentExists({ itemId }) {
      return contents.some((item) => item._id === itemId);
    },
  };
};

/** Unit of work giả có rollback thật: lỗi trong callback trả store về ảnh chụp trước. */
const rollbackUnitOfWork = (repository) => ({
  runs: 0,
  async run(fn) {
    this.runs += 1;
    const snapshot = clone(repository.store.rows);
    try {
      return await fn({ session: 'session-1' });
    } catch (error) {
      repository.store.rows = snapshot;
      for (const write of repository.committedElsewhere.splice(0)) write(repository.store);
      throw error;
    }
  },
});

/** Cổng ghi hoạt động giả: chống trùng theo khoá như unique index thật. */
const fakeStreak = ({ fail = false } = {}) => {
  const keys = new Set();
  return {
    calls: [],
    async recordActivity(activity, options) {
      this.calls.push([activity, options]);
      if (fail) throw new Error('ghi event thất bại');
      if (keys.has(activity.occurrenceKey)) return { duplicate: true, xpAwarded: 0 };
      keys.add(activity.occurrenceKey);
      return { duplicate: false, xpAwarded: 2 };
    },
  };
};

const build = ({ repository = memoryRepository(), streak = fakeStreak(), now = NOW } = {}) => {
  let current = now;
  const unitOfWork = rollbackUnitOfWork(repository);
  const service = createSrsService({ repository, streak, unitOfWork, clock: () => current });
  return {
    service,
    repository,
    streak,
    unitOfWork,
    setNow: (value) => {
      current = value;
    },
  };
};

const review = (service, overrides = {}) =>
  service.review({
    userId: USER,
    itemId: 'v1',
    itemType: TYPE,
    isCorrect: true,
    expectedNextReview: new Date(NOW.getTime() - DAY),
    ...overrides,
  });

// --- due batch, count, stats ------------------------------------------------

test('due batch hydrates content and flags cards whose content is gone', async () => {
  const repository = memoryRepository({
    rows: [card(), card({ _id: 'p2', item_id: 'v-gone', next_review: new Date(NOW.getTime() - 2 * DAY) })],
  });
  const { service } = build({ repository });

  const batch = await service.dueBatch({ userId: USER, itemType: TYPE, limit: 20 });

  assert.equal(batch.limit, 20);
  assert.deepEqual(
    batch.cards.map((c) => [c.item_id, c.unavailable, c.item?.word ?? null]),
    [
      ['v-gone', true, null],
      ['v1', false, '学生'],
    ],
  );
  assert.equal(batch.cards[1].next_review, new Date(NOW.getTime() - DAY).toISOString());
});

test('due batch never includes cards that are not due or belong to someone else', async () => {
  const repository = memoryRepository({
    rows: [
      card({ next_review: new Date(NOW.getTime() + 1) }),
      card({ _id: 'p2', user: OTHER_USER }),
    ],
  });
  const { service } = build({ repository });

  const batch = await service.dueBatch({ userId: USER, itemType: TYPE, limit: 20 });
  assert.deepEqual(batch.cards, []);
});

test('forty due cards come out as two batches of twenty without skipping any', async () => {
  const rows = Array.from({ length: 40 }, (_, i) =>
    card({
      _id: `p${String(i).padStart(2, '0')}`,
      item_id: `v${i}`,
      next_review: new Date(NOW.getTime() - (i % 4) * DAY),
    }),
  );
  const contents = rows.map((row) => ({ _id: row.item_id, word: row.item_id }));
  const { service } = build({ repository: memoryRepository({ rows, contents }) });

  const first = await service.dueBatch({ userId: USER, itemType: TYPE, limit: 20 });
  // Bỏ qua cả đợt đầu (không ghi gì vào DB) vẫn tới được 20 thẻ phía sau.
  const skipped = first.cards.map((c) => c.item_id);
  const second = await service.dueBatch({ userId: USER, itemType: TYPE, limit: 20, excludeItemIds: skipped });
  const third = await service.dueBatch({
    userId: USER,
    itemType: TYPE,
    limit: 20,
    excludeItemIds: [...skipped, ...second.cards.map((c) => c.item_id)],
  });

  assert.equal(first.cards.length, 20);
  assert.equal(second.cards.length, 20);
  assert.equal(new Set([...skipped, ...second.cards.map((c) => c.item_id)]).size, 40);
  // Bỏ qua hết thì phiên dừng, dù badge vẫn còn đếm 40 thẻ đến hạn.
  assert.deepEqual(third.cards, []);
  assert.deepEqual(await service.dueCount({ userId: USER, itemType: TYPE }), { item_type: TYPE, total: 40 });
});

test('stats list every box from 1 to 5 even when empty', async () => {
  const repository = memoryRepository({
    rows: [card(), card({ _id: 'p2', item_id: 'v2', box: 3, next_review: new Date(NOW.getTime() + DAY) })],
  });
  const { service } = build({ repository });

  assert.deepEqual(await service.stats({ userId: USER, itemType: TYPE }), {
    item_type: TYPE,
    total_cards: 2,
    due_count: 1,
    by_box: { 1: 1, 2: 0, 3: 1, 4: 0, 5: 0 },
  });
});

// --- review -----------------------------------------------------------------

test('a correct answer moves the card up one box and records one activity', async () => {
  const { service, streak, repository } = build();

  const progress = await review(service);

  assert.deepEqual(progress, {
    _id: 'p1',
    item_id: 'v1',
    item_type: TYPE,
    box: 2,
    next_review: new Date(NOW.getTime() + 3 * DAY).toISOString(),
    streak: 1,
  });
  const [[activity, options]] = streak.calls;
  assert.deepEqual(activity, {
    userId: USER,
    type: 'srs.review',
    sourceId: 'p1',
    occurrenceKey: `srs:p1:${new Date(NOW.getTime() - DAY).toISOString()}`,
    context: { outcome: { remembered: true } },
  });
  // Cùng session và cùng mốc thời gian với lần ghi lịch.
  assert.deepEqual(options, { session: 'session-1', now: NOW });
  const [, cas] = repository.calls.find(([name]) => name === 'compareAndSet');
  assert.equal(cas.dueBy, NOW);
});

test('a wrong answer sends the card back to box 1 in 24 hours and still counts as study', async () => {
  const repository = memoryRepository({ rows: [card({ box: 4, streak: 3 })] });
  const { service, streak } = build({ repository });

  const progress = await review(service, { isCorrect: false });

  assert.equal(progress.box, 1);
  assert.equal(progress.streak, 0);
  assert.equal(progress.next_review, new Date(NOW.getTime() + DAY).toISOString());
  assert.deepEqual(streak.calls[0][0].context, { outcome: { remembered: false } });
});

test('three correct answers at each due time schedule 3, 7 then 14 days out', async () => {
  const { service, setNow } = build();
  let expected = new Date(NOW.getTime() - DAY);
  let at = NOW;
  const gaps = [];

  for (let i = 0; i < 3; i += 1) {
    setNow(at);
    const progress = await review(service, { expectedNextReview: expected });
    const next = new Date(progress.next_review);
    gaps.push((next - at) / DAY);
    expected = next;
    at = next;
  }

  assert.deepEqual(gaps, [3, 7, 14]);
});

test('a card is not due one millisecond early but is due exactly on time', async () => {
  const due = new Date(NOW.getTime() + DAY);
  const repository = memoryRepository({ rows: [card({ next_review: due })] });
  const { service, setNow, streak } = build({ repository });

  setNow(new Date(due.getTime() - 1));
  await assert.rejects(() => review(service, { expectedNextReview: due }), (error) => {
    assert.equal(error.status, 409);
    assert.equal(error.code, 'SRS_NOT_DUE');
    assert.equal(error.details.current_progress.next_review, due.toISOString());
    return true;
  });
  assert.equal(streak.calls.length, 0);

  setNow(due);
  assert.equal((await review(service, { expectedNextReview: due })).box, 2);
});

test('retrying an answer that already went through changes nothing a second time', async () => {
  const { service, streak } = build();

  await review(service);
  await assert.rejects(() => review(service), { code: 'SRS_NOT_DUE' });

  assert.equal(streak.calls.length, 1);
});

test('an answer for an old schedule is rejected when the card is due again', async () => {
  // Thẻ đang đến hạn ở kỳ mới; request gửi muộn còn mang hạn của kỳ trước.
  const { service } = build();

  await assert.rejects(
    () => review(service, { expectedNextReview: new Date(NOW.getTime() - 5 * DAY) }),
    { code: 'SRS_PROGRESS_CHANGED', status: 409 },
  );
});

test('a card that is missing or owned by someone else is 404', async () => {
  const repository = memoryRepository({ rows: [card({ user: OTHER_USER })] });
  const { service } = build({ repository });

  await assert.rejects(() => review(service), { status: 404 });
});

test('losing the write to a concurrent answer is reported as not due, with no activity', async () => {
  const { service, repository, streak } = build();
  repository.beforeNextWrite = (store) => {
    Object.assign(store.rows[0], { box: 2, streak: 1, next_review: new Date(NOW.getTime() + 3 * DAY) });
  };

  await assert.rejects(() => review(service), { code: 'SRS_NOT_DUE' });
  assert.equal(streak.calls.length, 0);
});

test('losing the write to a change that keeps the card due is reported as changed', async () => {
  const { service, repository } = build();
  repository.beforeNextWrite = (store) => {
    store.rows[0].box = 3;
  };

  await assert.rejects(() => review(service), { code: 'SRS_PROGRESS_CHANGED' });
});

test('losing the write to a delete is 404 and the card is not recreated', async () => {
  const { service, repository } = build();
  repository.beforeNextWrite = (store) => {
    store.rows.length = 0;
  };

  await assert.rejects(() => review(service), { status: 404 });
  assert.equal(repository.store.rows.length, 0);
});

test('a card whose content was deleted cannot be answered', async () => {
  const { service, streak, repository } = build({ repository: memoryRepository({ contents: [] }) });

  await assert.rejects(() => review(service), (error) => {
    assert.equal(error.code, 'ITEM_UNAVAILABLE');
    assert.equal(error.details.current_progress.box, 1);
    return true;
  });
  assert.equal(streak.calls.length, 0);
  assert.equal(repository.store.rows[0].box, 1);
});

test('failing to record the activity rolls the schedule back', async () => {
  const repository = memoryRepository();
  const { service } = build({ repository, streak: fakeStreak({ fail: true }) });

  await assert.rejects(() => review(service), /ghi event thất bại/);
  assert.equal(repository.store.rows[0].box, 1);
  assert.equal(repository.store.rows[0].next_review.getTime(), NOW.getTime() - DAY);
});

test('two different cards on the same day each record their own activity', async () => {
  const repository = memoryRepository({
    rows: [card(), card({ _id: 'p2', item_id: 'v2' })],
    contents: [{ _id: 'v1' }, { _id: 'v2' }],
  });
  const { service, streak } = build({ repository });

  await review(service);
  await review(service, { itemId: 'v2' });

  assert.deepEqual(
    streak.calls.map(([activity]) => activity.sourceId),
    ['p1', 'p2'],
  );
});

// --- reset and delete -------------------------------------------------------

test('reset puts the card in box 1 for tomorrow, even before it is due, without activity', async () => {
  const future = new Date(NOW.getTime() + 10 * DAY);
  const repository = memoryRepository({ rows: [card({ box: 4, streak: 3, next_review: future })] });
  const { service, streak } = build({ repository });

  const progress = await service.reset({ userId: USER, itemId: 'v1', itemType: TYPE, expectedNextReview: future });

  assert.equal(progress.box, 1);
  assert.equal(progress.streak, 0);
  assert.equal(progress.next_review, new Date(NOW.getTime() + DAY).toISOString());
  assert.equal(streak.calls.length, 0);
});

test('a retried reset does not push the schedule out again', async () => {
  const { service } = build();
  const expected = new Date(NOW.getTime() - DAY);

  await service.reset({ userId: USER, itemId: 'v1', itemType: TYPE, expectedNextReview: expected });
  await assert.rejects(
    () => service.reset({ userId: USER, itemId: 'v1', itemType: TYPE, expectedNextReview: expected }),
    { code: 'SRS_PROGRESS_CHANGED' },
  );
});

test('reset of a missing card is 404, and of a card deleted mid-flight is 404 too', async () => {
  const expected = new Date(NOW.getTime() - DAY);
  const empty = build({ repository: memoryRepository({ rows: [] }) });
  await assert.rejects(
    () => empty.service.reset({ userId: USER, itemId: 'v1', itemType: TYPE, expectedNextReview: expected }),
    { status: 404 },
  );

  const { service, repository } = build();
  repository.beforeNextWrite = (store) => {
    store.rows.length = 0;
  };
  await assert.rejects(
    () => service.reset({ userId: USER, itemId: 'v1', itemType: TYPE, expectedNextReview: expected }),
    { status: 404 },
  );
});

test('delete reports whether something was removed and is safe to repeat', async () => {
  const { service } = build();

  assert.deepEqual(await service.remove({ userId: USER, itemId: 'v1', itemType: TYPE }), { deleted: true });
  assert.deepEqual(await service.remove({ userId: USER, itemId: 'v1', itemType: TYPE }), { deleted: false });
});
