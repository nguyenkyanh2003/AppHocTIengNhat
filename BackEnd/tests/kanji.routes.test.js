import assert from 'node:assert/strict';
import test from 'node:test';

import express from 'express';
import request from 'supertest';

import { errorHandler, notFoundHandler } from '../src/middleware/error.middleware.js';
import { createKanjiRoutes } from '../src/modules/kanji/kanji.routes.js';
import { ApiError } from '../src/shared/http/api-error.js';

const ID = '64b7f0c2a1b2c3d4e5f60718';
const LESSON = '64b7f0c2a1b2c3d4e5f60719';
const KANJI = { _id: ID, character: '学', meaning: 'học', level: 'N5' };

const asUser = (req, _res, next) => {
  req.user = { _id: 'user-1' };
  next();
};

const denyAdmin = (_req, res) => res.status(403).json({ message: 'Chỉ admin.' });

/** Multer giả: gắn sẵn một file nếu test yêu cầu, không đọc multipart thật. */
const fakeUpload = (file) => (req, _res, next) => {
  if (file) req.file = file;
  next();
};

const recordingService = (overrides = {}) => {
  const calls = [];
  const record = (name, result) => async (...args) => {
    calls.push([name, ...args]);
    return result;
  };
  return {
    calls,
    list: record('list', { items: [KANJI], total: 1, page: 1, limit: 20 }),
    search: record('search', [KANJI]),
    getDetail: record('getDetail', { _id: ID, character: '学', srs_progress: null }),
    markLearned: record('markLearned', { progress: { _id: 'p1', item_type: 'Kanji' }, created: true }),
    unmarkLearned: record('unmarkLearned', undefined),
    create: record('create', KANJI),
    update: record('update', KANJI),
    importSheet: record('importSheet', { insertedCount: 2 }),
    remove: record('remove', undefined),
    ...overrides,
  };
};

const buildApp = (service, { authenticateAsAdmin = asUser, file } = {}) => {
  const app = express();
  app.use(express.json());
  app.use('/api/kanji', createKanjiRoutes({ service, authenticate: asUser, authenticateAsAdmin, uploadExcel: fakeUpload(file) }));
  app.use(notFoundHandler);
  app.use(errorHandler);
  return app;
};

test('danh sách theo contract phân trang, lọc theo cấp độ', async () => {
  const service = recordingService();

  const response = await request(buildApp(service)).get('/api/kanji?level=N5&page=1');

  assert.deepEqual(response.body, { data: [KANJI], page: 1, limit: 20, total: 1, totalPages: 1 });
  assert.deepEqual(service.calls, [['list', { page: 1, limit: 20, level: 'N5' }]]);
  assert.equal((await request(buildApp(service)).get('/api/kanji?level=N6')).status, 400);
});

test('tìm kiếm trả `{ data, total }`; không thấy vẫn là 200 với mảng rỗng; thiếu từ khoá 400', async () => {
  const service = recordingService({ search: async () => [] });
  const app = buildApp(service);

  assert.deepEqual((await request(app).get('/api/kanji/search?keyword=%20学%20')).body, { data: [], total: 0 });
  assert.equal((await request(app).get('/api/kanji/search?keyword=')).status, 400);

  const found = recordingService();
  await request(buildApp(found)).get('/api/kanji/search?keyword=gaku&level=N4');
  assert.deepEqual(found.calls, [['search', { keyword: 'gaku', level: 'N4' }]]);
});

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

test('quản trị thêm chữ: 201, mặc định âm đọc rỗng; thiếu trường hay sai cấp độ là 400', async () => {
  const service = recordingService();
  const app = buildApp(service);
  const body = { character: ' 学 ', meaning: 'học', level: 'N5', lessonId: LESSON, onyomi: ['ガク'], hanviet: 'HỌC' };

  const response = await request(app).post('/api/kanji').send(body);

  assert.equal(response.status, 201);
  assert.deepEqual(response.body.data, KANJI);
  assert.deepEqual(service.calls, [['create', {
    character: '学', meaning: 'học', level: 'N5', lessonId: LESSON, hanviet: 'HỌC', onyomi: ['ガク'], kunyomi: [], examples: [],
  }]]);

  for (const invalid of [{ ...body, character: '' }, { ...body, level: 'N6' }, { ...body, lessonId: '' }, { ...body, onyomi: 'ガク' }]) {
    assert.equal((await request(app).post('/api/kanji').send(invalid)).status, 400, JSON.stringify(invalid));
  }
});

test('quản trị sửa chữ: chỉ gửi trường đổi; ô bài học bỏ trống là gỡ bài; body rỗng 400', async () => {
  const service = recordingService();
  const app = buildApp(service);

  await request(app).put(`/api/kanji/${ID}`).send({ meaning: 'học tập', lessonId: '' });

  assert.deepEqual(service.calls, [['update', ID, { meaning: 'học tập', lessonId: null }]]);
  assert.equal((await request(app).put(`/api/kanji/${ID}`).send({})).status, 400);
  assert.equal((await request(app).put('/api/kanji/abc').send({ meaning: 'x' })).status, 400);
});

test('quản trị nhập Excel: thiếu file 400; có file thì trả số chữ đã thêm', async () => {
  assert.equal((await request(buildApp(recordingService())).post('/api/kanji/upload')).status, 400);

  const service = recordingService();
  const buffer = Buffer.from('xlsx');
  const response = await request(buildApp(service, { file: { buffer } })).post('/api/kanji/upload');

  assert.equal(response.status, 201);
  assert.deepEqual(response.body.data, { insertedCount: 2 });
  assert.deepEqual(service.calls, [['importSheet', buffer]]);
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

test('thêm, sửa, nhập, xoá Kanji chỉ dành cho admin', async () => {
  const service = recordingService();
  const app = buildApp(service, { authenticateAsAdmin: denyAdmin, file: { buffer: Buffer.from('x') } });

  assert.equal((await request(app).post('/api/kanji').send({})).status, 403);
  assert.equal((await request(app).put(`/api/kanji/${ID}`).send({ meaning: 'x' })).status, 403);
  assert.equal((await request(app).post('/api/kanji/upload')).status, 403);
  assert.equal((await request(app).delete(`/api/kanji/${ID}`)).status, 403);
  assert.equal(service.calls.length, 0);
});

test('route không còn ai gọi đã bị bỏ', async () => {
  const app = buildApp(recordingService());

  assert.equal((await request(app).post(`/api/kanji/learn/${ID}`).send({})).status, 404);
  assert.equal((await request(app).get('/api/kanji/level/N5')).status, 404);
  assert.equal((await request(app).get(`/api/kanji/lesson/${LESSON}`)).status, 404);
});
