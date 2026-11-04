import assert from 'node:assert/strict';
import test from 'node:test';

import express from 'express';
import request from 'supertest';

import { errorHandler } from '../src/middleware/error.middleware.js';
import { createSearchRoutes } from '../src/modules/search/search.routes.js';

const RESULT = { id: 'k1', type: 'kanji', title: '月', subtitle: 'Nguyệt', description: 'Mặt trăng', image_url: null, level: 'N5' };

/** App tối thiểu: router thật + service giả + auth giả, không cần MongoDB. */
const buildApp = (service) => {
  const app = express();
  app.use(
    '/api/search',
    createSearchRoutes({
      service,
      authenticate: (req, _res, next) => {
        req.user = { _id: 'user-1' };
        next();
      },
    }),
  );
  app.use(errorHandler);
  return app;
};

const recordingService = (results = [RESULT]) => {
  const calls = [];
  return {
    calls,
    search: async (query) => {
      calls.push(query);
      return results;
    },
  };
};

test('GET /api/search trả danh sách { data, total }', async () => {
  const service = recordingService();

  const response = await request(buildApp(service)).get('/api/search').query({ q: '月' });

  assert.equal(response.status, 200);
  assert.deepEqual(response.body, { data: [RESULT], total: 1 });
});

test('không có kết quả vẫn là 200 với mảng rỗng', async () => {
  const response = await request(buildApp(recordingService([]))).get('/api/search').query({ q: 'không-tồn-tại' });

  assert.equal(response.status, 200);
  assert.deepEqual(response.body, { data: [], total: 0 });
});

test('từ khoá được cắt khoảng trắng, mặc định 5 kết quả mỗi nhóm', async () => {
  const service = recordingService();

  await request(buildApp(service)).get('/api/search').query({ q: '  月  ' });

  assert.deepEqual(service.calls, [{ q: '月', limitPerType: 5 }]);
});

test('từ khoá mã hoá đúng đến service nguyên vẹn', async () => {
  const service = recordingService();

  await request(buildApp(service)).get('/api/search?q=A%26B&limit_per_type=3');
  await request(buildApp(service)).get('/api/search?q=C%2B%2B');

  assert.deepEqual(service.calls, [
    { q: 'A&B', limitPerType: 3 },
    { q: 'C++', limitPerType: 5 },
  ]);
});

test('từ khoá thiếu, chỉ có khoảng trắng hoặc quá 100 ký tự bị chặn 400', async () => {
  const service = { search: async () => assert.fail('không được gọi service') };
  const app = buildApp(service);

  for (const query of [{}, { q: '   ' }, { q: 'あ'.repeat(101) }]) {
    const response = await request(app).get('/api/search').query(query);
    assert.equal(response.status, 400, JSON.stringify(query));
    assert.equal(response.body.code, 'VALIDATION_ERROR');
  }
});

test('giới hạn mỗi nhóm nằm trong 1–10', async () => {
  const service = { search: async () => assert.fail('không được gọi service') };
  const app = buildApp(service);

  for (const limit of ['0', '11', 'abc']) {
    const response = await request(app).get('/api/search').query({ q: '月', limit_per_type: limit });
    assert.equal(response.status, 400, limit);
  }
});
