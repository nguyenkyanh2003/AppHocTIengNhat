import assert from 'node:assert/strict';
import test from 'node:test';

import { createStreakSettingsRepository } from '../src/modules/streaks/streak-settings.repository.js';
import { createStreakSettingsService } from '../src/modules/streaks/streak-settings.service.js';

const USER = 'u1';
// 10:00 ngày 25/9 giờ Việt Nam.
const MORNING = new Date('2026-09-25T03:00:00.000Z');

/**
 * Repository giả mô phỏng đúng hai thứ service dựa vào: unique `user` và CAS
 * trên `revision`. `loseCas` cho số lần "thiết bị khác vừa lưu" trước mỗi CAS.
 */
const fakeRepository = ({ doc = null, loseCas = 0 } = {}) => {
  let stored = doc ? { ...doc } : null;
  let lossesLeft = loseCas;
  const calls = [];
  return {
    calls,
    get stored() {
      return stored;
    },
    async findByUser({ userId }) {
      calls.push(['findByUser', userId]);
      return stored ? { ...stored } : null;
    },
    async create({ userId, fields }) {
      calls.push(['create', { userId, fields }]);
      if (stored) return null;
      stored = { user: userId, revision: 1, ...fields };
      return { ...stored };
    },
    async cas({ userId, expectedRevision, patch }) {
      calls.push(['cas', { userId, expectedRevision, patch }]);
      if (lossesLeft > 0) {
        lossesLeft -= 1;
        stored = { ...stored, revision: stored.revision + 1 };
        return null;
      }
      if (!stored || stored.revision !== expectedRevision) return null;
      stored = { ...stored, ...patch, revision: stored.revision + 1 };
      return { ...stored };
    },
  };
};

const build = (repository, now = MORNING) =>
  createStreakSettingsService({ repository, clock: () => now });

const names = (repository) => repository.calls.map(([name]) => name);

// --- đọc -----------------------------------------------------------------------

test('đọc cài đặt của người chưa lưu gì trả mặc định và không ghi', async () => {
  const repository = fakeRepository();
  const view = await build(repository).get(USER);

  assert.equal(view.daily_goal_xp, 20);
  assert.equal(view.reminder_enabled, false);
  assert.equal(view.reminder_time, '20:00');
  assert.deepEqual(names(repository), ['findByUser']);
});

// --- ghi -----------------------------------------------------------------------

test('lưu lần đầu tạo bản cài đặt với revision 1', async () => {
  const repository = fakeRepository();
  const view = await build(repository).update(USER, { reminder_enabled: true, reminder_time: '19:30' });

  assert.equal(view.reminder_enabled, true);
  assert.equal(view.reminder_time, '19:30');
  assert.equal(view.revision, 1);
  assert.deepEqual(repository.stored.reminder_time, '19:30');
});

test('đổi mục tiêu chỉ hiệu lực từ ngày mai, hôm nay vẫn giữ mức cũ', async () => {
  const repository = fakeRepository();
  const view = await build(repository).update(USER, { daily_goal_xp: 30 });

  assert.equal(view.daily_goal_xp, 20);
  assert.equal(view.next_daily_goal_xp, 30);
  assert.equal(view.next_goal_from, '2026-09-26');
});

test('ranh giới ngày theo giờ Việt Nam của server lúc lưu', async () => {
  // 23:59:59 ngày 25 → hiệu lực ngày 26; 00:00 ngày 26 → hiệu lực ngày 27.
  const beforeMidnight = await build(fakeRepository(), new Date('2026-09-25T16:59:59.000Z')).update(USER, {
    daily_goal_xp: 50,
  });
  assert.equal(beforeMidnight.next_goal_from, '2026-09-26');

  const atMidnight = await build(fakeRepository(), new Date('2026-09-25T17:00:00.000Z')).update(USER, {
    daily_goal_xp: 50,
  });
  assert.equal(atMidnight.next_goal_from, '2026-09-27');
});

test('đổi giờ nhắc không đụng tới mục tiêu và ngược lại', async () => {
  const repository = fakeRepository({
    doc: { user: USER, revision: 4, daily_goal_xp: 30, previous_goal_xp: null, goal_effective_from: null },
  });
  await build(repository).update(USER, { reminder_time: '08:00' });

  const [, cas] = repository.calls.find(([name]) => name === 'cas');
  assert.deepEqual(cas.patch, { reminder_time: '08:00' });
  assert.equal(cas.expectedRevision, 4);
  assert.equal(repository.stored.daily_goal_xp, 30);
});

test('thua CAS vì thiết bị khác vừa lưu thì đọc lại và thử lại', async () => {
  const repository = fakeRepository({ doc: { user: USER, revision: 1 }, loseCas: 2 });
  const view = await build(repository).update(USER, { reminder_enabled: true });

  assert.equal(view.reminder_enabled, true);
  assert.equal(names(repository).filter((name) => name === 'cas').length, 3);
  assert.equal(names(repository).filter((name) => name === 'findByUser').length, 3);
});

test('hai lần lưu đầu tiên chạy song song: bên thua tạo mới thì chuyển sang CAS', async () => {
  const repository = fakeRepository();
  const originalFind = repository.findByUser;
  let firstRead = true;
  // Lần đọc đầu thấy "chưa có", nhưng một request khác tạo xong ngay sau đó.
  repository.findByUser = async (args) => {
    if (firstRead) {
      firstRead = false;
      await repository.create({ userId: USER, fields: { reminder_enabled: false } });
      return null;
    }
    return originalFind(args);
  };

  const view = await build(repository).update(USER, { reminder_enabled: true });
  assert.equal(view.reminder_enabled, true);
});

test('thua CAS quá 5 lần thì trả 409 để client thử lại', async () => {
  const repository = fakeRepository({ doc: { user: USER, revision: 1 }, loseCas: 99 });

  await assert.rejects(build(repository).update(USER, { reminder_enabled: true }), (error) => {
    assert.equal(error.status, 409);
    assert.equal(error.code, 'STREAK_SETTINGS_CONFLICT');
    return true;
  });
});

test('giá trị sai bị chặn ở service dù đã qua lớp validate', async () => {
  const service = build(fakeRepository());
  for (const changes of [{ daily_goal_xp: 25 }, { reminder_time: '22:30' }, { reminder_enabled: 'yes' }, {}]) {
    await assert.rejects(service.update(USER, changes), (error) => error.status === 400, JSON.stringify(changes));
  }
});

// --- repository ----------------------------------------------------------------

const fakeModel = ({ result = null, createError = null } = {}) => {
  const calls = [];
  return {
    calls,
    findOne: (filter) => {
      calls.push(['findOne', filter]);
      return { lean: async () => result };
    },
    create: async (docs) => {
      calls.push(['create', docs]);
      if (createError) throw createError;
      return docs.map((doc) => ({ toObject: () => ({ _id: 's1', ...doc }) }));
    },
    findOneAndUpdate: async (filter, update, options) => {
      calls.push(['findOneAndUpdate', filter, update, options]);
      return result;
    },
  };
};

test('repository tạo bản đầu với revision 1, trùng user thì trả null', async () => {
  const model = fakeModel();
  const saved = await createStreakSettingsRepository({ StreakSettings: model }).create({
    userId: USER,
    fields: { reminder_enabled: true },
  });
  assert.deepEqual(model.calls[0], ['create', [{ user: USER, reminder_enabled: true, revision: 1 }]]);
  assert.equal(saved.revision, 1);

  const duplicate = Object.assign(new Error('E11000'), { code: 11000 });
  const raced = createStreakSettingsRepository({ StreakSettings: fakeModel({ createError: duplicate }) });
  assert.equal(await raced.create({ userId: USER, fields: {} }), null);

  const broken = createStreakSettingsRepository({ StreakSettings: fakeModel({ createError: new Error('mất kết nối') }) });
  await assert.rejects(broken.create({ userId: USER, fields: {} }), /mất kết nối/);
});

test('repository CAS theo revision và tăng revision trong cùng lệnh ghi', async () => {
  const model = fakeModel({ result: { revision: 5 } });
  await createStreakSettingsRepository({ StreakSettings: model }).cas({
    userId: USER,
    expectedRevision: 4,
    patch: { reminder_time: '08:00' },
  });

  const [, filter, update, options] = model.calls[0];
  assert.deepEqual(filter, { user: USER, revision: 4 });
  assert.deepEqual(update, { $set: { reminder_time: '08:00' }, $inc: { revision: 1 } });
  assert.equal(options.new, true);
  assert.equal(options.runValidators, true);
  assert.equal(options.lean, true);
});
