import assert from 'node:assert/strict';
import test from 'node:test';

import express from 'express';
import request from 'supertest';

import { errorHandler, notFoundHandler } from '../src/middleware/error.middleware.js';
import { createFlashcardRoutes } from '../src/modules/flashcards/flashcard.routes.js';
import { ApiError } from '../src/shared/http/api-error.js';

const DECK_ID = '507f1f77bcf86cd799439011';
const CARD_ID = '507f1f77bcf86cd799439012';
const DECK = { _id: DECK_ID, title: 'N5', cards: [] };

const buildApp = (service) => {
  const app = express();
  app.use(express.json());
  app.use('/api/flashcard', createFlashcardRoutes({
    service,
    authenticate: (req, _res, next) => { req.user = { _id: 'user-1' }; next(); },
  }));
  app.use(notFoundHandler);
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

test('GET /decks trả trang bộ thẻ của mình theo contract phân trang', async () => {
  const { calls, service } = recording({ listMine: { items: [DECK], total: 1, page: 1, limit: 20 } });

  const response = await request(buildApp(service)).get('/api/flashcard/decks');

  assert.deepEqual(response.body, { data: [DECK], page: 1, limit: 20, total: 1, totalPages: 1 });
  assert.deepEqual(calls, [['listMine', { userId: 'user-1', page: 1, limit: 20 }]]);
});

test('GET /decks/:id bọc chi tiết trong `data`; id sai 400; không xem được 404', async () => {
  const { calls, service } = recording({ detail: DECK });
  const app = buildApp(service);

  assert.deepEqual((await request(app).get(`/api/flashcard/decks/${DECK_ID}`)).body, { data: DECK });
  assert.equal((await request(app).get('/api/flashcard/decks/abc')).status, 400);
  assert.deepEqual(calls, [['detail', { userId: 'user-1', id: DECK_ID }]]);

  const missing = buildApp(recording({ detail: ApiError.notFound('Không tìm thấy bộ thẻ.') }).service);
  assert.equal((await request(missing).get(`/api/flashcard/decks/${DECK_ID}`)).status, 404);
});

test('POST /decks: 201 kèm mặc định; thiếu tiêu đề, danh mục hay cấp độ lạ là 400; chủ bộ lấy từ phiên', async () => {
  const { calls, service } = recording({ createDeck: DECK });
  const app = buildApp(service);

  const response = await request(app).post('/api/flashcard/decks').send({ title: ' N5 ', user: 'someone-else' });

  assert.equal(response.status, 201);
  assert.deepEqual(calls, [['createDeck', {
    userId: 'user-1',
    input: { title: 'N5', is_public: false, category: 'custom' },
  }]]);

  for (const invalid of [{ title: ' ' }, { title: 'a', category: 'music' }, { title: 'a', level: 'N6' }]) {
    assert.equal((await request(app).post('/api/flashcard/decks').send(invalid)).status, 400, JSON.stringify(invalid));
  }
});

test('PUT và DELETE /decks/:id sửa, xoá bộ của mình; body rỗng 400', async () => {
  const { calls, service } = recording({ updateDeck: DECK, removeDeck: undefined });
  const app = buildApp(service);

  await request(app).put(`/api/flashcard/decks/${DECK_ID}`).send({ title: 'N4', description: '' });
  assert.deepEqual((await request(app).delete(`/api/flashcard/decks/${DECK_ID}`)).body.data, { deleted: true });
  assert.equal((await request(app).put(`/api/flashcard/decks/${DECK_ID}`).send({})).status, 400);

  assert.deepEqual(calls, [
    ['updateDeck', { userId: 'user-1', id: DECK_ID, changes: { title: 'N4', description: '' } }],
    ['removeDeck', { userId: 'user-1', id: DECK_ID }],
  ]);
});

test('thẻ: thêm 201, sửa, xoá đều trả bộ thẻ sau khi đổi; phụ đề null là xoá phụ đề', async () => {
  const { calls, service } = recording({ addCard: DECK, updateCard: DECK, removeCard: DECK });
  const app = buildApp(service);

  const added = await request(app).post(`/api/flashcard/decks/${DECK_ID}/cards`).send({ front: '学生', back: 'học sinh', front_subtext: 'がくせい' });
  assert.equal(added.status, 201);
  assert.deepEqual(added.body.data, DECK);

  await request(app).put(`/api/flashcard/decks/${DECK_ID}/cards/${CARD_ID}`).send({ back: 'sinh viên', back_subtext: null });
  assert.deepEqual((await request(app).delete(`/api/flashcard/decks/${DECK_ID}/cards/${CARD_ID}`)).body.data, DECK);

  assert.deepEqual(calls, [
    ['addCard', { userId: 'user-1', deckId: DECK_ID, card: { front: '学生', back: 'học sinh', front_subtext: 'がくせい' } }],
    ['updateCard', { userId: 'user-1', deckId: DECK_ID, cardId: CARD_ID, changes: { back: 'sinh viên', back_subtext: null } }],
    ['removeCard', { userId: 'user-1', deckId: DECK_ID, cardId: CARD_ID }],
  ]);
});

test('thẻ thiếu mặt trước/sau hay id thẻ sai là 400', async () => {
  const { calls, service } = recording({ addCard: DECK, updateCard: DECK });
  const app = buildApp(service);

  assert.equal((await request(app).post(`/api/flashcard/decks/${DECK_ID}/cards`).send({ front: '学生' })).status, 400);
  assert.equal((await request(app).put(`/api/flashcard/decks/${DECK_ID}/cards/abc`).send({ back: 'x' })).status, 400);
  assert.equal((await request(app).put(`/api/flashcard/decks/${DECK_ID}/cards/${CARD_ID}`).send({})).status, 400);
  assert.deepEqual(calls, []);
});

test('POST /decks/:id/study ghi một lượt học; tìm bộ thẻ đã bị gỡ', async () => {
  const { calls, service } = recording({ recordStudy: { study_count: 3 } });
  const app = buildApp(service);

  assert.deepEqual((await request(app).post(`/api/flashcard/decks/${DECK_ID}/study`)).body, { data: { study_count: 3 } });
  assert.deepEqual(calls, [['recordStudy', { userId: 'user-1', id: DECK_ID }]]);
  assert.equal((await request(app).get('/api/flashcard/decks/search?keyword=N5')).status, 400, '"search" giờ chỉ là một id sai');
});
