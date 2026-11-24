import assert from 'node:assert/strict';
import test from 'node:test';
import {
  POLICY_VERSION,
  STREAK_MILESTONES,
  MILESTONE_REWARD_TYPE,
  ACHIEVEMENT_REWARD_TYPE,
  ACTIVITY_TYPES,
  DAILY_GOAL_OPTIONS,
  DEFAULT_DAILY_GOAL,
  DEFAULT_REMINDER_TIME,
  FREEZE_GIFT_TYPE,
  REMINDER_WINDOW,
  xpFor,
  countsAsStudy,
  milestonesCrossed,
  isActivityType,
  rewardFor,
  sourceCapFor,
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

test('an achievement unlock takes its XP from server-side achievement config', () => {
  assert.equal(countsAsStudy(ACHIEVEMENT_REWARD_TYPE), false);
  assert.equal(xpFor(ACHIEVEMENT_REWARD_TYPE, { configuredXp: 50 }), 50);
  // Huy hiệu không cấu hình thưởng: vẫn ghi event để chống cấp lại, 0 XP.
  assert.equal(xpFor(ACHIEVEMENT_REWARD_TYPE), 0);
});

test('a streak milestone is a zero-XP marker, the badge carries the reward', () => {
  // Một mốc chỉ một khoản thưởng: XP của mốc 7 ngày nằm ở huy hiệu streak.
  assert.equal(countsAsStudy(MILESTONE_REWARD_TYPE), false);
  assert.equal(xpFor(MILESTONE_REWARD_TYPE, { configuredXp: 50 }), 0);
});

test('a malformed achievement config is rejected instead of being written', () => {
  for (const bad of [-1, 1.5, Number.NaN, '50', 10 ** 9]) {
    assert.throws(
      () => xpFor(ACHIEVEMENT_REWARD_TYPE, { configuredXp: bad }),
      (error) => error.status === 400,
      `configuredXp=${String(bad)} phải bị chặn`,
    );
  }
});

// --- Trần XP theo từng bài tập / đề thi (mục 18) ------------------------------

test('an exercise and a JLPT exam each have a lifetime XP cap; other activities do not', () => {
  assert.equal(sourceCapFor('exercise.submit'), 10, 'mức cao nhất của bài tập');
  assert.equal(sourceCapFor('jlpt.submit'), 20);
  // Bài học đã chống trùng bằng khoá theo bài, thẻ SRS bằng khoá theo lịch:
  // không cần trần theo nguồn.
  for (const type of ['srs.review', 'lesson.progress', 'lesson.complete', 'login']) {
    assert.equal(sourceCapFor(type), null, type);
  }
  assert.throws(() => sourceCapFor('exercise.retry'), (error) => error.status === 400);
});

test('exercise retries pay only what is still missing, so repeating never farms XP', () => {
  const attempt = (passed, awardedBefore) => rewardFor('exercise.submit', { passed }, { awardedBefore });

  assert.deepEqual(attempt(false, 0), { xp: 5, remaining: 5 }, 'lần đầu chưa đạt');
  assert.deepEqual(attempt(false, 5), { xp: 0, remaining: 5 }, 'chưa đạt lần nữa');
  assert.deepEqual(attempt(true, 5), { xp: 5, remaining: 0 }, 'làm đạt sau đó: bù phần còn thiếu');
  assert.deepEqual(attempt(true, 10), { xp: 0, remaining: 0 }, 'đã đủ rồi làm lại');
  assert.deepEqual(attempt(true, 0), { xp: 10, remaining: 0 }, 'đạt ngay lần đầu');
  assert.deepEqual(attempt(false, 10), { xp: 0, remaining: 0 }, 'đã đạt rồi làm kém đi');
});

test('a JLPT exam pays its 20 XP once, pass or fail', () => {
  assert.deepEqual(rewardFor('jlpt.submit', { passed: false }), { xp: 20, remaining: 0 });
  assert.deepEqual(rewardFor('jlpt.submit', { passed: true }, { awardedBefore: 20 }), { xp: 0, remaining: 0 });
});

test('XP farmed before the cap existed is never taken back nor topped up', () => {
  // Người đã cày 60 XP từ một bài trước khi có luật: không trừ, không cộng thêm.
  assert.deepEqual(rewardFor('exercise.submit', { passed: true }, { awardedBefore: 60 }), { xp: 0, remaining: 0 });
});

test('activities without a cap keep their table XP and report no remainder', () => {
  assert.deepEqual(rewardFor('srs.review'), { xp: 2, remaining: null });
  assert.deepEqual(rewardFor('lesson.complete', undefined, { awardedBefore: 999 }), { xp: 20, remaining: null });
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

// --- Phần B ------------------------------------------------------------------

test('a freeze gift is a non-study event worth no XP', () => {
  assert.equal(FREEZE_GIFT_TYPE, 'streak.freeze_gift');
  assert.equal(xpFor(FREEZE_GIFT_TYPE), 0);
  assert.equal(countsAsStudy(FREEZE_GIFT_TYPE), false);
  // Khoá quà băng tách khỏi khoá mốc chuỗi (spec §5.2).
  assert.notEqual(FREEZE_GIFT_TYPE, MILESTONE_REWARD_TYPE);
});

test('daily goal choices and reminder window are the ones the spec settled', () => {
  assert.deepEqual([...DAILY_GOAL_OPTIONS], [10, 20, 30, 50]);
  assert.equal(DEFAULT_DAILY_GOAL, 20);
  assert.ok(DAILY_GOAL_OPTIONS.includes(DEFAULT_DAILY_GOAL));
  assert.deepEqual({ ...REMINDER_WINDOW }, { start: '08:00', end: '21:59' });
  assert.equal(DEFAULT_REMINDER_TIME, '20:00');
  assert.ok(Object.isFrozen(DAILY_GOAL_OPTIONS));
  assert.ok(Object.isFrozen(REMINDER_WINDOW));
});
