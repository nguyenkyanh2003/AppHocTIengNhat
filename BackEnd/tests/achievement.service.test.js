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
  assert.equal(metricOf({ category: 'grammar', requirement_type: 'count' }), 'passedPatternExercises');
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

const fakeRepository = ({
  definitions = [],
  completed = [],
  counts = {},
  earned = [],
  unlockedCounts = [],
  earnedByCategory = [],
} = {}) => {
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
    findAll: async () => definitions,
    countActive: async () => definitions.length,
    countCompletedByAchievement: async () => unlockedCounts,
    countActiveByCategory: async () => [],
    countCompletedByCategory: async () => earnedByCategory,
    countLearnedVocabulary: counter('countLearnedVocabulary'),
    countLearnedKanji: counter('countLearnedKanji'),
    countPassedPatternExercises: counter('countPassedPatternExercises'),
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

  assert.deepEqual(unlocked.map(({ id, xpReward, progress }) => ({ id, xpReward, progress })), [
    { id: 'words-50', xpReward: 100, progress: 50 },
    { id: 'streak-7', xpReward: 100, progress: 7 },
  ]);
  // Đếm trong cùng transaction với hoạt động vừa ghi.
  assert.deepEqual(repository.calls.find(([name]) => name === 'countLearnedVocabulary')[1], {
    userId: 'u1',
    session: 'sess',
  });
});

test('an unlocked badge carries what the learner is told: Vietnamese name and criterion, icon, rarity', async () => {
  const vietnamese = definition({
    name: 'First Words',
    name_vi: 'Những Từ Đầu Tiên',
    description: 'Learn 10 vocabulary words',
    description_vi: 'Học 10 từ vựng',
    icon: '📚',
    rarity: 'rare',
    category: 'vocabulary',
    requirement_value: 10,
  });
  const englishOnly = definition({
    name: 'Lesson Starter',
    description: 'Complete 1 lesson',
    icon: '📖',
    category: 'lesson',
    requirement_value: 1,
  });
  const repository = fakeRepository({
    definitions: [vietnamese, englishOnly],
    counts: { countLearnedVocabulary: 10, countCompletedLessons: 1 },
  });

  const unlocked = await createAchievementService({ repository }).findUnlocked({ userId: 'u1', snapshot: {} });

  assert.deepEqual(
    unlocked.map(({ name, description, icon, rarity }) => ({ name, description, icon, rarity })),
    [
      { name: 'Những Từ Đầu Tiên', description: 'Học 10 từ vựng', icon: '📚', rarity: 'rare' },
      { name: 'Lesson Starter', description: 'Complete 1 lesson', icon: '📖', rarity: 'common' },
    ],
  );
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

test('a progress row that was never completed stays locked with server-counted progress', async () => {
  // Dòng tiến độ cũ do client khai: số trong đó không đáng tin và chưa phải huy hiệu đã đạt.
  const staleRow = { _id: 'ua1', achievement: WORDS_50, is_completed: false, progress: 49 };
  const service = createAchievementService({
    repository: fakeRepository({
      definitions: [WORDS_50],
      earned: [staleRow],
      counts: { countLearnedVocabulary: 12 },
    }),
    streakSnapshot: async () => ({ currentStreak: 0, totalXp: 0 }),
  });

  const view = await service.myAchievements('u1');

  assert.deepEqual(view.earned, []);
  assert.deepEqual(view.locked.map((row) => row.progress), [12]);
  assert.equal(view.completed, 0);
});

test('completed and locked add up to the active total after a badge is retired', async () => {
  const retired = definition({ name: 'retired', category: 'kanji', requirement_value: 1, is_active: false });
  const service = createAchievementService({
    repository: fakeRepository({
      definitions: [WORDS_50, LESSONS_5],
      earned: [
        { _id: 'ua1', achievement: retired, is_completed: true, progress: 1 },
        { _id: 'ua2', achievement: LESSONS_5, is_completed: true, progress: 5 },
      ],
    }),
    streakSnapshot: async () => ({ currentStreak: 0, totalXp: 0 }),
  });

  const view = await service.myAchievements('u1');

  // Huy hiệu đã ngừng vẫn ở trong danh sách đã đạt nhưng không tính vào tỉ lệ.
  assert.equal(view.earned.length, 2);
  assert.equal(view.total, 2);
  assert.equal(view.completed, 1);
  assert.equal(view.completed + view.locked.length, view.total);
});

test('stats count only active badges and report the rate as a number', async () => {
  const service = createAchievementService({
    repository: fakeRepository({
      definitions: [WORDS_50, LESSONS_5, STREAK_7],
      earnedByCategory: [{ _id: 'lesson', count: 1 }],
    }),
  });

  const stats = await service.stats('u1');

  assert.equal(stats.total_achievements, 3);
  assert.equal(stats.earned_achievements, 1);
  assert.equal(stats.completion_rate, 33.3);
});

test('stats with no badges report a zero rate', async () => {
  const stats = await createAchievementService({ repository: fakeRepository() }).stats('u1');

  assert.equal(stats.completion_rate, 0);
});

test('the admin list says how many learners unlocked each badge', async () => {
  const service = createAchievementService({
    repository: fakeRepository({
      definitions: [WORDS_50, LESSONS_5],
      unlockedCounts: [{ _id: 'lessons-5', count: 4 }],
    }),
  });

  const rows = await service.listAll();

  assert.deepEqual(rows.map((row) => [row.name, row.unlocked]), [['words-50', 0], ['lessons-5', 4]]);
});

test('grammar badges unlock from passed pattern exercises, inside the same transaction', async () => {
  const grammar5 = definition({ name: 'grammar-5', category: 'grammar', requirement_value: 5 });
  const repository = fakeRepository({
    definitions: [grammar5],
    counts: { countPassedPatternExercises: 5 },
  });

  const unlocked = await createAchievementService({ repository }).findUnlocked({
    userId: 'u1',
    snapshot: {},
    session: 's',
  });

  assert.deepEqual(unlocked.map((row) => [row.id, row.progress]), [['grammar-5', 5]]);
  const call = repository.calls.find(([name]) => name === 'countPassedPatternExercises');
  assert.deepEqual(call[1], { userId: 'u1', session: 's' });
});

test('every countable category has a counter, so the check never crashes mid-transaction', async () => {
  const everyCategory = ['vocabulary', 'kanji', 'grammar', 'lesson', 'practice'].map((category) =>
    definition({ name: category, category, requirement_value: 1 }),
  );
  const service = createAchievementService({ repository: fakeRepository({ definitions: everyCategory }) });

  assert.deepEqual(await service.findUnlocked({ userId: 'u1', snapshot: {}, session: 's' }), []);
});

test('updating or deleting a missing definition is 404', async () => {
  const service = createAchievementService({ repository: fakeRepository() });

  await assert.rejects(() => service.update('x', { xp_reward: 1 }), { status: 404 });
  await assert.rejects(() => service.remove('x'), { status: 404 });
});
