import assert from 'node:assert/strict';
import test from 'node:test';

import { createStreakRepository } from '../src/modules/streaks/streak.repository.js';

/** Model giả: ghi lại filter và update để khẳng định đúng tên trường. */
const fakeModel = (result = null) => {
  const calls = [];
  return {
    calls,
    findOne: (filter) => ({
      session: () => ({ lean: async () => (calls.push(['findOne', filter]), result) }),
    }),
    findOneAndUpdate: async (filter, update, options) => {
      calls.push(['findOneAndUpdate', filter, update, options]);
      return result;
    },
    create: async (docs) => (calls.push(['create', docs]), docs),
    updateOne: async (filter, update, options) => {
      calls.push(['updateOne', filter, update, options]);
      return { upsertedCount: 1 };
    },
    find: (filter) => {
      calls.push(['find', filter]);
      // Chain ghi lại đúng đối số của từng bước (sort/skip/limit) — không chỉ
      // việc chúng có được gọi hay không — để test phân trang có thể khẳng
      // định giá trị thật, bắt được lỗi kiểu off-by-one (`page * limit` thay
      // vì `(page - 1) * limit`).
      const chain = {
        sort: (arg) => (calls.push(['sort', arg]), chain),
        skip: (arg) => (calls.push(['skip', arg]), chain),
        limit: (arg) => (calls.push(['limit', arg]), chain),
        lean: async () => result ?? [],
      };
      return chain;
    },
    countDocuments: async (filter) => (calls.push(['countDocuments', filter]), result ?? 0),
  };
};

test('casUpdate so khớp last_activity_day đã đọc', async () => {
  const UserStreak = fakeModel({ _id: 's1' });
  const repository = createStreakRepository({
    UserStreak,
    XpEvent: fakeModel(),
    StreakDay: fakeModel(),
  });

  await repository.casUpdate({
    userId: 'u1',
    expectedDay: '2026-09-09',
    patch: { current_streak: 6, last_activity_day: '2026-09-10' },
    session: 'sess',
  });

  const [, filter, update, options] = UserStreak.calls.at(-1);
  assert.deepEqual(filter, { user: 'u1', last_activity_day: '2026-09-09' });
  assert.equal(update.$set.current_streak, 6);
  // runValidators: true — không có cờ này thì min/max của freezes_available
  // (và mọi validator khác trên UserStreak) không được Mongoose kiểm tra khi
  // ghi qua findOneAndUpdate.
  assert.equal(options.runValidators, true);
});

test('casUpdate với expectedDay null khớp document chưa từng học', async () => {
  const UserStreak = fakeModel({ _id: 's1' });
  const repository = createStreakRepository({
    UserStreak,
    XpEvent: fakeModel(),
    StreakDay: fakeModel(),
  });

  await repository.casUpdate({
    userId: 'u1',
    expectedDay: null,
    patch: { current_streak: 1 },
  });

  const [, filter] = UserStreak.calls.at(-1);
  assert.deepEqual(filter, { user: 'u1', last_activity_day: null });
});

test('casUpdate trả về null khi CAS thua (request khác đã ghi trước)', async () => {
  // fakeModel(null) mô phỏng findOneAndUpdate không tìm thấy document khớp
  // filter — đúng tình huống một request khác đã đổi last_activity_day trước.
  const UserStreak = fakeModel(null);
  const repository = createStreakRepository({
    UserStreak,
    XpEvent: fakeModel(),
    StreakDay: fakeModel(),
  });

  const saved = await repository.casUpdate({
    userId: 'u1',
    expectedDay: '2026-09-09',
    patch: { current_streak: 6 },
  });

  assert.equal(saved, null);
});

test('[Vòng sửa 1] casUpdate với xpDelta ghi $inc thay vì $set tổng tuyệt đối', async () => {
  const UserStreak = fakeModel({ _id: 's1' });
  const repository = createStreakRepository({
    UserStreak,
    XpEvent: fakeModel(),
    StreakDay: fakeModel(),
  });

  await repository.casUpdate({
    userId: 'u1',
    expectedDay: '2026-09-10',
    patch: { current_streak: 5 },
    xpDelta: 15,
  });

  const [, , update] = UserStreak.calls.at(-1);
  assert.deepEqual(update.$inc, { total_xp: 15 });
  // total_xp không được nằm trong $set — nếu có thì hai request cùng ngày
  // dựa trên bản đọc cũ sẽ đè số của nhau thay vì cộng dồn (đúng lỗi Vòng sửa 1).
  assert.equal(update.$set.total_xp, undefined);
});

test('[Vòng sửa 1] casUpdate với rewardKey vừa lọc filter vừa $addToSet', async () => {
  const UserStreak = fakeModel({ _id: 's1' });
  const repository = createStreakRepository({
    UserStreak,
    XpEvent: fakeModel(),
    StreakDay: fakeModel(),
  });

  await repository.casUpdate({
    userId: 'u1',
    expectedDay: '2026-09-10',
    patch: { current_streak: 5 },
    xpDelta: 15,
    rewardKey: 'lesson.complete:l1',
  });

  const [, filter, update] = UserStreak.calls.at(-1);
  // Chống trùng nằm ngay trong filter CAS — chặn thưởng hai lần cho cùng
  // sourceId dù last_activity_day không đổi (hoạt động lặp trong ngày).
  assert.deepEqual(filter, {
    user: 'u1',
    last_activity_day: '2026-09-10',
    reward_keys: { $ne: 'lesson.complete:l1' },
  });
  assert.deepEqual(update.$addToSet, { reward_keys: 'lesson.complete:l1' });
  // reward_keys tuyệt đối không được nằm trong $set — lý do y hệt total_xp.
  assert.equal(update.$set.reward_keys, undefined);
});

test('casUpdate không có rewardKey (hoạt động lặp) thì không lọc và không $addToSet reward_keys', async () => {
  const UserStreak = fakeModel({ _id: 's1' });
  const repository = createStreakRepository({
    UserStreak,
    XpEvent: fakeModel(),
    StreakDay: fakeModel(),
  });

  await repository.casUpdate({
    userId: 'u1',
    expectedDay: '2026-09-10',
    patch: { current_streak: 5 },
    xpDelta: 2,
  });

  const [, filter, update] = UserStreak.calls.at(-1);
  assert.deepEqual(filter, { user: 'u1', last_activity_day: '2026-09-10' });
  assert.equal(update.$addToSet, undefined);
});

test('markDay upsert theo (user, day_key) nên gọi lại không sinh bản sao', async () => {
  const StreakDay = fakeModel();
  const repository = createStreakRepository({
    UserStreak: fakeModel(),
    XpEvent: fakeModel(),
    StreakDay,
  });

  await repository.markDay({ userId: 'u1', dayKey: '2026-09-10', status: 'studied' });

  const [, filter, , options] = StreakDay.calls.at(-1);
  assert.deepEqual(filter, { user: 'u1', day_key: '2026-09-10' });
  assert.equal(options.upsert, true);
  assert.equal(options.runValidators, true);
});

test('markDay dùng $setOnInsert nên không đổi status của ngày đã có bản ghi', async () => {
  const StreakDay = fakeModel();
  const repository = createStreakRepository({
    UserStreak: fakeModel(),
    XpEvent: fakeModel(),
    StreakDay,
  });

  await repository.markDay({ userId: 'u1', dayKey: '2026-09-10', status: 'frozen' });

  const [, , update] = StreakDay.calls.at(-1);
  assert.deepEqual(update, {
    $setOnInsert: { user: 'u1', day_key: '2026-09-10', status: 'frozen' },
  });
  assert.equal(update.$set, undefined);
});

test('appendXpEvent ghi đúng tên trường snake_case', async () => {
  const XpEvent = fakeModel();
  const repository = createStreakRepository({
    UserStreak: fakeModel(),
    XpEvent,
    StreakDay: fakeModel(),
  });

  await repository.appendXpEvent({
    userId: 'u1',
    amount: 10,
    reason: 'exercise.submit',
    type: 'exercise.submit',
    sourceId: 'ex1',
    earnedAt: new Date('2026-09-09T00:00:00.000Z'),
    session: 'sess',
  });

  const [, docs] = XpEvent.calls.at(-1);
  assert.deepEqual(docs, [
    {
      user: 'u1',
      amount: 10,
      reason: 'exercise.submit',
      type: 'exercise.submit',
      source_id: 'ex1',
      earned_at: new Date('2026-09-09T00:00:00.000Z'),
    },
  ]);
});

test('ensureFor upsert bằng $setOnInsert để không đụng document đã có', async () => {
  const UserStreak = fakeModel({ _id: 's1', user: 'u1' });
  const repository = createStreakRepository({
    UserStreak,
    XpEvent: fakeModel(),
    StreakDay: fakeModel(),
  });

  await repository.ensureFor({ userId: 'u1', session: 'sess' });

  const [, filter, update, options] = UserStreak.calls.at(-1);
  assert.deepEqual(filter, { user: 'u1' });
  assert.deepEqual(update, { $setOnInsert: { user: 'u1' } });
  assert.equal(options.upsert, true);
  assert.equal(options.setDefaultsOnInsert, true);
  assert.equal(options.runValidators, true);
});

test('listXpEvents phân trang bằng skip/limit theo page truyền vào', async () => {
  const XpEvent = fakeModel([{ amount: 5 }]);
  const repository = createStreakRepository({
    UserStreak: fakeModel(),
    XpEvent,
    StreakDay: fakeModel(),
  });

  // page: 3, limit: 20 phải cho skip(40) — tức (page - 1) * limit. Một lỗi
  // off-by-one (`page * limit` = 60) sẽ làm test này fail thay vì trôi qua
  // như trước khi chain không ghi lại tham số.
  const rows = await repository.listXpEvents({ userId: 'u1', page: 3, limit: 20 });

  assert.deepEqual(rows, [{ amount: 5 }]);
  const [findCall, sortCall, skipCall, limitCall] = XpEvent.calls;
  assert.deepEqual(findCall, ['find', { user: 'u1' }]);
  assert.deepEqual(sortCall, ['sort', { earned_at: -1 }]);
  assert.deepEqual(skipCall, ['skip', 40]);
  assert.deepEqual(limitCall, ['limit', 20]);
});

test('listXpEvents dùng page mặc định 1 khi không truyền', async () => {
  const XpEvent = fakeModel([]);
  const repository = createStreakRepository({
    UserStreak: fakeModel(),
    XpEvent,
    StreakDay: fakeModel(),
  });

  await repository.listXpEvents({ userId: 'u1' });

  const skipCall = XpEvent.calls.find(([name]) => name === 'skip');
  const limitCall = XpEvent.calls.find(([name]) => name === 'limit');
  assert.deepEqual(skipCall, ['skip', 0]);
  assert.deepEqual(limitCall, ['limit', 20]);
});
