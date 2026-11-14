import assert from 'node:assert/strict';
import test from 'node:test';

import express from 'express';
import request from 'supertest';

import { errorHandler } from '../src/middleware/error.middleware.js';
import { ApiError } from '../src/shared/http/api-error.js';
import { createGrammarRoutes } from '../src/modules/grammar/grammar.routes.js';

const ID = '507f1f77bcf86cd799439011';
const GRAMMAR = { _id: ID, title: 'が', structure: 'N + が', meaning: 'chủ ngữ', level: 'N5' };

/** Router thật + service giả + auth giả: người học thường và quản trị viên. */
const buildApp = (service, { admin = true } = {}) => {
  const app = express();
  app.use(express.json());
  app.use('/api/grammar', createGrammarRoutes({
    service,
    authenticate: (req, _res, next) => { req.user = { _id: 'user-1' }; next(); },
    authorizeAdmin: (_req, res, next) => (admin ? next() : res.status(403).json({ message: 'Chỉ admin.' })),
  }));
  app.use(errorHandler);
  return app;
};

const recording = (methods) => {
  const calls = [];
  const service = Object.fromEntries(Object.entries(methods).map(([name, result]) => [name, async (...args) => {
    calls.push([name, ...args]);
    if (result instanceof Error) throw result;
    return result;
  }]));
  return { calls, service };
};

test('GET / trả một trang theo contract phân trang chung', async () => {
  const { calls, service } = recording({ list: { items: [GRAMMAR], total: 21, page: 2, limit: 10 } });

  const response = await request(buildApp(service)).get('/api/grammar?page=2&limit=10&level=N5&sortBy=popular&search=');

  assert.equal(response.status, 200);
  assert.deepEqual(response.body, { data: [GRAMMAR], page: 2, limit: 10, total: 21, totalPages: 3 });
  // Ô tìm kiếm bỏ trống đến service như không truyền.
  assert.deepEqual(calls, [['list', { page: 2, limit: 10, level: 'N5', sortBy: 'popular', search: undefined }]]);
});

test('GET / chặn cấp độ lạ, cách sắp xếp lạ và limit quá 100', async () => {
  const { calls, service } = recording({ list: { items: [], total: 0, page: 1, limit: 20 } });
  const app = buildApp(service);

  for (const query of ['level=N6', 'sortBy=random', 'limit=500']) {
    assert.equal((await request(app).get(`/api/grammar?${query}`)).status, 400, query);
  }
  assert.deepEqual(calls, []);
});

test('GET /:id trả `{ data }`; id sai dạng là 400, không có là 404', async () => {
  const { service } = recording({ getDetail: GRAMMAR });
  const app = buildApp(service);

  assert.deepEqual((await request(app).get(`/api/grammar/${ID}`)).body, { data: GRAMMAR });
  assert.equal((await request(app).get('/api/grammar/abc')).status, 400);

  const missing = recording({ getDetail: ApiError.notFound('Ngữ pháp không tồn tại.') });
  assert.equal((await request(buildApp(missing.service)).get(`/api/grammar/${ID}`)).status, 404);
});

test('POST / tạo mới 201; khôi phục bản đã xoá thì báo đúng như vậy', async () => {
  const body = { title: ' が ', structure: 'N + が', meaning: 'chủ ngữ', level: 'N5', lessonID: '' };
  const { calls, service } = recording({ create: { grammar: GRAMMAR, revived: false } });

  const response = await request(buildApp(service)).post('/api/grammar').send(body);

  assert.equal(response.status, 201);
  assert.deepEqual(response.body, { data: GRAMMAR, message: 'Thêm ngữ pháp thành công.' });
  assert.deepEqual(calls, [['create', {
    title: 'が', structure: 'N + が', meaning: 'chủ ngữ', level: 'N5', lessonID: null,
    examples: [], difficulty: 3, relatedGrammar: [],
  }]]);

  const revived = recording({ create: { grammar: GRAMMAR, revived: true } });
  const again = await request(buildApp(revived.service)).post('/api/grammar').send(body);
  assert.match(again.body.message, /khôi phục/);
});

test('POST / thiếu trường bắt buộc, ví dụ thiếu nghĩa hoặc bài học sai dạng là 400', async () => {
  const { calls, service } = recording({ create: { grammar: GRAMMAR, revived: false } });
  const app = buildApp(service);
  const valid = { title: 'が', structure: 'N + が', meaning: 'chủ ngữ', level: 'N5' };

  for (const body of [
    { ...valid, title: '  ' },
    { ...valid, level: 'N6' },
    { ...valid, lessonID: 'bai-1' },
    { ...valid, examples: [{ sentence: '誰が来ましたか。' }] },
    { ...valid, difficulty: 9 },
  ]) {
    assert.equal((await request(app).post('/api/grammar').send(body)).status, 400, JSON.stringify(body));
  }
  assert.deepEqual(calls, []);
});

test('POST / trùng ngữ pháp đang có ra 409 kèm mã lỗi', async () => {
  const conflict = ApiError.conflict('Cấp N5 đã có ngữ pháp "が".', { code: 'DUPLICATE_GRAMMAR' });
  const { service } = recording({ create: conflict });

  const response = await request(buildApp(service))
    .post('/api/grammar')
    .send({ title: 'が', structure: 'N + が', meaning: 'chủ ngữ', level: 'N5' });

  assert.equal(response.status, 409);
  assert.equal(response.body.code, 'DUPLICATE_GRAMMAR');
});

test('PUT /:id chỉ gửi trường có trong body; body rỗng là 400', async () => {
  const { calls, service } = recording({ update: GRAMMAR });
  const app = buildApp(service);

  const response = await request(app).put(`/api/grammar/${ID}`).send({ meaning: 'chủ ngữ (nhấn mạnh)' });
  assert.deepEqual(response.body, { data: GRAMMAR, message: 'Cập nhật ngữ pháp thành công.' });
  assert.deepEqual(calls, [['update', ID, { meaning: 'chủ ngữ (nhấn mạnh)' }]]);

  assert.equal((await request(app).put(`/api/grammar/${ID}`).send({})).status, 400);
});

test('DELETE /:id xoá mềm và trả `{ data: { deleted: true } }`', async () => {
  const { calls, service } = recording({ remove: undefined });

  const response = await request(buildApp(service)).delete(`/api/grammar/${ID}`);

  assert.deepEqual(response.body, { data: { deleted: true }, message: 'Xóa ngữ pháp thành công.' });
  assert.deepEqual(calls, [['remove', ID]]);
});

test('người học thường không thêm, sửa, xoá được', async () => {
  const { calls, service } = recording({ create: {}, update: {}, remove: undefined });
  const app = buildApp(service, { admin: false });

  assert.equal((await request(app).post('/api/grammar').send({})).status, 403);
  assert.equal((await request(app).put(`/api/grammar/${ID}`).send({ title: 'は' })).status, 403);
  assert.equal((await request(app).delete(`/api/grammar/${ID}`)).status, 403);
  assert.deepEqual(calls, []);
});
