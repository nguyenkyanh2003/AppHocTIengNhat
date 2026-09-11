import assert from 'node:assert/strict';
import test from 'node:test';
import {
  POLICY_VERSION,
  STREAK_MILESTONES,
  MILESTONE_REWARD_TYPE,
  ACTIVITY_TYPES,
  xpFor,
  countsAsStudy,
  milestonesCrossed,
  isActivityType,
} from '../src/modules/streaks/streak-policy.js';

test('every row of the XP table is exactly what the spec says', () => {
  assert.equal(xpFor('srs.review'), 2);
  assert.equal(xpFor('lesson.progress'), 2);
  assert.equal(xpFor('lesson.complete'), 20);
  assert.equal(xpFor('jlpt.submit'), 20);
});

test('exercise XP follows the server grade, not a flat number', () => {
  assert.equal(xpFor('exercise.submit', { passed: true }), 10);
  assert.equal(xpFor('exercise.submit', { passed: false }), 5);
  // Không có kết quả chấm nghĩa là chưa chấm xong — không được đoán là đạt.
  assert.equal(xpFor('exercise.submit'), 5);
});

test('an outcome cannot move the number for types the table fixes', () => {
  // Đây là ràng buộc chính của module: `outcome` đến từ tầng nghiệp vụ và có
  // thể mang theo dữ liệu client gửi lên. Chỉ `exercise.submit` được phép đọc
  // nó, và chỉ đọc đúng cờ `passed` do server chấm.
  const hostile = { passed: true, amount: 9999, xp: 9999, isPassed: true, score: 100 };
  assert.equal(xpFor('srs.review', hostile), 2);
  assert.equal(xpFor('lesson.progress', hostile), 2);
  assert.equal(xpFor('lesson.complete', hostile), 20);
  assert.equal(xpFor('jlpt.submit', hostile), 20);
  assert.equal(xpFor('exercise.submit', hostile), 10);
});

test('actions that are not study earn nothing and do not count as study', () => {
  for (const type of ['login', 'lesson.open', 'vocabulary.mark', 'srs.reset', 'srs.delete', 'srs.skip']) {
    assert.equal(xpFor(type), 0, `${type} phải là 0 XP`);
    assert.equal(countsAsStudy(type), false, `${type} không phải hoạt động học`);
  }
});

test('study types count as study', () => {
  for (const type of ['srs.review', 'lesson.progress', 'lesson.complete', 'exercise.submit', 'jlpt.submit']) {
    assert.equal(countsAsStudy(type), true, `${type} phải tính là ngày học`);
  }
});

test('an unknown type is a 400, never a silent zero', () => {
  assert.throws(() => xpFor('lesson.finish'), (error) => error.status === 400);
  assert.throws(() => countsAsStudy('lesson.finish'), (error) => error.status === 400);
});

test('a milestone reward takes its XP from server-side achievement config', () => {
  assert.equal(countsAsStudy(MILESTONE_REWARD_TYPE), false);
  assert.equal(xpFor(MILESTONE_REWARD_TYPE, { configuredXp: 50 }), 50);
  // Chưa cấu hình thưởng cho mốc đó: vẫn ghi event để chống cấp lại, 0 XP.
  assert.equal(xpFor(MILESTONE_REWARD_TYPE), 0);
});

test('a malformed achievement config is rejected instead of being written', () => {
  for (const bad of [-1, 1.5, Number.NaN, '50', 10 ** 9]) {
    assert.throws(
      () => xpFor(MILESTONE_REWARD_TYPE, { configuredXp: bad }),
      (error) => error.status === 400,
      `configuredXp=${String(bad)} phải bị chặn`,
    );
  }
});

test('the milestone ladder is the single one from the spec', () => {
  assert.deepEqual(STREAK_MILESTONES, [7, 14, 30, 50, 100, 365]);
  assert.throws(() => STREAK_MILESTONES.push(3), TypeError);
});

test('only milestones actually crossed by this activity are returned', () => {
  assert.deepEqual(milestonesCrossed(6, 7), [7]);
  assert.deepEqual(milestonesCrossed(7, 8), []);
  // Chuỗi đứt rồi học lại: không được phát lại mốc đã qua.
  assert.deepEqual(milestonesCrossed(30, 1), []);
  // Một lần ghi nhảy nhiều mốc (dữ liệu trễ, migration) trả về cả hai.
  assert.deepEqual(milestonesCrossed(6, 14), [7, 14]);
  assert.deepEqual(milestonesCrossed(364, 365), [365]);
  assert.deepEqual(milestonesCrossed(365, 366), []);
});

test('the policy version is a non-empty string events can be stamped with', () => {
  assert.equal(typeof POLICY_VERSION, 'string');
  assert.ok(POLICY_VERSION.length > 0);
});

test('the type list is closed and really frozen', () => {
  assert.throws(() => ACTIVITY_TYPES.push('anything'), TypeError);
  assert.equal(isActivityType('srs.review'), true);
  assert.equal(isActivityType('streak.bonus'), false);
  // Không lọt khoá kế thừa từ Object.prototype.
  assert.equal(isActivityType('toString'), false);
});
