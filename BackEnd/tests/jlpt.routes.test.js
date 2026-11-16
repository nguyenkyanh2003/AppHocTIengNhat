import assert from 'node:assert/strict';
import test from 'node:test';

import express from 'express';
import request from 'supertest';

import { errorHandler, notFoundHandler } from '../src/middleware/error.middleware.js';
import { createJlptRoutes } from '../src/modules/jlpt/jlpt.routes.js';
import { ApiError } from '../src/shared/http/api-error.js';

const ID = '507f1f77bcf86cd799439011';
const ATTEMPT = '11111111-2222-4333-8444-555555555555';
const EXAM = { _id: ID, title: 'N5' };
const RESULT = { passed: true, total_score: 120 };

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
  app.use('/api/jlpt', createJlptRoutes({
    service,
    submission,
    authenticate: (req, _res, next) => { req.user = { _id: 'user-1' }; next(); },
  }));
  app.use(notFoundHandler);
  app.use(errorHandler);
  return app;
};

test('danh sách đề theo contract phân trang, bộ lọc đã ép kiểu', async () => {
  const { calls, fake } = recording({ list: { items: [EXAM], total: 1, page: 1, limit: 10 } });

  const response = await request(buildApp({ service: fake })).get('/api/jlpt?limit=10&level=N5&year=2026&month=');

  assert.deepEqual(response.body, { data: [EXAM], page: 1, limit: 10, total: 1, totalPages: 1 });
  assert.deepEqual(calls, [['list', { userId: 'user-1', page: 1, limit: 10, level: 'N5', year: 2026, month: undefined }]]);
  assert.equal((await request(buildApp({ service: fake })).get('/api/jlpt?month=13')).status, 400);
});

test('luyện nhanh trả `{ data, total }`; rỗng là 200; kỹ năng lạ 400', async () => {
  const { calls, fake } = recording({ practice: [] });
  const app = buildApp({ service: fake });

  assert.deepEqual((await request(app).get('/api/jlpt/practice?type=dokkai&level=N4')).body, { data: [], total: 0 });
  assert.equal((await request(app).get('/api/jlpt/practice?type=kaiwa')).status, 400);
  assert.deepEqual(calls, [['practice', { type: 'dokkai', level: 'N4', limit: 10 }]]);
});

test('đề để thi và đáp án sau khi nộp đều bọc trong `data`', async () => {
  const { calls, fake } = recording({ detail: EXAM, solutions: { ...EXAM, sections: {} } });
  const app = buildApp({ service: fake });

  assert.deepEqual((await request(app).get(`/api/jlpt/${ID}`)).body, { data: EXAM });
  assert.deepEqual((await request(app).get(`/api/jlpt/${ID}/solutions`)).body, { data: { ...EXAM, sections: {} } });
  assert.equal((await request(app).get('/api/jlpt/abc')).status, 400);
  assert.deepEqual(calls, [['detail', ID], ['solutions', { userId: 'user-1', examId: ID }]]);

  const locked = recording({ solutions: ApiError.forbidden('Bạn cần nộp bài trước khi xem đáp án.') }).fake;
  assert.equal((await request(buildApp({ service: locked })).get(`/api/jlpt/${ID}/solutions`)).status, 403);
});

test('nộp đề: một tên duy nhất cho bài làm và thời gian; kết quả bọc trong `data`', async () => {
  const { calls, fake } = recording({ submit: { result: RESULT, replayed: false } });
  const app = buildApp({ submission: fake });
  const answers = [{ question_key: 'moji_goi_0', selected: 1 }];

  const response = await request(app).post(`/api/jlpt/${ID}/submit`).send({ attempt_id: ATTEMPT, answers, time_spent: 600 });

  assert.deepEqual(response.body, { data: RESULT });
  assert.deepEqual(calls, [['submit', { userId: 'user-1', examId: ID, attemptId: ATTEMPT, answers, timeSpent: 600 }]]);

  for (const invalid of [
    { answers, time_spent: 600 },
    { attempt_id: ATTEMPT, answers: [] },
    { attempt_id: ATTEMPT, answers: [{ question_key: 'moji_goi_0', selected: 7 }] },
    { attempt_id: ATTEMPT, userAnswers: answers },
  ]) {
    assert.equal((await request(app).post(`/api/jlpt/${ID}/submit`).send(invalid)).status, 400, JSON.stringify(invalid));
  }
});
