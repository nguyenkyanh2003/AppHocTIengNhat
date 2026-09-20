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

/** Router thật + service đọc giả + auth giả, không cần MongoDB. */
const buildApp = (readService = {}) => {
  const app = express();
  app.use(express.json());
  app.use('/api/streak', createStreakRoutes({ readService, authenticate: passthrough }));
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
