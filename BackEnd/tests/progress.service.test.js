import assert from 'node:assert/strict';
import test from 'node:test';

import { createProgressService } from '../src/modules/progress/progress.service.js';

const NOW = new Date('2026-11-04T03:00:00.000Z'); // 10:00 giờ Việt Nam.
const USER = 'u1';

/** Nửa đêm giờ Việt Nam của một ngày lịch. */
const vnMidnight = (key) => new Date(`${key}T00:00:00+07:00`);

const recorder = (calls) => (name, result) => async (args) => {
  calls.push([name, args]);
  return result;
};

const fakeRepository = (overrides = {}) => {
  const calls = [];
  const record = recorder(calls);
  return {
    calls,
    sumExerciseSeconds: record('sumExerciseSeconds', 0),
    findExerciseResultsBetween: record('findExerciseResultsBetween', []),
    findLessonsStudiedBetween: record('findLessonsStudiedBetween', []),
    lessonsByLevel: record('lessonsByLevel', []),
    exercisesByType: record('exercisesByType', []),
    countUsers: record('countUsers', 0),
    countUsersActiveSince: record('countUsersActiveSince', 0),
    countLessonsCompletedSince: record('countLessonsCompletedSince', 0),
    sumExamSecondsSince: record('sumExamSecondsSince', 0),
    dailyRegistrations: record('dailyRegistrations', []),
    dailyActiveUsers: record('dailyActiveUsers', []),
    dailyLessonsCompleted: record('dailyLessonsCompleted', []),
    dailyExamMinutes: record('dailyExamMinutes', []),
    levelDistribution: record('levelDistribution', []),
    ...overrides,
  };
};

const fakeCounters = (overrides = {}) => {
  const calls = [];
  const record = recorder(calls);
  return {
    calls,
    countLearnedVocabulary: record('countLearnedVocabulary', 0),
    countLearnedKanji: record('countLearnedKanji', 0),
    countExerciseSubmissions: record('countExerciseSubmissions', 0),
    countCompletedLessons: record('countCompletedLessons', 0),
    ...overrides,
  };
};

const fakeStreak = ({ summary = { current_streak: 0, total_xp: 0, level: 1 }, xp = [], days = [] } = {}) => ({
  summary: async () => summary,
  xpHistory: async () => xp,
  activityDates: async () => days,
});

const serviceWith = ({
  repository = fakeRepository(),
  lessonProgress = { findAllProgress: async () => [] },
  counters = fakeCounters(),
  streak = fakeStreak(),
  srs = { countCards: async () => 0 },
} = {}) =>
  createProgressService({ repository, lessonProgress, counters, streak, srs, clock: () => NOW });

test('tiến độ cá nhân đọc LessonProgress của đúng user và trả DTO kèm phần trăm', async () => {
  const studiedAt = new Date('2026-11-03T08:00:00.000Z');
  let askedFor = null;
  const lessonProgress = {
    findAllProgress: async (userId) => {
      askedFor = userId;
      return [
        {
          _id: 'p1',
          user: USER,
          lesson: { _id: 'l1', title: 'Chào hỏi', level: 'N5', order: 1 },
          completed_vocabularies: 3,
          total_vocabularies: 4,
          completed_grammars: 1,
          total_grammars: 1,
          completed_kanjis: 0,
          total_kanjis: 0,
          learned_vocabulary_ids: ['v1', 'v2', 'v3'],
          is_completed: false,
          last_studied_at: studiedAt,
          completion_reward_state: 'pending',
          __v: 0,
        },
      ];
    },
  };

  const items = await serviceWith({ lessonProgress }).listLessonProgress(USER);

  assert.equal(askedFor, USER);
  assert.deepEqual(items, [
    {
      _id: 'p1',
      lesson: { _id: 'l1', title: 'Chào hỏi', level: 'N5', order: 1 },
      completed_vocabularies: 3,
      total_vocabularies: 4,
      completed_grammars: 1,
      total_grammars: 1,
      completed_kanjis: 0,
      total_kanjis: 0,
      overall_progress: 80,
      is_completed: false,
      completed_at: null,
      last_studied_at: studiedAt,
    },
  ]);
});

test('bài học đã bị xoá vẫn giữ dòng tiến độ với lesson null, bài không có nội dung là 0%', async () => {
  const lessonProgress = { findAllProgress: async () => [{ _id: 'p2', lesson: null }] };

  const [item] = await serviceWith({ lessonProgress }).listLessonProgress(USER);

  assert.equal(item.lesson, null);
  assert.equal(item.overall_progress, 0);
  assert.equal(item.total_vocabularies, 0);
});

test('chưa học bài nào thì danh sách tiến độ rỗng chứ không lỗi', async () => {
  assert.deepEqual(await serviceWith().listLessonProgress(USER), []);
});

test('thống kê tổng quan đếm từ vựng/kanji theo cùng định nghĩa với huy hiệu', async () => {
  const counters = fakeCounters({
    countLearnedVocabulary: async ({ userId }) => (userId === USER ? 12 : -1),
    countLearnedKanji: async ({ userId }) => (userId === USER ? 5 : -1),
    countExerciseSubmissions: async ({ userId }) => (userId === USER ? 7 : -1),
    countCompletedLessons: async ({ userId }) => (userId === USER ? 2 : -1),
  });
  const repository = fakeRepository({
    sumExerciseSeconds: async (userId) => (userId === USER ? 900 : -1),
  });
  const streak = fakeStreak({ summary: { current_streak: 3, total_xp: 250, level: 3 } });
  const srs = {
    countCards: async ({ userId, itemType }) => (userId === USER && itemType === 'Kanji' ? 9 : -1),
  };

  const stats = await serviceWith({ counters, repository, streak, srs }).dashboardStats(USER);

  assert.deepEqual(stats, {
    vocabulary_learned: 12,
    kanji_learned: 5,
    kanji_reviewing: 9,
    exercises_completed: 7,
    lessons_completed: 2,
    total_study_time: 900,
    current_streak: 3,
    total_xp: 250,
    level: 3,
  });
});

test('timeline gom theo ngày giờ Việt Nam, có cả ngày chỉ kiếm XP, sắp xếp tăng dần', async () => {
  const repository = fakeRepository({
    findExerciseResultsBetween: async () => [
      // 01:30 sáng 04/11 giờ Việt Nam — theo UTC vẫn là 03/11.
      { completed_at: new Date('2026-11-03T18:30:00.000Z'), time_spent: 120 },
      { completed_at: new Date('2026-11-02T05:00:00.000Z'), time_spent: 60 },
    ],
    findLessonsStudiedBetween: async () => [
      { last_studied_at: new Date('2026-11-02T10:00:00.000Z') },
    ],
  });
  const streak = fakeStreak({
    xp: [
      { amount: 10, earned_at: new Date('2026-11-03T02:00:00.000Z') },
      { amount: 99, earned_at: new Date('2026-10-20T02:00:00.000Z') }, // ngoài tuần
    ],
  });

  const timeline = await serviceWith({ repository, streak }).timeline(USER, 'week');

  assert.deepEqual(timeline, [
    { date: '2026-11-02', exercises: 1, lessons: 1, time: 60, xp: 0 },
    { date: '2026-11-03', exercises: 0, lessons: 0, time: 0, xp: 10 },
    { date: '2026-11-04', exercises: 1, lessons: 0, time: 120, xp: 0 },
  ]);
});

test('timeline đọc đúng khoảng ngày lịch của từng kỳ, tính cả hôm nay', async () => {
  const cases = [
    ['week', '2026-10-29'],
    ['month', '2026-10-06'],
    ['year', '2025-11-05'],
  ];

  for (const [period, fromDay] of cases) {
    const repository = fakeRepository();
    await serviceWith({ repository }).timeline(USER, period);

    const range = { userId: USER, from: vnMidnight(fromDay), to: vnMidnight('2026-11-05') };
    assert.deepEqual(repository.calls, [
      ['findExerciseResultsBetween', range],
      ['findLessonsStudiedBetween', range],
    ], period);
  }
});

test('heatmap không cộng trùng ngày streak với hoạt động, ngày chỉ có trong lịch tính 1', async () => {
  const repository = fakeRepository({
    findExerciseResultsBetween: async () => [
      { completed_at: new Date('2026-11-04T01:00:00.000Z'), time_spent: 30 },
      { completed_at: new Date('2026-11-04T02:00:00.000Z'), time_spent: 45 },
    ],
    findLessonsStudiedBetween: async () => [
      { last_studied_at: new Date('2026-11-04T03:00:00.000Z') },
    ],
  });
  const streak = fakeStreak({
    days: [
      '2026-11-04',
      '2026-03-10',
      // Mốc thời gian cũ chưa migration: 00:30 ngày 01/01 giờ Việt Nam.
      '2025-12-31T17:30:00.000Z',
      '2025-06-01', // khác năm
    ],
  });

  const heatmap = await serviceWith({ repository, streak }).heatmap(USER);

  assert.deepEqual(heatmap, [
    { date: '2026-01-01', count: 1, time: 0 },
    { date: '2026-03-10', count: 1, time: 0 },
    { date: '2026-11-04', count: 3, time: 75 },
  ]);
});

test('heatmap đọc trọn năm lịch Việt Nam, mặc định là năm hiện tại', async () => {
  const current = fakeRepository();
  await serviceWith({ repository: current }).heatmap(USER);
  assert.deepEqual(current.calls[0], [
    'findExerciseResultsBetween',
    { userId: USER, from: vnMidnight('2026-01-01'), to: vnMidnight('2027-01-01') },
  ]);

  const past = fakeRepository();
  await serviceWith({ repository: past }).heatmap(USER, 2025);
  assert.deepEqual(past.calls[0], [
    'findExerciseResultsBetween',
    { userId: USER, from: vnMidnight('2025-01-01'), to: vnMidnight('2026-01-01') },
  ]);
});

test('breakdown giữ hình dạng client đang đọc và làm tròn điểm trung bình', async () => {
  const repository = fakeRepository({
    lessonsByLevel: async (userId) => [{ _id: 'N5', completed: 2, in_progress: 1, userId }],
    exercisesByType: async () => [{ _id: 'Từ vựng', count: 3, average_score: 73.3333333, passed: 2 }],
  });

  const breakdown = await serviceWith({ repository }).breakdown(USER);

  assert.deepEqual(breakdown, {
    lessons_by_level: [{ _id: 'N5', completed: 2, in_progress: 1, userId: USER }],
    exercises_by_type: [{ _id: 'Từ vựng', count: 3, average_score: 73.3, passed: 2 }],
  });
});

test('analytics admin dựng nhãn theo ngày Việt Nam và lấp ngày trống bằng 0', async () => {
  const repository = fakeRepository({
    countUsers: async () => 10,
    countUsersActiveSince: async () => 2,
    countLessonsCompletedSince: async () => 4,
    sumExamSecondsSince: async () => 5400,
    dailyRegistrations: async () => [{ _id: '2026-11-04', value: 1 }],
    dailyActiveUsers: async () => [{ _id: '2026-10-30', value: 2 }],
    dailyExamMinutes: async () => [{ _id: '2026-11-01', value: 12.6 }],
    levelDistribution: async () => [{ _id: null, value: 3 }, { _id: 'N5', value: 7 }],
  });

  const analytics = await serviceWith({ repository }).adminAnalytics('7d');

  assert.deepEqual(analytics, {
    period: '7d',
    labels: ['2026-10-29', '2026-10-30', '2026-10-31', '2026-11-01', '2026-11-02', '2026-11-03', '2026-11-04'],
    metrics: { total_users: 10, active_today: 2, lessons_completed: 4, study_minutes: 90 },
    daily_active_users: [0, 2, 0, 0, 0, 0, 0],
    new_registrations: [0, 0, 0, 0, 0, 0, 1],
    lessons_completed: [0, 0, 0, 0, 0, 0, 0],
    total_study_time: [0, 0, 0, 13, 0, 0, 0],
    level_distribution: { 'Chưa đặt': 3, N5: 7 },
  });
});

test('analytics admin đếm "hôm nay" từ nửa đêm Việt Nam, chuỗi ngày từ đầu kỳ', async () => {
  const repository = fakeRepository();

  const analytics = await serviceWith({ repository }).adminAnalytics('30d');

  const since = { since: vnMidnight('2026-10-06') };
  const calls = new Map(repository.calls);
  assert.deepEqual(calls.get('countUsersActiveSince'), { since: vnMidnight('2026-11-04') });
  assert.deepEqual(calls.get('countLessonsCompletedSince'), since);
  assert.deepEqual(calls.get('dailyRegistrations'), since);
  assert.equal(analytics.labels.length, 30);
  assert.equal(analytics.labels[0], '2026-10-06');
});
