import assert from 'node:assert/strict';
import test from 'node:test';

import express from 'express';
import request from 'supertest';

import { errorHandler } from '../src/middleware/error.middleware.js';
import { ApiError } from '../src/shared/http/api-error.js';
import { createLessonProgressRoutes } from '../src/modules/lesson-progress/lesson-progress.routes.js';

const USER_ID = '507f1f77bcf86cd799439011';
const LESSON_ID = '507f1f77bcf86cd799439012';
const ITEM_ID = '507f1f77bcf86cd799439013';

const passthrough = (req, _res, next) => {
  req.user = { _id: USER_ID };
  next();
};

/** App tối thiểu: router thật + service giả + auth giả, không cần MongoDB. */
const buildApp = (service) => {
  const app = express();
  app.use(express.json());
  app.use(
    '/api/lesson-progress',
    createLessonProgressRoutes({ service, authenticate: passthrough }),
  );
  app.use(errorHandler);
  return app;
};

const recordingService = (overrides = {}) => {
  const calls = [];
  const record = (name, result) => async (args) => {
    calls.push([name, args]);
    return result;
  };

  return {
    calls,
    getProgress: record('getProgress', { _id: 'p1', completed_vocabularies: 2 }),
    listProgress: record('listProgress', []),
    startLesson: record('startLesson', { _id: 'p1' }),
    updateItem: record('updateItem', { _id: 'p1' }),
    completeLesson: record('completeLesson', { _id: 'p1', is_completed: true }),
    resetLesson: record('resetLesson', { message: 'Đã reset tiến độ' }),
    getStats: record('getStats', { total_lessons: 0 }),
    getLevelStats: record('getLevelStats', { level: 'N5' }),
    ...overrides,
  };
};

test('lessonId sai định dạng bị chặn trước khi tới service', async () => {
  const service = recordingService();
  const app = buildApp(service);

  const response = await request(app).get('/api/lesson-progress/lesson/khong-phai-id');

  assert.equal(response.status, 400);
  assert.equal(response.body.code, 'VALIDATION_ERROR');
  assert.equal(service.calls.length, 0);
});

test('chưa có tiến độ trả về null chứ không phải 404', async () => {
  const service = recordingService({ getProgress: async () => null });
  const app = buildApp(service);

  const response = await request(app).get(`/api/lesson-progress/lesson/${LESSON_ID}`);

  assert.equal(response.status, 200);
  assert.equal(response.body, null);
});

test('update yêu cầu completed là boolean và item_type hợp lệ', async () => {
  const service = recordingService();
  const app = buildApp(service);

  const badBoolean = await request(app)
    .post(`/api/lesson-progress/lesson/${LESSON_ID}/update`)
    .send({ item_type: 'vocabulary', item_id: ITEM_ID, completed: 'false' });
  assert.equal(badBoolean.status, 400);

  const badType = await request(app)
    .post(`/api/lesson-progress/lesson/${LESSON_ID}/update`)
    .send({ item_type: 'listening', item_id: ITEM_ID, completed: true });
  assert.equal(badType.status, 400);

  const badItemId = await request(app)
    .post(`/api/lesson-progress/lesson/${LESSON_ID}/update`)
    .send({ item_type: 'vocabulary', item_id: 'x', completed: true });
  assert.equal(badItemId.status, 400);

  assert.equal(service.calls.length, 0);
});

test('update hợp lệ truyền đủ tham số đã ép kiểu cho service', async () => {
  const service = recordingService();
  const app = buildApp(service);

  const response = await request(app)
    .post(`/api/lesson-progress/lesson/${LESSON_ID}/update`)
    .send({ item_type: 'kanji', item_id: ITEM_ID, completed: true });

  assert.equal(response.status, 200);
  assert.deepEqual(service.calls, [
    [
      'updateItem',
      {
        userId: USER_ID,
        lessonId: LESSON_ID,
        itemType: 'kanji',
        itemId: ITEM_ID,
        completed: true,
      },
    ],
  ]);
});

test('hoàn thành bài trả về tiến độ đã cập nhật', async () => {
  const service = recordingService({
    completeLesson: async () => ({
      _id: 'p1',
      is_completed: true,
      completed_vocabularies: 3,
      total_vocabularies: 3,
      completed_at: new Date('2026-01-01T00:00:00.000Z'),
    }),
  });
  const app = buildApp(service);

  const response = await request(app).post(
    `/api/lesson-progress/lesson/${LESSON_ID}/complete`,
  );

  assert.equal(response.status, 200);
  assert.equal(response.body.is_completed, true);
  assert.equal(response.body.completed_vocabularies, 3);
  assert.equal(response.body.total_vocabularies, 3);
});

test('lỗi nghiệp vụ được dịch sang status tương ứng', async () => {
  const app = buildApp(
    recordingService({
      completeLesson: async () => {
        throw ApiError.notFound('Không tìm thấy tiến độ');
      },
    }),
  );

  const response = await request(app).post(
    `/api/lesson-progress/lesson/${LESSON_ID}/complete`,
  );

  assert.equal(response.status, 404);
  assert.equal(response.body.message, 'Không tìm thấy tiến độ');
});

test('level chỉ nhận giá trị trong bộ N5..N1', async () => {
  const service = recordingService();
  const app = buildApp(service);

  assert.equal((await request(app).get('/api/lesson-progress/level/N9')).status, 400);
  assert.equal((await request(app).get('/api/lesson-progress/level/N5')).status, 200);
});
