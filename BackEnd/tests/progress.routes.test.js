import assert from 'node:assert/strict';
import test from 'node:test';

import express from 'express';
import request from 'supertest';

import { errorHandler, notFoundHandler } from '../src/middleware/error.middleware.js';
import { createProgressRoutes } from '../src/modules/progress/progress.routes.js';

const asUser = (req, _res, next) => {
  req.user = { _id: 'user-1' };
  next();
};

const denyAdmin = (_req, res) => res.status(403).json({ message: 'Chỉ admin.' });

const recordingService = (overrides = {}) => {
  const calls = [];
  const record = (name, result) => async (...args) => {
    calls.push([name, ...args]);
    return result;
  };
  return {
    calls,
    listLessonProgress: record('listLessonProgress', []),
    dashboardStats: record('dashboardStats', { vocabulary_learned: 0 }),
    timeline: record('timeline', []),
    heatmap: record('heatmap', []),
    breakdown: record('breakdown', { lessons_by_level: [], exercises_by_type: [] }),
    adminAnalytics: record('adminAnalytics', { period: '7d' }),
    ...overrides,
  };
};

/** App tối thiểu: router thật + service giả + auth giả, không cần MongoDB. */
const buildApp = (service, { authenticateAsAdmin = asUser } = {}) => {
  const app = express();
  app.use(express.json());
  app.use('/api/progress', createProgressRoutes({ service, authenticate: asUser, authenticateAsAdmin }));
  app.use(notFoundHandler);
  app.use(errorHandler);
  return app;
};

test('GET /progress trả { data, total }; chưa học bài nào vẫn là 200 với mảng rỗng', async () => {
  const service = recordingService();

  const empty = await request(buildApp(service)).get('/api/progress');

  assert.equal(empty.status, 200);
  assert.deepEqual(empty.body, { data: [], total: 0 });
  assert.deepEqual(service.calls, [['listLessonProgress', 'user-1']]);
});

test('GET /progress đổi mốc thời gian sang giờ Việt Nam như các màn tiến độ khác', async () => {
  const service = recordingService({
    listLessonProgress: async () => [
      { _id: 'p1', last_studied_at: new Date('2026-11-03T18:30:00.000Z'), completed_at: null },
    ],
  });

  const response = await request(buildApp(service)).get('/api/progress');

  assert.equal(response.body.total, 1);
  assert.equal(response.body.data[0].last_studied_at, '2026-11-04 01:30:00');
});

test('dashboard giữ nguyên hình dạng client đang đọc, không bọc { data }', async () => {
  const stats = { vocabulary_learned: 12, kanji_learned: 5 };
  const timeline = [{ date: '2026-11-04', exercises: 1, lessons: 0, time: 60, xp: 10 }];
  const heatmap = [{ date: '2026-11-04', count: 2, time: 60 }];
  const breakdown = { lessons_by_level: [{ _id: 'N5' }], exercises_by_type: [] };
  const app = buildApp(
    recordingService({
      dashboardStats: async () => stats,
      timeline: async () => timeline,
      heatmap: async () => heatmap,
      breakdown: async () => breakdown,
    }),
  );

  assert.deepEqual((await request(app).get('/api/progress/dashboard/stats')).body, stats);
  assert.deepEqual((await request(app).get('/api/progress/dashboard/timeline')).body, timeline);
  assert.deepEqual((await request(app).get('/api/progress/dashboard/heatmap')).body, heatmap);
  assert.deepEqual((await request(app).get('/api/progress/dashboard/breakdown')).body, breakdown);
});

test('timeline mặc định một tuần và chặn kỳ lạ trước khi tới service', async () => {
  const service = recordingService();
  const app = buildApp(service);

  await request(app).get('/api/progress/dashboard/timeline');
  await request(app).get('/api/progress/dashboard/timeline?period=year');
  const bad = await request(app).get('/api/progress/dashboard/timeline?period=decade');

  assert.equal(bad.status, 400);
  assert.equal(bad.body.code, 'VALIDATION_ERROR');
  assert.deepEqual(service.calls, [
    ['timeline', 'user-1', 'week'],
    ['timeline', 'user-1', 'year'],
  ]);
});

test('heatmap nhận năm dạng số, bỏ trống thì để service chọn năm hiện tại', async () => {
  const service = recordingService();
  const app = buildApp(service);

  await request(app).get('/api/progress/dashboard/heatmap');
  await request(app).get('/api/progress/dashboard/heatmap?year=2025');
  const bad = await request(app).get('/api/progress/dashboard/heatmap?year=abc');

  assert.equal(bad.status, 400);
  assert.deepEqual(service.calls, [
    ['heatmap', 'user-1', undefined],
    ['heatmap', 'user-1', 2025],
  ]);
});

test('analytics admin mặc định 7 ngày, chặn kỳ lạ, và đi qua auth admin', async () => {
  const service = recordingService();
  const app = buildApp(service);

  assert.equal((await request(app).get('/api/progress/admin/analytics')).status, 200);
  await request(app).get('/api/progress/admin/analytics?period=90d');
  assert.equal((await request(app).get('/api/progress/admin/analytics?period=1y')).status, 400);
  assert.deepEqual(service.calls, [
    ['adminAnalytics', '7d'],
    ['adminAnalytics', '90d'],
  ]);

  const denied = await request(buildApp(service, { authenticateAsAdmin: denyAdmin })).get(
    '/api/progress/admin/analytics',
  );
  assert.equal(denied.status, 403);
});
