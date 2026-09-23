import assert from 'node:assert/strict';
import test from 'node:test';

import Achievement from '../model/Achievement.js';
import { ACHIEVEMENTS } from '../scripts/achievement-catalog.js';
import { metricOf } from '../src/modules/achievements/achievement-rules.js';
import { STREAK_MILESTONES } from '../src/modules/streaks/streak-policy.js';

test('every badge has a criterion the server can verify on its own', () => {
  for (const badge of ACHIEVEMENTS) {
    assert.notEqual(metricOf(badge), null, badge.name);
    assert.equal(new Achievement(badge).validateSync(), undefined, badge.name);
  }
});

test('names are unique because they are the upsert key', () => {
  const names = ACHIEVEMENTS.map((badge) => badge.name);
  assert.equal(new Set(names).size, names.length);
});

test('each category is a ladder that starts easy and only goes up', () => {
  const byCategory = Map.groupBy(ACHIEVEMENTS, (badge) => badge.category);
  for (const [category, badges] of byCategory) {
    const goals = badges.map((badge) => badge.requirement_value);
    assert.deepEqual(goals, [...goals].sort((a, b) => a - b), category);
    assert.equal(badges[0].rarity, 'common', `${category} bắt đầu bằng huy hiệu phổ thông`);
  }
});

test('the streak badges cover every milestone of the streak policy', () => {
  const streakGoals = ACHIEVEMENTS.filter((badge) => badge.category === 'streak').map((b) => b.requirement_value);
  for (const milestone of STREAK_MILESTONES) assert.ok(streakGoals.includes(milestone), `${milestone} ngày`);
});

test('badges of the old seed keep their names so their ids survive the upsert', () => {
  const names = new Set(ACHIEVEMENTS.map((badge) => badge.name));
  for (const legacy of ['First Step', 'Word Beginner', 'Kanji Starter', 'Grammar Novice', 'Lesson Beginner', 'Practice Newbie', 'Point Starter', 'XP Legend']) {
    assert.ok(names.has(legacy), legacy);
  }
});
