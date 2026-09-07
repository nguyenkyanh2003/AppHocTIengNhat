import assert from 'node:assert/strict';
import test from 'node:test';

import {
  BOX_INTERVAL_IN_DAYS,
  MAX_BOX,
  applyAnswer,
  initialProgress,
  isDue,
  nextBox,
  nextReviewDate,
  nextStreak,
} from '../src/modules/srs/srs-scheduling.js';

const NOW = new Date('2026-03-01T08:00:00.000Z');
const DAY = 24 * 60 * 60 * 1000;

test('trả lời đúng thì lên một box, tối đa MAX_BOX', () => {
  assert.equal(nextBox(1, true), 2);
  assert.equal(nextBox(4, true), 5);
  assert.equal(nextBox(MAX_BOX, true), MAX_BOX);
});

test('trả lời sai thì quay về box 1', () => {
  assert.equal(nextBox(5, false), 1);
  assert.equal(nextBox(2, false), 1);
});

test('box ngoài khoảng hợp lệ được kẹp lại trước khi tính', () => {
  assert.equal(nextBox(0, true), 2);
  assert.equal(nextBox(99, true), MAX_BOX);
  assert.equal(nextBox(undefined, false), 1);
});

test('ngày ôn tiếp theo đúng theo khoảng của box', () => {
  for (const [box, days] of Object.entries(BOX_INTERVAL_IN_DAYS)) {
    assert.equal(
      nextReviewDate(Number(box), NOW).getTime(),
      NOW.getTime() + days * DAY,
      `box ${box} phải cách ${days} ngày`,
    );
  }
});

test('streak tăng khi đúng và reset khi sai', () => {
  assert.equal(nextStreak(3, true), 4);
  assert.equal(nextStreak(3, false), 0);
  assert.equal(nextStreak(undefined, true), 1);
});

test('tiến độ ban đầu là box 1, ôn lại sau 1 ngày', () => {
  const progress = initialProgress(NOW);

  assert.equal(progress.box, 1);
  assert.equal(progress.streak, 0);
  assert.equal(progress.next_review.getTime(), NOW.getTime() + DAY);
});

test('applyAnswer gộp box, ngày ôn và streak trong một bước', () => {
  const correct = applyAnswer({ box: 2, streak: 1 }, true, NOW);
  assert.deepEqual(correct, {
    box: 3,
    next_review: new Date(NOW.getTime() + BOX_INTERVAL_IN_DAYS[3] * DAY),
    streak: 2,
  });

  const wrong = applyAnswer({ box: 4, streak: 6 }, false, NOW);
  assert.deepEqual(wrong, {
    box: 1,
    next_review: new Date(NOW.getTime() + BOX_INTERVAL_IN_DAYS[1] * DAY),
    streak: 0,
  });
});

test('isDue đúng ở mốc bằng và sau hạn', () => {
  assert.equal(isDue({ next_review: NOW }, NOW), true);
  assert.equal(isDue({ next_review: new Date(NOW.getTime() + 1) }, NOW), false);
  assert.equal(isDue({}, NOW), false);
});
