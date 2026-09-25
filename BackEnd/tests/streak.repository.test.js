import assert from 'node:assert/strict';
import test from 'node:test';

import { createStreakRepository } from '../src/modules/streaks/streak.repository.js';

/** Lỗi trùng khoá y như driver Mongo ném ra, kèm `keyPattern` của index. */
const duplicateKeyError = (keyPattern = { user: 1, event_key: 1 }) =>
  Object.assign(new Error('E11000 duplicate key error'), { code: 11000, keyPattern });

/**
 * Model giả ghi lại mọi lệnh cùng **đầy đủ đối số**, không chỉ tên lệnh.
 *
 * Ghi lại đối số là điểm mấu chốt: phần lớn lỗi của tầng này là sai tên
 * trường, sai toán tử (`$set` thay vì `$inc`) hay thiếu `session` — tất cả
 * đều lọt qua một test chỉ kiểm "có được gọi không".
 */
const fakeModel = ({ result = null, createError = null, findOneResult } = {}) => {
  const calls = [];
  const chain = (rows) => {
    const self = {
      sort: (arg) => (calls.push(['sort', arg]), self),
      limit: (arg) => (calls.push(['limit', arg]), self),
      skip: (arg) => (calls.push(['skip', arg]), self),
      session: (arg) => (calls.push(['session', arg]), self),
      select: (arg) => (calls.push(['select', arg]), self),
      lean: async () => rows,
    };
    return self;
  };
  return {
    calls,
    create: async (docs, options) => {
      calls.push(['create', docs, options]);
      if (createError) throw createError;
      return docs.map((doc, index) => ({ _id: `e${index}`, ...doc }));
    },
    findOne: (filter) => {
      calls.push(['findOne', filter]);
      return chain(findOneResult ?? result);
    },
    findOneAndUpdate: async (filter, update, options) => {
      calls.push(['findOneAndUpdate', filter, update, options]);
      return result;
    },
    updateOne: async (filter, update, options) => {
      calls.push(['updateOne', filter, update, options]);
      return { matchedCount: 1, upsertedCount: 0 };
    },
    find: (filter) => {
      calls.push(['find', filter]);
      return chain(Array.isArray(result) ? result : []);
    },
    aggregate: async (pipeline, options) => {
      calls.push(['aggregate', pipeline, options]);
      return Array.isArray(result) ? result : [];
    },
    exists: async (filter) => {
      calls.push(['exists', filter]);
      return result;
    },
    distinct: async (field, filter) => {
      calls.push(['distinct', field, filter]);
      return Array.isArray(result) ? result : [];
    },
    countDocuments: async (filter) => {
      calls.push(['countDocuments', filter]);
      return typeof result === 'number' ? result : 0;
    },
  };
};

const build = (overrides = {}) =>
  createStreakRepository({
    UserStreak: fakeModel(),
    ActivityEvent: fakeModel(),
    StreakDay: fakeModel(),
    ...overrides,
  });

const lastCall = (model, name) => model.calls.filter(([called]) => called === name).at(-1);

// --- insertEvent -----------------------------------------------------------

test('insertEvent writes every spec field and stays inside the session', async () => {
  const ActivityEvent = fakeModel();
  const occurredAt = new Date('2026-09-11T02:00:00.000Z');

  const saved = await build({ ActivityEvent }).insertEvent({
    userId: 'u1',
    eventKey: 'lesson-complete:l1',
    type: 'lesson.complete',
    sourceId: 'l1',
    occurredAt,
    dayKey: '2026-09-11',
    xpDelta: 20,
    reason: 'lesson.complete',
    countsAsStudy: true,
    policyVersion: 'p1',
    session: 'sess',
  });

  const [, docs, options] = lastCall(ActivityEvent, 'create');
  assert.deepEqual(docs, [
    {
      user: 'u1',
      event_key: 'lesson-complete:l1',
      type: 'lesson.complete',
      source_id: 'l1',
      occurred_at: occurredAt,
      day_key: '2026-09-11',
      xp_delta: 20,
      reason: 'lesson.complete',
      counts_as_study: true,
      policy_version: 'p1',
    },
  ]);
  // Mảng `[doc]` là bắt buộc, không phải phong cách: truyền thẳng một object
  // khiến Mongoose không nhận ra tham số thứ hai là options và `session` bị
  // bỏ qua lặng lẽ — bản ghi rơi ra ngoài transaction.
  assert.ok(Array.isArray(docs));
  assert.deepEqual(options, { session: 'sess' });
  assert.equal(saved.event_key, 'lesson-complete:l1');
});

test('insertEvent omits receipt entirely when there is none', async () => {
  const ActivityEvent = fakeModel();
  await build({ ActivityEvent }).insertEvent({
    userId: 'u1',
    eventKey: 'k',
    type: 'srs.review',
    occurredAt: new Date(),
    dayKey: '2026-09-11',
    policyVersion: 'p1',
  });
  const [, [doc]] = lastCall(ActivityEvent, 'create');
  assert.equal('receipt' in doc, false);
});

test('a duplicate event key inside a transaction asks for a retry, not a null', async () => {
  // MongoDB **huỷ cả transaction** khi một lệnh ghi đụng unique index. Trả
  // `null` như một câu trả lời bình thường khiến caller đi tiếp trên một
  // session đã chết, và lệnh kế tiếp nổ "Transaction has been aborted".
  // Gắn nhãn transient để unit of work chạy lại cả transaction; lần chạy lại
  // sẽ thấy event đã có và đi nhánh trùng mà không ghi gì.
  const ActivityEvent = fakeModel({ createError: duplicateKeyError() });

  await assert.rejects(
    build({ ActivityEvent }).insertEvent({ userId: 'u1', eventKey: 'k1', session: 'sess' }),
    (error) => {
      assert.equal(error.errorLabels.includes('TransientTransactionError'), true);
      return true;
    },
  );
});

test('a duplicate on some other index is still a real error', async () => {
  // Nuốt mọi E11000 sẽ che mất lỗi thật nếu sau này collection có thêm unique
  // index khác — im lặng bỏ qua một lần ghi hỏng là kiểu hỏng khó lần nhất.
  const ActivityEvent = fakeModel({ createError: duplicateKeyError({ some_other: 1 }) });
  await assert.rejects(
    build({ ActivityEvent }).insertEvent({
      userId: 'u1',
      eventKey: 'k',
      type: 'srs.review',
      occurredAt: new Date(),
      dayKey: '2026-09-11',
      policyVersion: 'p1',
    }),
    /duplicate key/,
  );
});

test('a non-duplicate write failure is never swallowed', async () => {
  const ActivityEvent = fakeModel({ createError: new Error('network down') });
  await assert.rejects(
    build({ ActivityEvent }).insertEvent({
      userId: 'u1',
      eventKey: 'k',
      type: 'srs.review',
      occurredAt: new Date(),
      dayKey: '2026-09-11',
      policyVersion: 'p1',
    }),
    /network down/,
  );
});

// --- casSummary ------------------------------------------------------------

test('casSummary locks on the revision it read and bumps it in the same write', async () => {
  const UserStreak = fakeModel({ result: { _id: 's1' } });
  await build({ UserStreak }).casSummary({
    userId: 'u1',
    expectedRevision: 4,
    patch: { current_streak: 6, last_activity_day: '2026-09-11' },
    inc: { total_xp: 20, total_active_days: 1 },
    session: 'sess',
  });

  const [, filter, update, options] = lastCall(UserStreak, 'findOneAndUpdate');
  assert.deepEqual(filter, { user: 'u1', revision: 4 });
  assert.deepEqual(update.$set, { current_streak: 6, last_activity_day: '2026-09-11' });
  // revision phải tăng trong **cùng** lệnh ghi, nếu không thì hai request đọc
  // cùng một revision vẫn có thể cùng thắng.
  assert.deepEqual(update.$inc, { total_xp: 20, total_active_days: 1, revision: 1 });
  assert.equal(options.runValidators, true);
  assert.equal(options.new, true);
  assert.equal(options.session, 'sess');
});

test('casSummary still bumps revision when there is nothing else to write', async () => {
  const UserStreak = fakeModel({ result: { _id: 's1' } });
  await build({ UserStreak }).casSummary({ userId: 'u1', expectedRevision: 0 });
  const [, , update] = lastCall(UserStreak, 'findOneAndUpdate');
  assert.deepEqual(update.$inc, { revision: 1 });
  // `$set: {}` là lỗi cú pháp của Mongo ("'$set' is empty"), không phải no-op.
  assert.equal('$set' in update, false);
});

test('casSummary at revision 0 also claims a legacy summary that has no revision field', async () => {
  // Bốn tóm tắt ghi trước cutover không có trường `revision`. Lọc đúng
  // `revision: 0` thì không bao giờ khớp chúng: mọi hoạt động của các user đó
  // thua CAS năm lần rồi trả 409. `null` trong filter của Mongo khớp cả trường
  // vắng mặt lẫn trường bằng null.
  const UserStreak = fakeModel({ result: { _id: 's1' } });
  await build({ UserStreak }).casSummary({ userId: 'u1', expectedRevision: 0 });

  const [, filter] = lastCall(UserStreak, 'findOneAndUpdate');
  assert.deepEqual(filter, { user: 'u1', revision: { $in: [0, null] } });
});

test('casSummary above revision 0 never matches a legacy summary', async () => {
  // Chỉ mức 0 mới được nhận document chưa có revision. Nhận ở mức khác sẽ để
  // hai request đọc hai revision khác nhau cùng thắng.
  const UserStreak = fakeModel({ result: { _id: 's1' } });
  await build({ UserStreak }).casSummary({ userId: 'u1', expectedRevision: 3 });

  const [, filter] = lastCall(UserStreak, 'findOneAndUpdate');
  assert.deepEqual(filter, { user: 'u1', revision: 3 });
});

test('casSummary returning null is how a caller learns it lost the race', async () => {
  const UserStreak = fakeModel({ result: null });
  const saved = await build({ UserStreak }).casSummary({ userId: 'u1', expectedRevision: 4 });
  assert.equal(saved, null);
});

// --- ensureSummary ---------------------------------------------------------

test('ensureSummary creates the summary without touching an existing one', async () => {
  const UserStreak = fakeModel({ result: { _id: 's1', user: 'u1', revision: 0 } });
  const summary = await build({ UserStreak }).ensureSummary({ userId: 'u1', session: 'sess' });

  const [, filter, update, options] = lastCall(UserStreak, 'findOneAndUpdate');
  assert.deepEqual(filter, { user: 'u1' });
  assert.deepEqual(update, { $setOnInsert: { user: 'u1' } });
  assert.equal(options.upsert, true);
  assert.equal(options.setDefaultsOnInsert, true);
  assert.equal(options.session, 'sess');
  assert.equal(summary.user, 'u1');
});

test('two first-ever requests racing to create a summary both get one back', async () => {
  // Upsert đồng thời: một bên thắng, bên kia nhận E11000 từ unique index
  // `user`. Bên thua phải đọc lại chứ không được ném — đây là lần học đầu
  // tiên của người dùng, hỏng ở đây là hỏng ngay ấn tượng đầu.
  const UserStreak = fakeModel({ result: null, findOneResult: { _id: 's1', revision: 0 } });
  UserStreak.findOneAndUpdate = async (filter, update, options) => {
    UserStreak.calls.push(['findOneAndUpdate', filter, update, options]);
    throw duplicateKeyError({ user: 1 });
  };

  const summary = await build({ UserStreak }).ensureSummary({ userId: 'u1', session: 'sess' });

  assert.deepEqual(summary, { _id: 's1', revision: 0 });
  assert.deepEqual(lastCall(UserStreak, 'findOne'), ['findOne', { user: 'u1' }]);
  assert.deepEqual(lastCall(UserStreak, 'session'), ['session', 'sess']);
});

// --- upsertDay -------------------------------------------------------------

test('a studied day upgrades a legacy record but keeps its legacy origin', async () => {
  const StreakDay = fakeModel();
  await build({ StreakDay }).upsertDay({
    userId: 'u1',
    dayKey: '2026-09-11',
    status: 'studied',
    incDirectXp: 20,
    incReviewCount: 1,
    incCorrect: 1,
    session: 'sess',
  });

  const [, filter, update, options] = lastCall(StreakDay, 'updateOne');
  assert.deepEqual(filter, { user: 'u1', day_key: '2026-09-11' });
  // `$set` chứ không `$setOnInsert`: một ngày `legacy` gặp hoạt động thật
  // phải được nâng lên `studied` (spec §3.2).
  assert.deepEqual(update.$set, { status: 'studied' });
  // `origin` chỉ đặt lúc tạo mới — ngày legacy được nâng vẫn giữ dấu nguồn
  // của nó, nhờ đó migration biết ngày đó đã tính ở baseline rồi.
  assert.deepEqual(update.$setOnInsert, {
    user: 'u1',
    day_key: '2026-09-11',
    origin: 'activity',
  });
  assert.deepEqual(update.$inc, { direct_xp: 20, review_count: 1, correct_self_reports: 1 });
  assert.equal(options.upsert, true);
  assert.equal(options.runValidators, true);
  assert.equal(options.session, 'sess');
});

test('a frozen or legacy day never overwrites a day already proven studied', async () => {
  for (const status of ['frozen', 'legacy']) {
    const StreakDay = fakeModel();
    await build({ StreakDay }).upsertDay({ userId: 'u1', dayKey: '2026-09-10', status });
    const [, , update] = lastCall(StreakDay, 'updateOne');
    assert.equal(update.$set, undefined, `${status} không được $set status`);
    assert.equal(update.$setOnInsert.status, status);
  }
});

test('upsertDay omits $inc entirely when there is nothing to count', async () => {
  const StreakDay = fakeModel();
  await build({ StreakDay }).upsertDay({ userId: 'u1', dayKey: '2026-09-10', status: 'frozen' });
  const [, , update] = lastCall(StreakDay, 'updateOne');
  assert.equal('$inc' in update, false);
});

test('upsertDay rejects a status outside the enum before it reaches Mongo', async () => {
  await assert.rejects(
    build().upsertDay({ userId: 'u1', dayKey: '2026-09-10', status: 'studied_maybe' }),
    /status/,
  );
});

// --- listEvents ------------------------------------------------------------

test('listEvents pages by keyset, never by skip', async () => {
  const ActivityEvent = fakeModel({ result: [{ _id: 'e1' }] });
  const cursorAt = new Date('2026-09-11T02:00:00.000Z');

  await build({ ActivityEvent }).listEvents({
    userId: 'u1',
    cursor: { occurredAt: cursorAt, id: 'e9' },
    limit: 20,
  });

  const [, filter] = lastCall(ActivityEvent, 'find');
  // Hai nhánh: mốc thời gian nhỏ hơn hẳn, hoặc cùng mốc nhưng `_id` nhỏ hơn.
  // Thiếu nhánh thứ hai thì các event ghi cùng một transaction (cùng
  // `occurred_at`) bị bỏ sót hoặc lặp giữa hai trang.
  assert.deepEqual(filter.$or, [
    { occurred_at: { $lt: cursorAt } },
    { occurred_at: cursorAt, _id: { $lt: 'e9' } },
  ]);
  assert.deepEqual(lastCall(ActivityEvent, 'sort'), ['sort', { occurred_at: -1, _id: -1 }]);
  assert.deepEqual(lastCall(ActivityEvent, 'limit'), ['limit', 20]);
  assert.equal(ActivityEvent.calls.some(([name]) => name === 'skip'), false);
});

test('listEvents without a cursor does not invent one', async () => {
  const ActivityEvent = fakeModel({ result: [] });
  await build({ ActivityEvent }).listEvents({ userId: 'u1' });
  const [, filter] = lastCall(ActivityEvent, 'find');
  assert.deepEqual(filter, { user: 'u1' });
});

test('the XP history view is a filter over the same events, not another table', async () => {
  const ActivityEvent = fakeModel({ result: [] });
  await build({ ActivityEvent }).listEvents({ userId: 'u1', withXpOnly: true });
  const [, filter] = lastCall(ActivityEvent, 'find');
  assert.deepEqual(filter.xp_delta, { $ne: 0 });
});

test('listEvents can be pinned to a point in time for a stable page sequence', async () => {
  const ActivityEvent = fakeModel({ result: [] });
  const asOf = new Date('2026-09-11T00:00:00.000Z');
  await build({ ActivityEvent }).listEvents({ userId: 'u1', asOf });
  const [, filter] = lastCall(ActivityEvent, 'find');
  assert.deepEqual(filter.occurred_at, { $lte: asOf });
});

test('listEvents caps the page size a caller can ask for', async () => {
  const ActivityEvent = fakeModel({ result: [] });
  await build({ ActivityEvent }).listEvents({ userId: 'u1', limit: 100_000 });
  const [, value] = lastCall(ActivityEvent, 'limit');
  assert.ok(value <= 200, `limit ${value} phải bị chặn trên`);
});

// --- listDays và sumXpBetween ---------------------------------------------

test('listDays asks for one inclusive range of day keys', async () => {
  const StreakDay = fakeModel({ result: [] });
  await build({ StreakDay }).listDays({ userId: 'u1', from: '2026-09-01', to: '2026-09-30' });
  const [, filter] = lastCall(StreakDay, 'find');
  assert.deepEqual(filter, {
    user: 'u1',
    day_key: { $gte: '2026-09-01', $lte: '2026-09-30' },
  });
  assert.deepEqual(lastCall(StreakDay, 'sort'), ['sort', { day_key: -1 }]);
});

test('sumXpBetween adds up events by day key and returns a plain number', async () => {
  const ActivityEvent = fakeModel({ result: [{ _id: null, total: 42 }] });
  const total = await build({ ActivityEvent }).sumXpBetween({
    userId: 'u1',
    fromDay: '2026-09-01',
    toDay: '2026-09-07',
  });

  assert.equal(total, 42);
  const [, pipeline] = lastCall(ActivityEvent, 'aggregate');
  assert.deepEqual(pipeline[0].$match.day_key, { $gte: '2026-09-01', $lte: '2026-09-07' });
  assert.equal(pipeline[1].$group.total.$sum, '$xp_delta');
});

test('a period with no events sums to zero, not undefined', async () => {
  const ActivityEvent = fakeModel({ result: [] });
  const total = await build({ ActivityEvent }).sumXpBetween({
    userId: 'u1',
    fromDay: '2026-09-01',
    toDay: '2026-09-07',
  });
  assert.equal(total, 0);
});

// --- ràng buộc chung -------------------------------------------------------

test('every write carries the session it was given', async () => {
  const UserStreak = fakeModel({ result: { _id: 's1' } });
  const ActivityEvent = fakeModel();
  const StreakDay = fakeModel();
  const repository = build({ UserStreak, ActivityEvent, StreakDay });

  await repository.insertEvent({
    userId: 'u1',
    eventKey: 'k',
    type: 'srs.review',
    occurredAt: new Date(),
    dayKey: '2026-09-11',
    policyVersion: 'p1',
    session: 'sess',
  });
  await repository.casSummary({ userId: 'u1', expectedRevision: 0, session: 'sess' });
  await repository.upsertDay({ userId: 'u1', dayKey: '2026-09-11', status: 'studied', session: 'sess' });
  await repository.ensureSummary({ userId: 'u1', session: 'sess' });

  assert.deepEqual(lastCall(ActivityEvent, 'create')[2], { session: 'sess' });
  assert.equal(lastCall(UserStreak, 'findOneAndUpdate')[3].session, 'sess');
  assert.equal(lastCall(StreakDay, 'updateOne')[3].session, 'sess');
});

// --- Đường đọc: receipt, lịch sử legacy, bảng xếp hạng -----------------------

test('findEventByKey reads one event by its occurrence key inside the session', async () => {
  const ActivityEvent = fakeModel({ result: { _id: 'e1', receipt: { fingerprint: 'f' } } });
  const event = await build({ ActivityEvent }).findEventByKey({
    userId: 'u1',
    eventKey: 'exercise-attempt:a1',
    session: 'sess',
  });

  assert.deepEqual(event, { _id: 'e1', receipt: { fingerprint: 'f' } });
  assert.deepEqual(lastCall(ActivityEvent, 'findOne')[1], { user: 'u1', event_key: 'exercise-attempt:a1' });
  assert.deepEqual(lastCall(ActivityEvent, 'session'), ['session', 'sess']);
});

test('hasLegacyImport asks whether the migration copied this user history', async () => {
  const ActivityEvent = fakeModel({ result: { _id: 'e9' } });
  assert.equal(await build({ ActivityEvent }).hasLegacyImport({ userId: 'u1' }), true);
  assert.deepEqual(lastCall(ActivityEvent, 'exists')[1], { user: 'u1', type: 'legacy.xp' });

  const none = fakeModel({ result: null });
  assert.equal(await build({ ActivityEvent: none }).hasLegacyImport({ userId: 'u1' }), false);
});

test('usersWithLegacyImport lists users whose history already lives in the journal', async () => {
  const ActivityEvent = fakeModel({ result: ['u3'] });
  assert.deepEqual(await build({ ActivityEvent }).usersWithLegacyImport(), ['u3']);
  assert.deepEqual(lastCall(ActivityEvent, 'distinct').slice(1), ['user', { type: 'legacy.xp' }]);
});

test('topByTotalXp sorts by XP then streak and applies the limit', async () => {
  const UserStreak = fakeModel({ result: [{ user: 'u1' }] });
  await build({ UserStreak }).topByTotalXp({ limit: 5 });

  assert.deepEqual(lastCall(UserStreak, 'find')[1], {});
  assert.deepEqual(lastCall(UserStreak, 'sort')[1], { total_xp: -1, current_streak: -1, _id: 1 });
  assert.deepEqual(lastCall(UserStreak, 'limit')[1], 5);
});

test('countRankedAbove counts with the same order the list uses', async () => {
  const UserStreak = fakeModel({ result: 2 });
  const above = await build({ UserStreak }).countRankedAbove({
    totalXp: 30,
    currentStreak: 4,
    id: 's5',
  });

  assert.equal(above, 2);
  // Cả khoá phụ `_id` cũng phải có mặt: hai người bằng điểm và bằng chuỗi vẫn
  // đứng theo thứ tự `_id` trong danh sách, nên hạng đếm được phải theo đúng thế.
  assert.deepEqual(lastCall(UserStreak, 'countDocuments')[1], {
    $or: [
      { total_xp: { $gt: 30 } },
      { total_xp: 30, current_streak: { $gt: 4 } },
      { total_xp: 30, current_streak: 4, _id: { $lt: 's5' } },
    ],
  });
});

test('sumXpByUserBetween groups XP events per user over a Vietnamese day range', async () => {
  const ActivityEvent = fakeModel({ result: [{ _id: 'u1', total: 12 }] });
  const rows = await build({ ActivityEvent }).sumXpByUserBetween({
    fromDay: '2026-09-13',
    toDay: '2026-09-19',
  });

  assert.deepEqual(rows, [{ _id: 'u1', total: 12 }]);
  const [, pipeline] = lastCall(ActivityEvent, 'aggregate');
  assert.deepEqual(pipeline, [
    { $match: { day_key: { $gte: '2026-09-13', $lte: '2026-09-19' }, xp_delta: { $ne: 0 } } },
    { $group: { _id: '$user', total: { $sum: '$xp_delta' } } },
  ]);
});

test('sumLegacyXpByUserSince reads the legacy array and skips migrated users', async () => {
  const UserStreak = fakeModel({ result: [{ _id: 'u2', total: 20 }] });
  const since = new Date('2026-08-20T17:00:00.000Z');
  await build({ UserStreak }).sumLegacyXpByUserSince({ since, excludeUserIds: ['u3'] });

  const [, pipeline] = lastCall(UserStreak, 'aggregate');
  assert.deepEqual(pipeline, [
    { $match: { user: { $nin: ['u3'] } } },
    { $unwind: '$xp_history' },
    { $match: { 'xp_history.earned_at': { $gte: since } } },
    { $group: { _id: '$user', total: { $sum: '$xp_history.amount' } } },
  ]);
});

test('findSummaries and findUsersByIds read only what the board shows', async () => {
  const UserStreak = fakeModel({ result: [{ user: 'u1' }] });
  const User = fakeModel({ result: [{ _id: 'u1' }] });
  const repository = build({ UserStreak, User });

  await repository.findSummaries({ userIds: ['u1'] });
  assert.deepEqual(lastCall(UserStreak, 'find')[1], { user: { $in: ['u1'] } });

  await repository.findUsersByIds(['u1']);
  assert.deepEqual(lastCall(User, 'find')[1], { _id: { $in: ['u1'] } });
  // Không bao giờ trả mật khẩu hay email đầy đủ của người khác ra bảng xếp hạng.
  assert.equal(lastCall(User, 'select')[1], 'TenDangNhap HoTen AnhDaiDien');
});

test('findDay reads exactly one calendar day of one user', async () => {
  const StreakDay = fakeModel({ result: { day_key: '2026-09-19', direct_xp: 6 } });
  const day = await build({ StreakDay }).findDay({ userId: 'u1', dayKey: '2026-09-19' });

  assert.deepEqual(day, { day_key: '2026-09-19', direct_xp: 6 });
  assert.deepEqual(lastCall(StreakDay, 'findOne')[1], { user: 'u1', day_key: '2026-09-19' });
});
