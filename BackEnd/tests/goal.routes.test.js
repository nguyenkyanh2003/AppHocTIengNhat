import assert from 'node:assert/strict';
import test from 'node:test';

import express from 'express';
import request from 'supertest';

import { errorHandler } from '../src/middleware/error.middleware.js';
import { timezoneMiddleware } from '../src/middleware/timezone.middleware.js';
import { ApiError } from '../src/shared/http/api-error.js';
import { createGoalRoutes } from '../src/modules/goals/goal.routes.js';

const ID = '507f1f77bcf86cd799439011';
const GOAL = {
  id: ID, type: 'vocabulary', title: 'Đạt 150 từ vựng', target: 150, current: 120,
  is_completed: true, completed_at: '2026-11-04T08:00:00.000Z', deadline: '2026-12-31', created_at: '2026-11-01T00:00:00.000Z',
};

/** Router thật + service giả + auth giả, gắn middleware giờ Việt Nam như `app.js`. */
const buildApp = (service) => {
  const app = express();
  app.use(express.json());
  app.use(timezoneMiddleware);
  app.use('/api/goal', createGoalRoutes({
    service,
    authenticate: (req, _res, next) => { req.user = { _id: 'user-1' }; next(); },
  }));
  app.use(errorHandler);
  return app;
};

const recording = (methods) => {
  const calls = [];
  const service = Object.fromEntries(Object.entries(methods).map(([name, result]) => [name, async (args) => {
    calls.push([name, args]);
    if (result instanceof Error) throw result;
    return result;
  }]));
  return { calls, service };
};

test('GET / trả mục tiêu kèm số đã học và nội dung hiện có; thời điểm giữ ISO có múi giờ', async () => {
  const counts = { lessons: 2, vocabulary: 120, kanji: 5 };
  const available = { lessons: 40, kanji: 33 };
  const { calls, service } = recording({ list: { goals: [GOAL], counts, available } });

  const response = await request(buildApp(service)).get('/api/goal');

  assert.equal(response.status, 200);
  assert.deepEqual(response.body, { data: [GOAL], total: 1, counts, available });
  assert.deepEqual(calls, [['list', 'user-1']]);
});

test('POST / tạo mục tiêu; tên trống coi như không đặt, hạn tuỳ chọn', async () => {
  const { calls, service } = recording({ create: GOAL });

  const response = await request(buildApp(service))
    .post('/api/goal')
    .send({ type: 'vocabulary', target: 150, title: '   ' });

  assert.equal(response.status, 201);
  assert.deepEqual(response.body, { data: GOAL });
  assert.deepEqual(calls, [['create', { userId: 'user-1', type: 'vocabulary', target: 150, title: undefined, deadline: null }]]);
});

test('POST / chặn 400 với loại lạ, số không hợp lệ hoặc hạn sai định dạng', async () => {
  const { calls, service } = recording({ create: GOAL });
  const app = buildApp(service);

  for (const body of [
    { target: 10 },
    { type: 'days', target: 10 },
    { type: 'kanji', target: 0 },
    { type: 'kanji', target: -5 },
    { type: 'kanji', target: 2.5 },
    { type: 'kanji', target: '10' },
    { type: 'kanji', target: 100001 },
    { type: 'kanji', target: 10, deadline: '31/12/2026' },
    { type: 'kanji', target: 10, deadline: '2026-02-30' },
    { type: 'kanji', target: 10, current_value: 3 },
  ]) {
    const response = await request(app).post('/api/goal').send(body);
    assert.equal(response.status, 400, JSON.stringify(body));
  }
  assert.deepEqual(calls, []);
});

test('lỗi nghiệp vụ của service đi ra nguyên mã và số hiện có', async () => {
  const error = ApiError.badRequest('Bạn đã có 120 từ vựng; số cần đạt phải lớn hơn 120.', {
    code: 'GOAL_TARGET_REACHED', details: { current: 120 },
  });
  const { service } = recording({ create: error });

  const response = await request(buildApp(service)).post('/api/goal').send({ type: 'vocabulary', target: 100 });

  assert.equal(response.status, 400);
  assert.equal(response.body.code, 'GOAL_TARGET_REACHED');
  assert.deepEqual(response.body.details, { current: 120 });
});

test('PATCH /:id sửa tên, số cần đạt, hạn (null là bỏ hạn); không đổi được loại', async () => {
  const { calls, service } = recording({ update: GOAL });
  const app = buildApp(service);

  const response = await request(app).patch(`/api/goal/${ID}`).send({ title: 'Mốc N5', deadline: null });
  assert.equal(response.status, 200);
  assert.deepEqual(calls, [['update', { id: ID, userId: 'user-1', changes: { title: 'Mốc N5', deadline: null } }]]);

  for (const body of [{}, { type: 'kanji' }, { title: '' }]) {
    assert.equal((await request(app).patch(`/api/goal/${ID}`).send(body)).status, 400, JSON.stringify(body));
  }
  assert.equal((await request(app).patch('/api/goal/abc').send({ title: 'X' })).status, 400);
});

test('DELETE /:id xoá mục tiêu của mình; không thuộc mình là 404', async () => {
  const { calls, service } = recording({ remove: undefined });

  const response = await request(buildApp(service)).delete(`/api/goal/${ID}`);
  assert.deepEqual(response.body, { data: { deleted: true } });
  assert.deepEqual(calls, [['remove', { id: ID, userId: 'user-1' }]]);

  const missing = recording({ remove: ApiError.notFound('Không tìm thấy mục tiêu.') });
  assert.equal((await request(buildApp(missing.service)).delete(`/api/goal/${ID}`)).status, 404);
});
