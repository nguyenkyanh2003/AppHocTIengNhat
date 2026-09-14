import assert from 'node:assert/strict';
import test from 'node:test';

import express from 'express';
import request from 'supertest';

import { errorHandler } from '../src/middleware/error.middleware.js';
import { ApiError } from '../src/shared/http/api-error.js';
import { createLessonRoutes } from '../src/modules/lessons/lesson.routes.js';

const VALID_ID = '507f1f77bcf86cd799439011';

const passthrough = (user) => (req, _res, next) => {
  req.user = user;
  next();
};

/** App tối thiểu: router thật + service giả + auth giả, không cần MongoDB. Mount path khớp app.js thật (`/api/lesson`, số ít). */
const buildApp = (service) => {
  const app = express();
  app.use(express.json());
  app.use(
    '/api/lesson',
    createLessonRoutes({
      service,
      authenticate: passthrough({ _id: 'user-1' }),
      authorizeAdmin: passthrough({ _id: 'admin-1', role: 'admin' }),
    }),
  );
  app.use(errorHandler);
  return app;
};

test('GET / giữ đúng vỏ response cũ totalItems/totalPages/currentPage/data', async () => {
  const app = buildApp({
    list: async () => ({ items: [{ _id: 'l1' }], page: 2, limit: 5, total: 11, totalPages: 3 }),
  });

  const response = await request(app).get('/api/lesson?page=2&limit=5');

  assert.equal(response.status, 200);
  assert.deepEqual(response.body, {
    totalItems: 11,
    totalPages: 3,
    currentPage: 2,
    data: [{ _id: 'l1' }],
  });
});

test('GET /?situation=supermarket chưa có bài nào vẫn là 200 và mảng rỗng', async () => {
  const app = buildApp({
    list: async () => ({ items: [], page: 1, limit: 10, total: 0, totalPages: 0 }),
  });

  const response = await request(app).get('/api/lesson?situation=supermarket');

  assert.equal(response.status, 200);
  assert.deepEqual(response.body.data, []);
});

test('GET /?situation=khong-hop-le bị chặn 400 trước khi tới service', async () => {
  const app = buildApp({ list: async () => assert.fail('không được gọi service') });

  const response = await request(app).get('/api/lesson?situation=khong-hop-le');

  assert.equal(response.status, 400);
  assert.equal(response.body.code, 'VALIDATION_ERROR');
});

test('limit vượt trần bị từ chối bằng 400', async () => {
  const app = buildApp({ list: async () => assert.fail('không được gọi service') });

  const response = await request(app).get('/api/lesson?limit=100000');

  assert.equal(response.status, 400);
});

test('GET /:id trả object phẳng kèm tuvungs/nguphaps như hành vi cũ', async () => {
  const app = buildApp({
    getDetail: async () => ({
      _id: 'l1',
      title: 'Bài 1',
      vocabularies: [{ _id: 'v1' }],
      grammars: [],
      kanjis: [],
      tuvungs: [{ _id: 'v1' }],
      nguphaps: [],
    }),
  });

  const response = await request(app).get(`/api/lesson/${VALID_ID}`);

  assert.equal(response.status, 200);
  assert.equal(response.body._id, 'l1');
  assert.deepEqual(response.body.tuvungs, [{ _id: 'v1' }]);
  assert.equal(response.body.data, undefined, 'không được bọc thêm data ở route này');
});

test('GET /:id với id không phải ObjectId bị chặn 400', async () => {
  const app = buildApp({ getDetail: async () => assert.fail('không được gọi service') });

  const response = await request(app).get('/api/lesson/khong-phai-object-id');

  assert.equal(response.status, 400);
});

test('GET /level/:capDo với cấp độ lạ bị chặn 400', async () => {
  const app = buildApp({ getByLevel: async () => assert.fail('không được gọi service') });

  const response = await request(app).get('/api/lesson/level/N9');

  assert.equal(response.status, 400);
});

test('GET /level/:capDo rỗng vẫn là 200 và mảng rỗng', async () => {
  const app = buildApp({ getByLevel: async () => [] });

  const response = await request(app).get('/api/lesson/level/N5');

  assert.equal(response.status, 200);
  assert.deepEqual(response.body, { data: [], total: 0 });
});

test('GET /type/:loaiBaiHoc rỗng vẫn là 200 và mảng rỗng', async () => {
  const app = buildApp({ getByType: async () => [] });

  const response = await request(app).get('/api/lesson/type/ngu-phap');

  assert.equal(response.status, 200);
  assert.deepEqual(response.body, { data: [], total: 0 });
});

test('GET /stats/overview trả đúng vỏ phẳng cũ, không bọc trong data', async () => {
  const app = buildApp({
    getStatsOverview: async () => ({ totalLessons: 3, byLevel: [], byType: [] }),
  });

  const response = await request(app).get('/api/lesson/stats/overview');

  assert.equal(response.status, 200);
  assert.deepEqual(response.body, { totalLessons: 3, byLevel: [], byType: [] });
});

test('POST / tạo bài học kèm situation hợp lệ, trả 201', async () => {
  let received = null;
  const app = buildApp({
    create: async (input) => { received = input; return { _id: 'l1', ...input }; },
  });

  const response = await request(app)
    .post('/api/lesson')
    .send({ title: 'Đi siêu thị', level: 'N5', situation: 'supermarket' });

  assert.equal(response.status, 201);
  assert.equal(received.situation, 'supermarket');
  assert.equal(response.body.data.situation, 'supermarket');
});

test('POST / với situation không nằm trong danh mục bị chặn 400', async () => {
  const app = buildApp({ create: async () => assert.fail('không được gọi service') });

  const response = await request(app)
    .post('/api/lesson')
    .send({ title: 'Bài x', level: 'N5', situation: 'mat_trang' });

  assert.equal(response.status, 400);
});

test('POST / vẫn nhận tên field di sản TenBaiHoc/CapDo như trước khi tách tầng', async () => {
  let received = null;
  const app = buildApp({
    create: async (input) => { received = input; return { _id: 'l1', ...input }; },
  });

  const response = await request(app)
    .post('/api/lesson')
    .send({ TenBaiHoc: 'Bài cũ', CapDo: 'N5' });

  assert.equal(response.status, 201);
  assert.equal(received.title, 'Bài cũ');
  assert.equal(received.level, 'N5');
});

test('POST / thiếu title/level bị chặn 400', async () => {
  const app = buildApp({ create: async () => assert.fail('không được gọi service') });

  const response = await request(app).post('/api/lesson').send({ level: 'N5' });

  assert.equal(response.status, 400);
});

test('POST /bulk tạo nhiều bài, giới hạn 1-100 phần tử', async () => {
  const app = buildApp({
    createMany: async (inputs) => inputs.map((item, index) => ({ _id: `l${index}`, ...item })),
  });

  const ok = await request(app)
    .post('/api/lesson/bulk')
    .send({ lessons: [{ title: 'A', level: 'N5' }, { title: 'B', level: 'N4' }] });
  assert.equal(ok.status, 201);
  assert.equal(ok.body.data.length, 2);

  const empty = await request(app).post('/api/lesson/bulk').send({ lessons: [] });
  assert.equal(empty.status, 400);
});

test('PUT /:id và PATCH /:id gọi cùng một service.update', async () => {
  const calls = [];
  const app = buildApp({
    update: async (id, body) => { calls.push([id, body]); return { _id: id, ...body }; },
  });

  const put = await request(app).put(`/api/lesson/${VALID_ID}`).send({ title: 'A' });
  const patch = await request(app).patch(`/api/lesson/${VALID_ID}`).send({ title: 'B' });

  assert.equal(put.status, 200);
  assert.equal(patch.status, 200);
  assert.equal(calls.length, 2);
});

test('DELETE /:id còn tham chiếu trả 409 kèm details', async () => {
  const app = buildApp({
    remove: async () => {
      throw ApiError.conflict('Không thể xóa bài học đang có nội dung liên quan.', {
        details: { vocabulary: 2, kanji: 0, grammar: 0 },
      });
    },
  });

  const response = await request(app).delete(`/api/lesson/${VALID_ID}`);

  assert.equal(response.status, 409);
  assert.deepEqual(response.body.details, { vocabulary: 2, kanji: 0, grammar: 0 });
});

test('DELETE / xóa nhiều — vỏ response không có key data, giữ đúng hành vi cũ', async () => {
  const app = buildApp({ removeMany: async () => 3 });

  const response = await request(app)
    .delete('/api/lesson')
    .send({ ids: [VALID_ID] });

  assert.equal(response.status, 200);
  assert.deepEqual(response.body, { message: 'Xóa thành công 3 bài học.', deletedCount: 3 });
});

test('POST /:id/duplicate trả 201 kèm data', async () => {
  const app = buildApp({
    duplicate: async (id) => ({ _id: 'l2', title: `Bài (Bản sao) từ ${id}` }),
  });

  const response = await request(app).post(`/api/lesson/${VALID_ID}/duplicate`);

  assert.equal(response.status, 201);
  assert.equal(response.body.data._id, 'l2');
});
