import assert from 'node:assert/strict';
import test from 'node:test';

import express from 'express';
import request from 'supertest';

import { errorHandler } from '../src/middleware/error.middleware.js';
import { ApiError } from '../src/shared/http/api-error.js';
import { createNotebookRoutes } from '../src/modules/notebook/notebook.routes.js';

const ID = '507f1f77bcf86cd799439011';
const NOTE = { _id: ID, title: 'Trợ từ は', content: 'Đánh dấu chủ đề', type: 'grammar', tags: [] };

const buildApp = (service) => {
  const app = express();
  app.use(express.json());
  app.use('/api/notebook', createNotebookRoutes({
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

test('POST / tạo ghi chú của chính người đăng nhập: 201, loại mặc định, thẻ bỏ trùng', async () => {
  const { calls, service } = recording({ create: NOTE });

  const response = await request(buildApp(service))
    .post('/api/notebook')
    .send({ title: ' Trợ từ は ', content: 'Đánh dấu chủ đề', tags: ['N5', ' N5 ', 'trợ từ'], user_id: 'someone-else' });

  assert.equal(response.status, 201);
  assert.deepEqual(response.body.data, NOTE);
  assert.match(response.body.message, /thành công/);
  assert.deepEqual(calls, [['create', {
    userId: 'user-1',
    input: { title: 'Trợ từ は', content: 'Đánh dấu chủ đề', type: 'general', tags: ['N5', 'trợ từ'] },
  }]]);
});

test('POST / thiếu tiêu đề/nội dung, loại lạ hay thẻ sai là 400', async () => {
  const { calls, service } = recording({ create: NOTE });
  const app = buildApp(service);
  const body = { title: 'a', content: 'b' };

  for (const invalid of [
    { ...body, title: '  ' },
    { ...body, content: '' },
    { ...body, type: 'diary' },
    { ...body, tags: 'N5' },
    { ...body, tags: [' '] },
  ]) {
    assert.equal((await request(app).post('/api/notebook').send(invalid)).status, 400, JSON.stringify(invalid));
  }
  assert.deepEqual(calls, []);
});

test('GET / trả trang ghi chú theo contract phân trang, bộ lọc trống coi như không truyền', async () => {
  const { calls, service } = recording({ list: { items: [NOTE], total: 1, page: 1, limit: 20 } });

  const response = await request(buildApp(service)).get('/api/notebook?type=&search=%20は%20');

  assert.deepEqual(response.body, { data: [NOTE], page: 1, limit: 20, total: 1, totalPages: 1 });
  assert.deepEqual(calls, [['list', { userId: 'user-1', page: 1, limit: 20, type: undefined, search: 'は' }]]);
  assert.equal((await request(buildApp(service)).get('/api/notebook?type=diary')).status, 400);
});

test('GET, PUT, DELETE /:id đọc, sửa, xoá ghi chú của chính mình', async () => {
  const { calls, service } = recording({ detail: NOTE, update: { ...NOTE, title: 'Mới' }, remove: undefined });
  const app = buildApp(service);

  assert.deepEqual((await request(app).get(`/api/notebook/${ID}`)).body, { data: NOTE });

  const updated = await request(app).put(`/api/notebook/${ID}`).send({ title: 'Mới', user_id: 'someone-else' });
  assert.equal(updated.body.data.title, 'Mới');

  const removed = await request(app).delete(`/api/notebook/${ID}`);
  assert.deepEqual(removed.body.data, { deleted: true });

  assert.deepEqual(calls, [
    ['detail', { userId: 'user-1', id: ID }],
    ['update', { userId: 'user-1', id: ID, changes: { title: 'Mới' } }],
    ['remove', { userId: 'user-1', id: ID }],
  ]);
});

test('PUT /:id không có gì để sửa là 400; id sai 400; ghi chú không có 404', async () => {
  const { calls, service } = recording({ update: NOTE });
  const app = buildApp(service);

  assert.equal((await request(app).put(`/api/notebook/${ID}`).send({ user_id: 'someone-else' })).status, 400);
  assert.equal((await request(app).put('/api/notebook/abc').send({ title: 'x' })).status, 400);
  assert.deepEqual(calls, []);

  const missing = buildApp(recording({ detail: ApiError.notFound('Không tìm thấy ghi chú.') }).service);
  assert.equal((await request(missing).get(`/api/notebook/${ID}`)).status, 404);
});
