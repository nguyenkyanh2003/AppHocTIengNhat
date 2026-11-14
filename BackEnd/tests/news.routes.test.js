import assert from 'node:assert/strict';
import test from 'node:test';

import express from 'express';
import request from 'supertest';

import { errorHandler } from '../src/middleware/error.middleware.js';
import { ApiError } from '../src/shared/http/api-error.js';
import { createNewsRoutes } from '../src/modules/news/news.routes.js';

const ID = '507f1f77bcf86cd799439011';
const NEWS = { _id: ID, title: 'Tin', level: 'N5' };

const buildApp = (service) => {
  const app = express();
  app.use(express.json());
  app.use('/api/news', createNewsRoutes({ service }));
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

test('GET / đọc công khai, trả một trang theo contract phân trang chung', async () => {
  const { calls, service } = recording({ list: { items: [NEWS], total: 11, page: 1, limit: 10 } });

  const response = await request(buildApp(service)).get('/api/news?limit=10&level=');

  assert.equal(response.status, 200);
  assert.deepEqual(response.body, { data: [NEWS], page: 1, limit: 10, total: 11, totalPages: 2 });
  // Cấp độ bỏ trống đến service như không truyền.
  assert.deepEqual(calls, [['list', { page: 1, limit: 10, level: undefined }]]);
});

test('GET / chặn cấp độ lạ và limit quá 100', async () => {
  const { calls, service } = recording({ list: {} });
  for (const query of ['level=N9', 'limit=1000']) {
    assert.equal((await request(buildApp(service)).get(`/api/news?${query}`)).status, 400, query);
  }
  assert.deepEqual(calls, []);
});

test('GET /:id trả `{ data }`; id sai dạng là 400, không có là 404', async () => {
  const { service } = recording({ getDetail: NEWS });
  assert.deepEqual((await request(buildApp(service)).get(`/api/news/${ID}`)).body, { data: NEWS });
  assert.equal((await request(buildApp(service)).get('/api/news/abc')).status, 400);

  const missing = recording({ getDetail: ApiError.notFound('Không tìm thấy tin tức.') });
  assert.equal((await request(buildApp(missing.service)).get(`/api/news/${ID}`)).status, 404);
});

test('GET /:id/related trả danh sách kèm tổng; mặc định 5 bài, tối đa 20', async () => {
  const { calls, service } = recording({ related: [NEWS] });
  const app = buildApp(service);

  assert.deepEqual((await request(app).get(`/api/news/${ID}/related`)).body, { data: [NEWS], total: 1 });
  assert.deepEqual(calls, [['related', { id: ID, limit: 5 }]]);
  assert.equal((await request(app).get(`/api/news/${ID}/related?limit=50`)).status, 400);
});
