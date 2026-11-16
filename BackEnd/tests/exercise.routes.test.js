import assert from 'node:assert/strict';
import test from 'node:test';

import express from 'express';
import request from 'supertest';

import { errorHandler, notFoundHandler } from '../src/middleware/error.middleware.js';
import { createExerciseRoutes } from '../src/modules/exercise/exercise.routes.js';
import { ApiError } from '../src/shared/http/api-error.js';

const ID = '507f1f77bcf86cd799439011';
const ATTEMPT = '9b2f6c1e-4f0a-4c33-9d55-0a1b2c3d4e5f';
const EXERCISE = { _id: ID, title: 'Bài tập N5', question_count: 1 };
const RESULT = { _id: 'r1', score: 100, passed: true };

const recording = (methods) => {
  const calls = [];
  const fake = Object.fromEntries(Object.entries(methods).map(([name, result]) => [name, async (args) => {
    calls.push([name, args]);
    if (result instanceof Error) throw result;
    return result;
  }]));
  return { calls, fake };
};

const buildApp = ({ service = {}, submission = {} } = {}) => {
  const app = express();
  app.use(express.json());
  app.use('/api/exercise', createExerciseRoutes({
    service,
    submission,
    authenticate: (req, _res, next) => { req.user = { _id: 'user-1' }; next(); },
  }));
  app.use(notFoundHandler);
  app.use(errorHandler);
  return app;
};

test('danh sách theo cấp độ và theo bài học trả `{ data, total }`; rỗng vẫn 200', async () => {
  const { calls, fake } = recording({ listByLevel: [EXERCISE], listByLesson: [] });
  const app = buildApp({ service: fake });

  assert.deepEqual((await request(app).get('/api/exercise/level/N5')).body, { data: [EXERCISE], total: 1 });
  assert.deepEqual((await request(app).get(`/api/exercise/lesson/${ID}`)).body, { data: [], total: 0 });
  assert.equal((await request(app).get('/api/exercise/level/N6')).status, 400);
  assert.equal((await request(app).get('/api/exercise/lesson/abc')).status, 400);
  assert.deepEqual(calls, [['listByLevel', 'N5'], ['listByLesson', ID]]);
});

test('chi tiết bọc trong `data`; id sai 400; không có 404', async () => {
  const { calls, fake } = recording({ detail: EXERCISE });

  assert.deepEqual((await request(buildApp({ service: fake })).get(`/api/exercise/${ID}`)).body, { data: EXERCISE });
  assert.equal((await request(buildApp({ service: fake })).get('/api/exercise/abc')).status, 400);
  assert.deepEqual(calls, [['detail', ID]]);

  const missing = recording({ detail: ApiError.notFound('Không tìm thấy bài tập.') }).fake;
  assert.equal((await request(buildApp({ service: missing })).get(`/api/exercise/${ID}`)).status, 404);
});

test('nộp bài: lần đầu 201, gửi lại đúng lượt cũ 200, cả hai bọc kết quả trong `data`', async () => {
  const body = { attempt_id: ATTEMPT, answers: [{ question_id: 'q1', answer_id: 'a1' }], timeSpent: 42 };
  const first = recording({ submit: { result: RESULT, replayed: false } });

  const created = await request(buildApp({ submission: first.fake })).post(`/api/exercise/submit/${ID}`).send(body);

  assert.equal(created.status, 201);
  assert.deepEqual(created.body, { data: RESULT });
  assert.deepEqual(first.calls, [['submit', {
    userId: 'user-1',
    exerciseId: ID,
    attemptId: ATTEMPT,
    answers: body.answers,
    timeSpent: 42,
  }]]);

  const replay = recording({ submit: { result: RESULT, replayed: true } }).fake;
  const again = await request(buildApp({ submission: replay })).post(`/api/exercise/submit/${ID}`).send(body);
  assert.equal(again.status, 200);
  assert.deepEqual(again.body, { data: RESULT });
});

test('lịch sử là trang kết quả của chính mình; xem lại một kết quả theo id', async () => {
  const { calls, fake } = recording({ history: { items: [RESULT], total: 1, page: 1, limit: 20 }, result: RESULT });
  const app = buildApp({ service: fake });

  assert.deepEqual((await request(app).get('/api/exercise/history')).body, { data: [RESULT], page: 1, limit: 20, total: 1, totalPages: 1 });
  assert.deepEqual((await request(app).get(`/api/exercise/result/${ID}`)).body, { data: RESULT });
  assert.equal((await request(app).get('/api/exercise/result/abc')).status, 400);
  assert.deepEqual(calls, [
    ['history', { userId: 'user-1', page: 1, limit: 20 }],
    ['result', { userId: 'user-1', id: ID }],
  ]);
});

test('lọc theo loại bài tập đã bị gỡ (không màn hình nào gọi)', async () => {
  assert.equal((await request(buildApp()).get('/api/exercise/type/multiple_choice')).status, 404);
});
