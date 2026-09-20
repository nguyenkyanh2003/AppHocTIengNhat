import assert from 'node:assert/strict';
import test from 'node:test';

import { createUserRepository } from '../src/modules/users/user.repository.js';

/**
 * Model streak giả chỉ có `findOne`. Không có `create`, `save` hay
 * `findOneAndUpdate`: nếu đường đăng nhập còn ghi streak thì test nổ ngay.
 */
const readOnlyStreakModel = (doc) => ({
  findOne: (filter) => ({
    lean: async () => {
      readOnlyStreakModel.lastFilter = filter;
      return doc;
    },
  }),
});

const NOW = new Date('2026-09-19T03:00:00.000Z'); // 10:00 giờ Việt Nam.

test('tóm tắt streak lúc đăng nhập của user chưa có streak là 0 và không tạo gì', async () => {
  const repository = createUserRepository({ UserStreak: readOnlyStreakModel(null) });
  const summary = await repository.readStreakSummary('u1', NOW);

  assert.deepEqual(summary, {
    current: 0,
    longest: 0,
    total_xp: 0,
    is_new_day: false,
    streak_broken: false,
  });
  assert.deepEqual(readOnlyStreakModel.lastFilter, { user: 'u1' });
});

test('chuỗi còn hiệu lực được giữ, đăng nhập không làm nó dài thêm', async () => {
  const repository = createUserRepository({
    UserStreak: readOnlyStreakModel({
      current_streak: 4,
      longest_streak: 9,
      total_xp: 120,
      last_activity_day: '2026-09-18',
    }),
  });
  const summary = await repository.readStreakSummary('u1', NOW);

  assert.equal(summary.current, 4);
  assert.equal(summary.longest, 9);
  assert.equal(summary.total_xp, 120);
  assert.equal(summary.is_new_day, false);
  assert.equal(summary.streak_broken, false);
});

test('chuỗi đã đứt hiển thị 0 nhưng không bị ghi đè lúc đăng nhập', async () => {
  const repository = createUserRepository({
    UserStreak: readOnlyStreakModel({
      current_streak: 4,
      longest_streak: 9,
      total_xp: 120,
      last_activity_day: '2026-09-10',
    }),
  });
  const summary = await repository.readStreakSummary('u1', NOW);

  assert.equal(summary.current, 0);
  assert.equal(summary.streak_broken, true);
});
