import assert from 'node:assert/strict';
import test from 'node:test';

import { createGoalService } from '../src/modules/goals/goal.service.js';

const A = 'aaaaaaaaaaaaaaaaaaaaaaaa';
const B = 'bbbbbbbbbbbbbbbbbbbbbbbb';
const NOW = new Date('2026-11-04T08:00:00.000Z');

const same = (left, right) => String(left) === String(right);

/**
 * Repository giả lưu trong bộ nhớ, giữ đúng các điều kiện ghi của repository
 * thật: mọi thao tác lọc theo `userId`; ghi hoàn thành chỉ khớp khi chưa hoàn
 * thành **và** số cần đạt chưa đổi; sửa có điều kiện chỉ khớp khi chưa hoàn thành.
 */
const memoryRepository = () => {
  const rows = [];
  let sequence = 0;
  const owned = (row, { id, userId }) => same(row._id, id) && same(row.user, userId);
  return {
    rows,
    sessions: [],
    findByUser: async (userId) => rows.filter((row) => same(row.user, userId)).reverse().map((row) => ({ ...row })),
    findIncomplete: async function ({ userId, session }) {
      this.sessions.push(session);
      return rows.filter((row) => same(row.user, userId) && row.completed_at === null).map((row) => ({ ...row }));
    },
    findOwned: async (query) => {
      const row = rows.find((candidate) => owned(candidate, query));
      return row ? { ...row } : null;
    },
    create: async (doc) => {
      sequence += 1;
      const row = { _id: `g${sequence}`, deadline: null, completed_at: null, createdAt: new Date(Date.UTC(2026, 10, 1, 0, sequence)), ...doc };
      rows.push(row);
      return { ...row };
    },
    updateOwned: async ({ id, userId, set, onlyIfIncomplete = false }) => {
      const row = rows.find((candidate) => owned(candidate, { id, userId }) && (!onlyIfIncomplete || candidate.completed_at === null));
      if (!row) return null;
      Object.assign(row, set);
      return { ...row };
    },
    markCompleted: async ({ id, userId, target, at }) => {
      const row = rows.find((candidate) =>
        owned(candidate, { id, userId }) && candidate.completed_at === null && candidate.target === target);
      if (!row) return false;
      row.completed_at = at;
      return true;
    },
    deleteOwned: async (query) => {
      const index = rows.findIndex((row) => owned(row, query));
      if (index === -1) return 0;
      rows.splice(index, 1);
      return 1;
    },
    countAvailable: async () => ({ lessons: 40, kanji: 33 }),
  };
};

/**
 * Bộ đếm "đã học" giả theo từng tài khoản — cùng tên hàm với bộ đếm chung của
 * dashboard. [onCount] chạy giữa lúc đọc mục tiêu và lúc ghi, để giả một
 * request khác chen vào đúng khoảng đó.
 */
const fakeCounters = (counts, calls = []) => {
  const counter = (field) => async ({ userId, session }) => {
    calls.push([field, session]);
    await counts.onCount?.();
    return counts[userId]?.[field] ?? 0;
  };
  return {
    countCompletedLessons: counter('lessons'),
    countLearnedVocabulary: counter('vocabulary'),
    countLearnedKanji: counter('kanji'),
  };
};

const setup = (counts = { [A]: { lessons: 2, vocabulary: 120, kanji: 5 }, [B]: { vocabulary: 10 } }) => {
  const repository = memoryRepository();
  const counterCalls = [];
  let now = NOW;
  const service = createGoalService({
    goalRepository: repository,
    counters: fakeCounters(counts, counterCalls),
    clock: () => now,
  });
  return { repository, service, counts, counterCalls, setNow: (value) => { now = value; } };
};

test('tạo mục tiêu: tiến độ tính cả những gì đã học trước đó, tên tự đặt khi bỏ trống', async () => {
  const { service } = setup();

  const goal = await service.create({ userId: A, type: 'vocabulary', target: 150 });

  assert.deepEqual(goal, {
    id: 'g1',
    type: 'vocabulary',
    title: 'Đạt 150 từ vựng',
    target: 150,
    current: 120,
    is_completed: false,
    completed_at: null,
    deadline: null,
    created_at: '2026-11-01T00:01:00.000Z',
  });
});

test('số cần đạt không lớn hơn số đang có thì từ chối, kèm số hiện có', async () => {
  const { service, repository } = setup();

  await assert.rejects(
    () => service.create({ userId: A, type: 'vocabulary', target: 120 }),
    { status: 400, code: 'GOAL_TARGET_REACHED', details: { current: 120 } },
  );
  assert.equal(repository.rows.length, 0);
});

test('danh sách và bộ đếm hiện tại; mỗi tài khoản chỉ thấy mục tiêu của mình', async () => {
  const { service } = setup();
  await service.create({ userId: A, type: 'lessons', target: 5, title: 'Năm bài đầu' });
  await service.create({ userId: B, type: 'vocabulary', target: 50 });

  const ofA = await service.list(A);
  const ofB = await service.list(B);

  assert.deepEqual(ofA.goals.map((goal) => [goal.title, goal.current]), [['Năm bài đầu', 2]]);
  assert.deepEqual(ofA.counts, { lessons: 2, vocabulary: 120, kanji: 5 });
  assert.deepEqual(ofA.available, { lessons: 40, kanji: 33 });
  assert.deepEqual(ofB.goals.map((goal) => goal.title), ['Đạt 50 từ vựng']);
});

test('học đủ thì hoàn thành và lưu thời điểm; số giảm sau đó không làm rớt lại', async () => {
  const { service, counts } = setup();
  await service.create({ userId: A, type: 'kanji', target: 6 });

  counts[A].kanji = 6;
  const [reached] = (await service.list(A)).goals;
  assert.equal(reached.is_completed, true);
  assert.equal(reached.completed_at, NOW.toISOString());

  counts[A].kanji = 4;
  const [later] = (await service.list(A)).goals;
  assert.equal(later.is_completed, true);
  assert.equal(later.current, 4);
});

test('A không sửa, không xoá được mục tiêu của B', async () => {
  const { service, repository } = setup();
  const ofB = await service.create({ userId: B, type: 'vocabulary', target: 50 });

  await assert.rejects(() => service.update({ id: ofB.id, userId: A, changes: { title: 'Của A' } }), { status: 404 });
  await assert.rejects(() => service.remove({ id: ofB.id, userId: A }), { status: 404 });

  assert.equal(repository.rows[0].title, 'Đạt 50 từ vựng');
});

test('sửa tên, hạn và số cần đạt; số mới vẫn phải lớn hơn số đang có', async () => {
  const { service } = setup();
  const goal = await service.create({ userId: A, type: 'vocabulary', target: 150 });

  const updated = await service.update({ id: goal.id, userId: A, changes: { title: 'Mốc N5', target: 200, deadline: '2026-12-31' } });
  assert.deepEqual([updated.title, updated.target, updated.deadline], ['Mốc N5', 200, '2026-12-31']);

  const cleared = await service.update({ id: goal.id, userId: A, changes: { deadline: null } });
  assert.equal(cleared.deadline, null);

  await assert.rejects(
    () => service.update({ id: goal.id, userId: A, changes: { target: 100 } }),
    { status: 400, code: 'GOAL_TARGET_REACHED' },
  );
});

test('mục tiêu đã hoàn thành không đổi số cần đạt được, nhưng vẫn đổi tên được', async () => {
  const { service, counts } = setup();
  const goal = await service.create({ userId: A, type: 'lessons', target: 3 });
  counts[A].lessons = 3;
  await service.list(A);

  await assert.rejects(
    () => service.update({ id: goal.id, userId: A, changes: { target: 10 } }),
    { status: 400, code: 'GOAL_COMPLETED' },
  );
  assert.equal((await service.update({ id: goal.id, userId: A, changes: { title: 'Đã xong' } })).title, 'Đã xong');
});

test('xoá mục tiêu của mình', async () => {
  const { service } = setup();
  const goal = await service.create({ userId: A, type: 'kanji', target: 10 });

  await service.remove({ id: goal.id, userId: A });

  assert.deepEqual((await service.list(A)).goals, []);
});

test('ghi nhận hoàn thành ngay lúc học đạt mốc, trong transaction của hoạt động học', async () => {
  const { service, counts, repository, setNow } = setup();
  await service.create({ userId: A, type: 'kanji', target: 6 });

  counts[A].kanji = 6;
  const learnedAt = new Date('2026-11-04T09:30:00.000Z');
  assert.deepEqual(await service.recordReached({ userId: A, at: learnedAt, session: 'tx' }), ['g1']);
  assert.deepEqual(repository.sessions, ['tx']);

  // Hai ngày sau mới mở màn, và đã bỏ "Đã nhớ" một chữ: vẫn hoàn thành đúng lúc học.
  counts[A].kanji = 5;
  setNow(new Date('2026-11-06T08:00:00.000Z'));
  const [goal] = (await service.list(A)).goals;
  assert.equal(goal.is_completed, true);
  assert.equal(goal.completed_at, learnedAt.toISOString());
});

test('chỉ xét mục tiêu chưa hoàn thành; không có thì không đếm gì', async () => {
  const { service, counterCalls } = setup();

  assert.deepEqual(await service.recordReached({ userId: A, at: NOW }), []);
  assert.deepEqual(counterCalls, []);

  await service.create({ userId: A, type: 'lessons', target: 5 });
  counterCalls.length = 0;
  await service.recordReached({ userId: A, at: NOW, session: 'tx' });
  assert.deepEqual(counterCalls, [['lessons', 'tx']], 'chỉ đếm đúng loại cần xét, cùng session');
});

test('đang ghi hoàn thành thì số cần đạt bị nâng lên: không báo hoàn thành sai', async () => {
  const { service, counts, repository } = setup();
  await service.create({ userId: A, type: 'kanji', target: 6 });
  counts[A].kanji = 6;
  // Một request sửa chen vào giữa lúc đọc mục tiêu và lúc ghi hoàn thành.
  counts.onCount = () => { repository.rows[0].target = 10; };

  assert.deepEqual(await service.recordReached({ userId: A, at: NOW }), []);
  const [goal] = (await service.list(A)).goals;

  assert.deepEqual([goal.target, goal.current, goal.is_completed], [10, 6, false]);
  assert.equal(repository.rows[0].completed_at, null);
});

test('đang sửa số cần đạt thì mục tiêu vừa hoàn thành: từ chối, giữ nguyên số cũ', async () => {
  const { service, counts, repository } = setup();
  const created = await service.create({ userId: A, type: 'kanji', target: 6 });
  // Hoạt động học ghi hoàn thành chen vào giữa lúc đọc và lúc sửa.
  counts.onCount = () => { repository.rows[0].completed_at = NOW; };

  await assert.rejects(
    () => service.update({ id: created.id, userId: A, changes: { target: 10 } }),
    { status: 400, code: 'GOAL_COMPLETED' },
  );
  assert.equal(repository.rows[0].target, 6);
});
