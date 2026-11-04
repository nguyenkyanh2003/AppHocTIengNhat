import assert from 'node:assert/strict';
import test from 'node:test';

import express from 'express';
import request from 'supertest';

import { errorHandler, notFoundHandler } from '../src/middleware/error.middleware.js';
import { createKanjiRoutes } from '../src/modules/kanji/kanji.routes.js';
import { ApiError } from '../src/shared/http/api-error.js';

const ID = '64b7f0c2a1b2c3d4e5f60718';

const asUser = (req, _res, next) => {
  req.user = { _id: 'user-1' };
  next();
};

const denyAdmin = (_req, res) => res.status(403).json({ message: 'Chỉ admin.' });

const recordingService = (overrides = {}) => {
  const calls = [];
  const record = (name, result) => async (args) => {
    calls.push([name, args]);
    return result;
  };
  return {
    calls,
    getDetail: record('getDetail', { _id: ID, character: '学', srs_progress: null }),
    markLearned: record('markLearned', { progress: { _id: 'p1', item_type: 'Kanji' }, created: true }),
    unmarkLearned: record('unmarkLearned', undefined),
    remove: record('remove', undefined),
    ...overrides,
  };
};

const buildApp = (service, { authenticateAsAdmin = asUser } = {}) => {
  const app = express();
  app.use(express.json());
  app.use('/api/kanji', createKanjiRoutes({ service, authenticate: asUser, authenticateAsAdmin }));
  app.use(notFoundHandler);
  app.use(errorHandler);
  return app;
};

test('chi tiết Kanji bọc trong data và kèm tiến độ ôn của user', async () => {
  const service = recordingService();

  const response = await request(buildApp(service)).get(`/api/kanji/${ID}`);

  assert.equal(response.status, 200);
  assert.deepEqual(response.body, { data: { _id: ID, character: '学', srs_progress: null } });
  assert.deepEqual(service.calls, [['getDetail', { id: ID, userId: 'user-1' }]]);
});

test('thêm và gỡ khỏi ôn tập theo ID trong path, user lấy từ phiên đăng nhập', async () => {
  const service = recordingService();
  const app = buildApp(service);

  const added = await request(app).post(`/api/kanji/${ID}/mark-learned`);
  const removed = await request(app).delete(`/api/kanji/${ID}/mark-learned`);

  assert.equal(added.status, 200);
  assert.deepEqual(added.body.data, { _id: 'p1', item_type: 'Kanji' });
  assert.equal(typeof added.body.message, 'string');
  assert.equal(removed.status, 200);
  assert.deepEqual(removed.body.data, { deleted: true });
  assert.deepEqual(service.calls, [
    ['markLearned', { id: ID, userId: 'user-1' }],
    ['unmarkLearned', { id: ID, userId: 'user-1' }],
  ]);
});

test('ID sai định dạng bị chặn trước khi tới service', async () => {
  const service = recordingService();
  const app = buildApp(service);

  assert.equal((await request(app).get('/api/kanji/abc')).status, 400);
  assert.equal((await request(app).post('/api/kanji/abc/mark-learned')).status, 400);
  assert.equal((await request(app).delete('/api/kanji/abc')).status, 400);
  assert.equal(service.calls.length, 0);
});

test('xoá Kanji còn trong lịch ôn trả 409 kèm mã; xoá được thì trả deleted', async () => {
  const blocked = buildApp(
    recordingService({
      remove: async () => {
        throw ApiError.conflict('Không thể xoá Kanji này.', { code: 'KANJI_IN_REVIEW' });
      },
    }),
  );
  const conflict = await request(blocked).delete(`/api/kanji/${ID}`);
  assert.equal(conflict.status, 409);
  assert.equal(conflict.body.code, 'KANJI_IN_REVIEW');

  const ok = await request(buildApp(recordingService())).delete(`/api/kanji/${ID}`);
  assert.equal(ok.status, 200);
  assert.deepEqual(ok.body.data, { deleted: true });
});

test('xoá Kanji chỉ dành cho admin', async () => {
  const service = recordingService();

  const response = await request(buildApp(service, { authenticateAsAdmin: denyAdmin })).delete(`/api/kanji/${ID}`);

  assert.equal(response.status, 403);
  assert.equal(service.calls.length, 0);
});

test('route học cũ không tạo thẻ đã bị bỏ', async () => {
  const response = await request(buildApp(recordingService())).post(`/api/kanji/learn/${ID}`).send({});
  assert.equal(response.status, 404);
});
