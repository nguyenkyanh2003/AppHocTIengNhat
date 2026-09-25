import assert from 'node:assert/strict';
import test from 'node:test';

import express from 'express';
import request from 'supertest';

import { errorHandler } from '../src/middleware/error.middleware.js';
import { createStreakRoutes } from '../src/modules/streaks/streak.routes.js';

const USER = { _id: 'user-1' };

const passthrough = (req, _res, next) => {
  req.user = USER;
  next();
};

/** Router thật + service giả + auth giả, không cần MongoDB. */
const buildApp = (readService = {}, settingsService = {}) => {
  const app = express();
  app.use(express.json());
  app.use('/api/streak', createStreakRoutes({ readService, settingsService, authenticate: passthrough }));
  app.use(errorHandler);
  return app;
};

test('GET /my-streak trả thẳng tóm tắt, giữ vỏ response cũ', async () => {
  let askedFor = null;
  const app = buildApp({
    summary: async (userId) => {
      askedFor = userId;
      return { current_streak: 2, total_xp: 30, level: 1, activity_dates: [] };
    },
  });

  const response = await request(app).get('/api/streak/my-streak');

  assert.equal(response.status, 200);
  // Client cũ đọc thẳng các trường ở gốc, không bọc trong `data`.
  assert.equal(response.body.current_streak, 2);
  assert.equal(response.body.total_xp, 30);
  assert.equal(askedFor, 'user-1');
});

test('GET /xp-history trả mảng đầy đủ cho export', async () => {
  const app = buildApp({
    xpHistory: async () => [{ amount: 20, reason: 'Hoàn thành bài học', earned_at: '2026-09-19T02:00:00.000Z' }],
  });

  const response = await request(app).get('/api/streak/xp-history');

  assert.equal(response.status, 200);
  assert.ok(Array.isArray(response.body));
  assert.equal(response.body[0].amount, 20);
});

test('GET /xp-history?mode=page trả trang theo response contract chung', async () => {
  let received = null;
  const app = buildApp({
    xpHistoryPage: async (userId, args) => {
      received = { userId, ...args };
      return { data: [{ amount: 2 }], next_cursor: 'abc', as_of: '2026-09-19T03:00:00.000Z' };
    },
  });

  const response = await request(app).get('/api/streak/xp-history?mode=page&limit=50&cursor=abc');

  assert.equal(response.status, 200);
  assert.deepEqual(response.body, {
    data: [{ amount: 2 }],
    next_cursor: 'abc',
    as_of: '2026-09-19T03:00:00.000Z',
  });
  assert.deepEqual(received, { userId: 'user-1', limit: 50, cursor: 'abc' });
});

test('GET /xp-history?mode=page chặn limit ngoài khoảng và mode lạ', async () => {
  const app = buildApp({ xpHistoryPage: async () => ({ data: [], next_cursor: null, as_of: '' }) });

  assert.equal((await request(app).get('/api/streak/xp-history?mode=page&limit=101')).status, 400);
  assert.equal((await request(app).get('/api/streak/xp-history?mode=all')).status, 400);
});

test('GET /days trả lịch kèm cursor và khoảng ngày đã dùng', async () => {
  let received = null;
  const app = buildApp({
    days: async (userId, query) => {
      received = { userId, ...query };
      return { data: [{ day_key: '2026-09-19' }], next_cursor: null, from: '2026-09-01', to: '2026-09-19' };
    },
  });

  const response = await request(app).get('/api/streak/days?from=2026-09-01&to=2026-09-19');

  assert.equal(response.status, 200);
  assert.deepEqual(response.body, {
    data: [{ day_key: '2026-09-19' }],
    next_cursor: null,
    from: '2026-09-01',
    to: '2026-09-19',
  });
  assert.deepEqual(received, { userId: 'user-1', from: '2026-09-01', to: '2026-09-19', limit: 100 });
});

test('GET /days từ chối ngày sai định dạng hoặc không có trên lịch', async () => {
  const app = buildApp({ days: async () => ({ data: [], next_cursor: null }) });

  assert.equal((await request(app).get('/api/streak/days?from=2026-9-1')).status, 400);
  assert.equal((await request(app).get('/api/streak/days?to=2026-02-30')).status, 400);
  assert.equal((await request(app).get('/api/streak/days?limit=500')).status, 400);
});

test('GET /leaderboard nhận period và limit đã kiểm', async () => {
  let received = null;
  const app = buildApp({
    leaderboard: async (args) => {
      received = args;
      return { leaderboard: [], user_rank: null };
    },
  });

  const response = await request(app).get('/api/streak/leaderboard?period=week&limit=10');

  assert.equal(response.status, 200);
  assert.deepEqual(response.body, { leaderboard: [], user_rank: null });
  assert.deepEqual(received, { userId: 'user-1', period: 'week', limit: 10 });
});

test('GET /leaderboard mặc định là toàn thời gian, 50 người', async () => {
  let received = null;
  const app = buildApp({
    leaderboard: async (args) => {
      received = args;
      return { leaderboard: [], user_rank: null };
    },
  });

  await request(app).get('/api/streak/leaderboard');
  assert.deepEqual(received, { userId: 'user-1', period: 'all', limit: 50 });
});

test('GET /leaderboard từ chối kỳ lạ và limit ngoài khoảng', async () => {
  const app = buildApp({ leaderboard: async () => ({ leaderboard: [], user_rank: null }) });

  assert.equal((await request(app).get('/api/streak/leaderboard?period=year')).status, 400);
  assert.equal((await request(app).get('/api/streak/leaderboard?limit=0')).status, 400);
  assert.equal((await request(app).get('/api/streak/leaderboard?limit=101')).status, 400);
});

test('các đường tự cấp thưởng và đường test đã bị gỡ', async () => {
  // Spec §3.1: không endpoint nào cho client gửi hoạt động hay XP.
  const app = buildApp();

  const addXp = await request(app).post('/api/streak/add-xp').send({ amount: 1_000_000 });
  assert.equal(addXp.status, 404);
  assert.equal((await request(app).post('/api/streak/test/reset-yesterday')).status, 404);
  assert.equal((await request(app).get('/api/streak/test/debug')).status, 404);
});

// --- cài đặt mục tiêu ngày và nhắc học (Phần B) -------------------------------

const SETTINGS_VIEW = {
  daily_goal_xp: 20,
  next_daily_goal_xp: 30,
  next_goal_from: '2026-09-26',
  goal_options: [10, 20, 30, 50],
  reminder_enabled: true,
  reminder_time: '20:00',
  reminder_window: { start: '08:00', end: '21:59' },
  revision: 2,
};

test('GET /settings trả cài đặt theo response contract chung', async () => {
  let askedFor = null;
  const app = buildApp({}, {
    get: async (userId) => {
      askedFor = userId;
      return SETTINGS_VIEW;
    },
  });

  const response = await request(app).get('/api/streak/settings');

  assert.equal(response.status, 200);
  assert.deepEqual(response.body, { data: SETTINGS_VIEW });
  assert.equal(askedFor, 'user-1');
});

test('PUT /settings chuyển đúng các trường đã kiểm cho service', async () => {
  let received = null;
  const app = buildApp({}, {
    update: async (userId, changes) => {
      received = { userId, changes };
      return SETTINGS_VIEW;
    },
  });

  const response = await request(app)
    .put('/api/streak/settings')
    .send({ daily_goal_xp: 30, reminder_enabled: true, reminder_time: '21:59' });

  assert.equal(response.status, 200);
  assert.deepEqual(response.body, { data: SETTINGS_VIEW });
  assert.deepEqual(received, {
    userId: 'user-1',
    changes: { daily_goal_xp: 30, reminder_enabled: true, reminder_time: '21:59' },
  });
});

test('PUT /settings từ chối giá trị ngoài spec và trường lạ', async () => {
  const app = buildApp({}, { update: async () => assert.fail('không được tới service') });

  for (const body of [
    { daily_goal_xp: 25 },
    { daily_goal_xp: '20' },
    { reminder_time: '22:30' },
    { reminder_time: '7:30' },
    { reminder_enabled: 'true' },
    // Client không được tự đặt băng hay revision qua đường cài đặt.
    { freezes_available: 2 },
    { reminder_enabled: true, revision: 99 },
    {},
  ]) {
    const response = await request(app).put('/api/streak/settings').send(body);
    assert.equal(response.status, 400, JSON.stringify(body));
    assert.equal(response.body.code, 'VALIDATION_ERROR');
  }
});
