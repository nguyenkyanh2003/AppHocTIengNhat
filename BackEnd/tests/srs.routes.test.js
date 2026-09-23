import assert from 'node:assert/strict';
import test from 'node:test';

import express from 'express';
import request from 'supertest';

import { errorHandler, notFoundHandler } from '../src/middleware/error.middleware.js';
import { ApiError } from '../src/shared/http/api-error.js';
import { createSrsRoutes } from '../src/modules/srs/srs.routes.js';

const USER = { _id: 'user-1' };
const ITEM = '64b7f0c2a1b2c3d4e5f60718';
const OTHER_ITEM = '64b7f0c2a1b2c3d4e5f60719';
const DUE = '2026-09-19T03:00:00.123Z';

const passthrough = (req, _res, next) => {
  req.user = USER;
  next();
};

/** Router thật + service giả + auth giả: kiểm status và hình dạng response, không cần MongoDB. */
const buildApp = (service = {}) => {
  const app = express();
  app.use(express.json());
  app.use('/api/srs', createSrsRoutes({ service, authenticate: passthrough }));
  app.use(notFoundHandler);
  app.use(errorHandler);
  return app;
};

const recorder = (result) => {
  const calls = [];
  const fn = async (args) => {
    calls.push(args);
    return typeof result === 'function' ? result(args) : result;
  };
  fn.calls = calls;
  return fn;
};

test('GET /due trả đợt thẻ kèm limit, user lấy từ phiên đăng nhập', async () => {
  const dueBatch = recorder({ cards: [{ item_id: ITEM }], limit: 20 });
  const response = await request(buildApp({ dueBatch })).get('/api/srs/due');

  assert.equal(response.status, 200);
  assert.deepEqual(response.body, { data: [{ item_id: ITEM }], limit: 20 });
  assert.deepEqual(dueBatch.calls[0], {
    userId: 'user-1',
    itemType: 'Vocabulary',
    limit: 20,
    excludeItemIds: undefined,
  });
});

test('GET /due tách và loại trùng danh sách loại trừ', async () => {
  const dueBatch = recorder({ cards: [], limit: 5 });
  const response = await request(buildApp({ dueBatch })).get(
    `/api/srs/due?limit=5&exclude_item_ids=${ITEM},${OTHER_ITEM},${ITEM}`,
  );

  assert.equal(response.status, 200);
  assert.deepEqual(response.body, { data: [], limit: 5 });
  assert.deepEqual(dueBatch.calls[0].excludeItemIds, [ITEM, OTHER_ITEM]);
});

test('GET /due từ chối loại thẻ ngoài phạm vi, tham số lạ và giới hạn sai', async () => {
  const app = buildApp({ dueBatch: async () => assert.fail('không được gọi') });
  const tooMany = Array.from({ length: 201 }, (_, i) => i.toString(16).padStart(24, '0')).join(',');

  for (const query of [
    'item_type=Kanji',
    'item_type=Grammar',
    'item_type=vocabulary',
    'limit=0',
    'limit=101',
    'page=2',
    'exclude_item_ids=abc',
    `exclude_item_ids=${tooMany}`,
  ]) {
    assert.equal((await request(app).get(`/api/srs/due?${query}`)).status, 400, query);
  }
});

test('GET /due/count và /stats bọc kết quả trong data', async () => {
  const app = buildApp({
    dueCount: recorder({ item_type: 'Vocabulary', total: 4 }),
    stats: recorder({ item_type: 'Vocabulary', total_cards: 4, due_count: 1, by_box: { 1: 4 } }),
  });

  assert.deepEqual((await request(app).get('/api/srs/due/count')).body, {
    data: { item_type: 'Vocabulary', total: 4 },
  });
  const stats = await request(app).get('/api/srs/stats');
  assert.equal(stats.status, 200);
  assert.equal(stats.body.data.total_cards, 4);
});

test('POST /review chuyển boolean và mốc hạn ôn đã parse cho service', async () => {
  const review = recorder({ _id: 'p1', box: 2 });
  const response = await request(buildApp({ review }))
    .post('/api/srs/review')
    .send({ item_id: ITEM, is_correct: false, expected_next_review: DUE });

  assert.equal(response.status, 200);
  assert.deepEqual(response.body, { data: { _id: 'p1', box: 2 } });
  assert.deepEqual(review.calls[0], {
    userId: 'user-1',
    itemId: ITEM,
    itemType: 'Vocabulary',
    isCorrect: false,
    expectedNextReview: new Date(DUE),
  });
});

test('POST /review từ chối body sai kiểu, thiếu hạn ôn hoặc có trường lạ', async () => {
  const app = buildApp({ review: async () => assert.fail('không được gọi') });

  for (const body of [
    { item_id: ITEM, is_correct: 'true', expected_next_review: DUE },
    { item_id: ITEM, is_correct: true },
    { item_id: ITEM, is_correct: true, expected_next_review: '19/09/2026' },
    { item_id: ITEM, is_correct: true, expected_next_review: DUE, quality: 5 },
    { item_id: 'v1', is_correct: true, expected_next_review: DUE },
  ]) {
    assert.equal((await request(app).post('/api/srs/review').send(body)).status, 400, JSON.stringify(body));
  }
});

test('xung đột trả 409 kèm mã và tiến độ hiện tại', async () => {
  const current = { _id: 'p1', item_id: ITEM, item_type: 'Vocabulary', box: 2, next_review: DUE, streak: 1 };
  const app = buildApp({
    review: async () => {
      throw ApiError.conflict('Thẻ này chưa đến hạn ôn.', {
        code: 'SRS_NOT_DUE',
        details: { current_progress: current },
      });
    },
  });

  const response = await request(app)
    .post('/api/srs/review')
    .send({ item_id: ITEM, is_correct: true, expected_next_review: DUE });

  assert.equal(response.status, 409);
  assert.equal(response.body.code, 'SRS_NOT_DUE');
  assert.deepEqual(response.body.details, { current_progress: current });
});

test('POST /items/:itemId/reset và DELETE /items/:itemId dùng ID từ vựng trong path', async () => {
  const reset = recorder({ _id: 'p1', box: 1 });
  const remove = recorder({ deleted: true });
  const app = buildApp({ reset, remove });

  const resetResponse = await request(app)
    .post(`/api/srs/items/${ITEM}/reset`)
    .send({ expected_next_review: DUE });
  assert.equal(resetResponse.status, 200);
  assert.equal(reset.calls[0].itemId, ITEM);
  assert.deepEqual(reset.calls[0].expectedNextReview, new Date(DUE));

  const deleteResponse = await request(app).delete(`/api/srs/items/${ITEM}`);
  assert.deepEqual(deleteResponse.body, { data: { deleted: true } });
  assert.deepEqual(remove.calls[0], { userId: 'user-1', itemId: ITEM, itemType: 'Vocabulary' });

  assert.equal((await request(app).post('/api/srs/items/abc/reset').send({ expected_next_review: DUE })).status, 400);
  assert.equal((await request(app).delete(`/api/srs/items/${ITEM}?item_type=Kanji`)).status, 400);
});

test('các route cũ của module SRS đã bị bỏ', async () => {
  const app = buildApp();

  assert.equal((await request(app).get('/api/srs/my-cards')).status, 404);
  assert.equal((await request(app).post(`/api/srs/answer/${ITEM}`).send({ quality: 5 })).status, 404);
  assert.equal((await request(app).put(`/api/srs/reset/${ITEM}`)).status, 404);
  assert.equal((await request(app).get('/api/srs/admin/all')).status, 404);
  assert.equal((await request(app).get('/api/srs/admin/stats')).status, 404);
});
