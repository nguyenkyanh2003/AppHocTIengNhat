import assert from 'node:assert/strict';
import test from 'node:test';

import express from 'express';
import request from 'supertest';

import { errorHandler } from '../src/middleware/error.middleware.js';
import { ApiError } from '../src/shared/http/api-error.js';
import { createVocabularyRoutes } from '../src/modules/vocabulary/vocabulary.routes.js';

const VALID_ID = '507f1f77bcf86cd799439011';
const OTHER_ID = '507f1f77bcf86cd799439012';

const passthrough = (user) => (req, _res, next) => {
  req.user = user;
  next();
};

/** App tối thiểu: router thật + service giả + auth giả, không cần MongoDB. */
const buildApp = (service) => {
  const app = express();
  app.use(express.json());
  app.use(
    '/api/vocabulary',
    createVocabularyRoutes({
      service,
      authenticate: passthrough({ _id: 'user-1' }),
      authorizeAdmin: passthrough({ _id: 'admin-1', role: 'admin' }),
      uploadExcel: (_req, _res, next) => next(),
    }),
  );
  app.use(errorHandler);
  return app;
};

test('danh sách trả về đúng vỏ response phân trang', async () => {
  let received = null;
  const app = buildApp({
    list: async (args) => {
      received = args;
      return { items: [{ _id: VALID_ID }], page: 2, limit: 5, total: 11 };
    },
  });

  const response = await request(app).get('/api/vocabulary?page=2&limit=5');

  assert.equal(response.status, 200);
  assert.deepEqual(response.body, {
    data: [{ _id: VALID_ID }],
    page: 2,
    limit: 5,
    total: 11,
    totalPages: 3,
  });
  assert.deepEqual(received, {
    userId: 'user-1',
    page: 2,
    limit: 5,
  });
});

test('page/limit được ép kiểu số và có giá trị mặc định', async () => {
  let received = null;
  const app = buildApp({
    list: async (args) => {
      received = args;
      return { items: [], page: args.page, limit: args.limit, total: 0 };
    },
  });

  await request(app).get('/api/vocabulary');

  assert.equal(received.page, 1);
  assert.equal(received.limit, 20);
});

test('limit vượt trần bị từ chối bằng 400 thay vì tải cả bảng', async () => {
  const app = buildApp({ list: async () => assert.fail('không được gọi service') });

  const response = await request(app).get('/api/vocabulary?limit=100000');

  assert.equal(response.status, 400);
  assert.equal(response.body.code, 'VALIDATION_ERROR');
  assert.equal(response.body.details[0].path, 'limit');
});

test('studyStatus lạ bị từ chối', async () => {
  const app = buildApp({ list: async () => assert.fail('không được gọi service') });

  const response = await request(app).get('/api/vocabulary?studyStatus=maybe');

  assert.equal(response.status, 400);
});

test('tìm kiếm không có kết quả trả về 200 và mảng rỗng', async () => {
  const app = buildApp({ search: async () => [] });

  const response = await request(app).get('/api/vocabulary/search?keyword=zzz');

  assert.equal(response.status, 200);
  assert.deepEqual(response.body, { data: [], total: 0 });
});

test('tìm kiếm thiếu từ khoá trả về 400', async () => {
  const app = buildApp({ search: async () => assert.fail('không được gọi service') });

  const response = await request(app).get('/api/vocabulary/search');

  assert.equal(response.status, 400);
});

test('danh sách theo cấp độ rỗng vẫn là 200', async () => {
  const app = buildApp({ listByLevel: async () => [] });

  const response = await request(app).get('/api/vocabulary/level/N1');

  assert.equal(response.status, 200);
  assert.deepEqual(response.body, { data: [], total: 0 });
});

test('cấp độ không hợp lệ trả về 400', async () => {
  const app = buildApp({ listByLevel: async () => assert.fail('không được gọi') });

  const response = await request(app).get('/api/vocabulary/level/N9');

  assert.equal(response.status, 400);
});

test('chi tiết trả về { data } và nhận userId từ auth', async () => {
  let received = null;
  const app = buildApp({
    getById: async (args) => {
      received = args;
      return { _id: VALID_ID, isLearned: true };
    },
  });

  const response = await request(app).get(`/api/vocabulary/${VALID_ID}`);

  assert.equal(response.status, 200);
  assert.deepEqual(response.body, { data: { _id: VALID_ID, isLearned: true } });
  assert.deepEqual(received, { id: VALID_ID, userId: 'user-1' });
});

test('id sai định dạng trả về 400 trước khi chạm service', async () => {
  const app = buildApp({ getById: async () => assert.fail('không được gọi') });

  const response = await request(app).get('/api/vocabulary/not-an-id');

  assert.equal(response.status, 400);
});

test('ApiError từ service được dịch sang đúng status', async () => {
  const app = buildApp({
    getById: async () => {
      throw ApiError.notFound('Không tìm thấy từ vựng.');
    },
  });

  const response = await request(app).get(`/api/vocabulary/${VALID_ID}`);

  assert.equal(response.status, 404);
  assert.equal(response.body.message, 'Không tìm thấy từ vựng.');
});

test('lỗi không lường trước vẫn là 500 với message chung', async () => {
  const app = buildApp({
    getById: async () => {
      throw new Error('mongo down');
    },
  });

  const response = await request(app).get(`/api/vocabulary/${VALID_ID}`);

  assert.equal(response.status, 500);
  assert.equal(response.body.message, 'Đã có lỗi xảy ra ở máy chủ');
});

test('tạo từ vựng trả về 201 kèm data và message', async () => {
  const app = buildApp({ create: async (payload) => ({ _id: VALID_ID, ...payload }) });

  const response = await request(app)
    .post('/api/vocabulary')
    .send({
      lesson: OTHER_ID,
      word: '学生',
      hiragana: 'がくせい',
      meaning: 'học sinh',
      level: 'N5',
    });

  assert.equal(response.status, 201);
  assert.equal(response.body.message, 'Thêm từ vựng thành công');
  assert.equal(response.body.data.word, '学生');
  assert.deepEqual(response.body.data.examples, []);
});

test('tạo từ vựng thiếu trường bắt buộc trả về 400 kèm chi tiết', async () => {
  const app = buildApp({ create: async () => assert.fail('không được gọi') });

  const response = await request(app)
    .post('/api/vocabulary')
    .send({ word: '学生' });

  assert.equal(response.status, 400);
  const paths = response.body.details.map((detail) => detail.path);
  assert.ok(paths.includes('lesson'));
  assert.ok(paths.includes('meaning'));
});

test('cập nhật chỉ gửi field cần đổi, không tự chèn mảng rỗng', async () => {
  let received = null;
  const app = buildApp({
    update: async (id, payload) => {
      received = { id, payload };
      return { _id: id, ...payload };
    },
  });

  const response = await request(app)
    .put(`/api/vocabulary/${VALID_ID}`)
    .send({ meaning: 'nghĩa mới' });

  assert.equal(response.status, 200);
  assert.deepEqual(received.payload, { meaning: 'nghĩa mới' });
});

test('xoá nhiều cần danh sách id hợp lệ', async () => {
  const app = buildApp({ removeMany: async (ids) => ids.length });

  const rejected = await request(app).delete('/api/vocabulary').send({ ids: [] });
  assert.equal(rejected.status, 400);

  const accepted = await request(app)
    .delete('/api/vocabulary')
    .send({ ids: [VALID_ID, OTHER_ID] });

  assert.equal(accepted.status, 200);
  assert.deepEqual(accepted.body.data, { deletedCount: 2 });
});

test('đánh dấu đã học trả về tiến độ và message', async () => {
  const app = buildApp({
    markLearned: async ({ id, userId }) => ({
      progress: { item_id: id, user: userId, box: 1 },
      created: true,
      message: 'Đã đánh dấu từ vựng là đã học.',
    }),
  });

  const response = await request(app).post(
    `/api/vocabulary/${VALID_ID}/mark-learned`,
  );

  assert.equal(response.status, 200);
  assert.equal(response.body.message, 'Đã đánh dấu từ vựng là đã học.');
  assert.equal(response.body.data.box, 1);
});

test('bỏ đánh dấu đã học trả về message', async () => {
  const app = buildApp({ unmarkLearned: async () => undefined });

  const response = await request(app).delete(
    `/api/vocabulary/${VALID_ID}/mark-learned`,
  );

  assert.equal(response.status, 200);
  assert.deepEqual(response.body, { message: 'Đã xóa đánh dấu đã học.' });
});

test('học từ vựng trong bài học yêu cầu lessonId', async () => {
  const app = buildApp({
    learnInLesson: async ({ lessonId }) => ({
      message: 'ok',
      redirect: `/lesson-progress/lesson/${lessonId}/update`,
    }),
  });

  const missing = await request(app)
    .post(`/api/vocabulary/learn/${VALID_ID}`)
    .send({});
  assert.equal(missing.status, 400);

  const accepted = await request(app)
    .post(`/api/vocabulary/learn/${VALID_ID}`)
    .send({ lessonId: OTHER_ID });

  assert.equal(accepted.status, 200);
  assert.equal(
    accepted.body.redirect,
    `/lesson-progress/lesson/${OTHER_ID}/update`,
  );
});

test('import Excel không kèm file trả về 400', async () => {
  const app = buildApp({ importFromExcel: async () => assert.fail('không được gọi') });

  const response = await request(app)
    .post('/api/vocabulary/upload')
    .send({ lesson: OTHER_ID, level: 'N5' });

  assert.equal(response.status, 400);
  assert.equal(response.body.message, 'Vui lòng upload file Excel.');
});
