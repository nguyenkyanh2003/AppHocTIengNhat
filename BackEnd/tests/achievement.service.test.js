import assert from 'node:assert/strict';
import test from 'node:test';

import { isUnlocked, metricOf, progressOf } from '../src/modules/achievements/achievement-rules.js';
import { createAchievementService } from '../src/modules/achievements/achievement.service.js';

const definition = (over) => ({
  _id: over.name,
  is_active: true,
  xp_reward: 100,
  requirement_type: 'count',
  ...over,
});

const WORDS_50 = definition({ name: 'words-50', category: 'vocabulary', requirement_value: 50 });
const LESSONS_5 = definition({ name: 'lessons-5', category: 'lesson', requirement_value: 5 });
const STREAK_7 = definition({ name: 'streak-7', category: 'streak', requirement_type: 'streak', requirement_value: 7 });
const XP_500 = definition({ name: 'xp-500', category: 'xp', requirement_type: 'xp', requirement_value: 500 });

// --- rules ------------------------------------------------------------------

test('every seeded category maps to a metric the server can count', () => {
  assert.equal(metricOf(WORDS_50), 'learnedVocabulary');
  assert.equal(metricOf({ category: 'kanji', requirement_type: 'count' }), 'learnedKanji');
  assert.equal(metricOf({ category: 'grammar', requirement_type: 'count' }), 'learnedGrammar');
  assert.equal(metricOf({ category: 'lesson', requirement_type: 'completion' }), 'completedLessons');
  assert.equal(metricOf({ category: 'practice', requirement_type: 'count' }), 'exerciseSubmissions');
  assert.equal(metricOf(STREAK_7), 'currentStreak');
  assert.equal(metricOf(XP_500), 'totalXp');
});

test('an unverifiable or broken definition is never unlocked', () => {
  assert.equal(isUnlocked({ category: 'social', requirement_type: 'count', requirement_value: 1 }, {}), false);
  assert.equal(isUnlocked({ ...WORDS_50, requirement_value: 0 }, { learnedVocabulary: 10 }), false);
  assert.equal(isUnlocked({ ...WORDS_50, requirement_value: 2.5 }, { learnedVocabulary: 10 }), false);
});

test('progress is capped at the goal', () => {
  assert.equal(progressOf(WORDS_50, { learnedVocabulary: 12 }), 12);
  assert.equal(progressOf(WORDS_50, { learnedVocabulary: 80 }), 50);
  assert.equal(progressOf(WORDS_50, {}), 0);
});

// --- service ----------------------------------------------------------------

const fakeRepository = ({ definitions = [], completed = [], counts = {}, earned = [] } = {}) => {
  const calls = [];
  const counter = (name) => async (args) => {
    calls.push([name, args]);
    return counts[name] ?? 0;
  };
  return {
    calls,
    findActive: async (args) => (calls.push(['findActive', args]), definitions),
    findCompletedAchievementIds: async () => new Set(completed),
    findUserAchievements: async () => earned,
    countLearnedVocabulary: counter('countLearnedVocabulary'),
    countLearnedKanji: counter('countLearnedKanji'),
    countLearnedGrammar: counter('countLearnedGrammar'),
    countCompletedLessons: counter('countCompletedLessons'),
    countExerciseSubmissions: counter('countExerciseSubmissions'),
    updateById: async () => null,
    deleteById: async () => null,
  };
};

const counted = (repository) => repository.calls.filter(([name]) => name.startsWith('count')).map(([name]) => name);

test('only definitions whose server-counted metric reaches the goal are unlocked', async () => {
  const repository = fakeRepository({
    definitions: [WORDS_50, LESSONS_5, STREAK_7, XP_500],
    counts: { countLearnedVocabulary: 50, countCompletedLessons: 4 },
  });
  const service = createAchievementService({ repository });

  const unlocked = await service.findUnlocked({
    userId: 'u1',
    snapshot: { currentStreak: 7, totalXp: 499 },
    session: 'sess',
  });

  assert.deepEqual(unlocked, [
    { id: 'words-50', xpReward: 100, progress: 50 },
    { id: 'streak-7', xpReward: 100, progress: 7 },
  ]);
  // Đếm trong cùng transaction với hoạt động vừa ghi.
  assert.deepEqual(repository.calls.find(([name]) => name === 'countLearnedVocabulary')[1], {
    userId: 'u1',
    session: 'sess',
  });
});

test('achievements already completed are not re-evaluated or counted for', async () => {
  const repository = fakeRepository({ definitions: [WORDS_50, STREAK_7], completed: ['words-50'] });
  const service = createAchievementService({ repository });

  const unlocked = await service.findUnlocked({
    userId: 'u1',
    snapshot: { currentStreak: 3, totalXp: 0 },
  });

  assert.deepEqual(unlocked, []);
  assert.deepEqual(counted(repository), []);
});

test('my achievements shows locked badges with real server progress', async () => {
  const earnedRow = { _id: 'ua1', achievement: STREAK_7, is_completed: true, progress: 7 };
  const repository = fakeRepository({
    definitions: [WORDS_50, STREAK_7, XP_500],
    earned: [earnedRow],
    counts: { countLearnedVocabulary: 12 },
  });
  const service = createAchievementService({
    repository,
    streakSnapshot: async () => ({ currentStreak: 2, totalXp: 130 }),
  });

  const view = await service.myAchievements('u1');

  assert.deepEqual(view.earned, [earnedRow]);
  assert.deepEqual(
    view.locked.map((row) => [row.achievement.name, row.progress, row.is_locked]),
    [
      ['words-50', 12, true],
      ['xp-500', 130, true],
    ],
  );
  assert.equal(view.total, 3);
  assert.equal(view.completed, 1);
});

test('updating or deleting a missing definition is 404', async () => {
  const service = createAchievementService({ repository: fakeRepository() });

  await assert.rejects(() => service.update('x', { xp_reward: 1 }), { status: 404 });
  await assert.rejects(() => service.remove('x'), { status: 404 });
});
