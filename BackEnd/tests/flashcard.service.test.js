import assert from 'node:assert/strict';
import test from 'node:test';

import { createFlashcardService } from '../src/modules/flashcards/flashcard.service.js';
import { ApiError } from '../src/shared/http/api-error.js';

const DECK = { _id: 'd1', title: 'N5', user: 'u1', cards: [], total_cards: 0 };

const fakeRepository = (results = {}) => {
  const calls = [];
  const repository = new Proxy({}, {
    get: (_target, name) => async (args) => {
      calls.push([name, args]);
      const result = results[name];
      return typeof result === 'function' ? result(args) : result;
    },
  });
  return { calls, repository };
};

const build = (results) => {
  const fake = fakeRepository(results);
  return { ...fake, service: createFlashcardService({ repository: fake.repository }) };
};

const notFound = (message) => (error) => {
  assert.ok(error instanceof ApiError);
  assert.equal(error.status, 404);
  assert.match(error.message, message);
  return true;
};

test('danh sách chỉ gồm bộ thẻ của chính người dùng, phân trang', async () => {
  const { calls, service } = build({ findPage: [DECK], count: 21 });

  assert.deepEqual(await service.listMine({ userId: 'u1', page: 2, limit: 20 }), { items: [DECK], total: 21, page: 2, limit: 20 });
  assert.deepEqual(calls, [
    ['findPage', { filter: { user: 'u1' }, skip: 20, limit: 20 }],
    ['count', { user: 'u1' }],
  ]);
});

test('xem bộ thẻ của mình hoặc bộ công khai; bộ riêng của người khác là 404', async () => {
  const { calls, service } = build({ findVisible: DECK });
  assert.equal(await service.detail({ userId: 'u1', id: 'd1' }), DECK);
  assert.deepEqual(calls, [['findVisible', { id: 'd1', userId: 'u1' }]]);

  await assert.rejects(build({ findVisible: null }).service.detail({ userId: 'u2', id: 'd1' }), notFound(/bộ thẻ/));
});

test('tạo bộ thẻ gắn với người đang đăng nhập; sửa, xoá chỉ trên bộ của mình', async () => {
  const { calls, service } = build({
    create: (doc) => ({ _id: 'd1', ...doc }),
    updateOwned: ({ set }) => ({ ...DECK, ...set }),
    deleteOwned: DECK,
  });

  await service.createDeck({ userId: 'u1', input: { title: 'N5', category: 'custom', is_public: false } });
  assert.equal((await service.updateDeck({ userId: 'u1', id: 'd1', changes: { title: 'N4' } })).title, 'N4');
  await service.removeDeck({ userId: 'u1', id: 'd1' });

  assert.deepEqual(calls, [
    ['create', { title: 'N5', category: 'custom', is_public: false, user: 'u1' }],
    ['updateOwned', { id: 'd1', userId: 'u1', set: { title: 'N4' } }],
    ['deleteOwned', { id: 'd1', userId: 'u1' }],
  ]);

  const { service: missing } = build({ updateOwned: null, deleteOwned: null });
  await assert.rejects(missing.updateDeck({ userId: 'u2', id: 'd1', changes: { title: 'x' } }), notFound(/bộ thẻ/));
  await assert.rejects(missing.removeDeck({ userId: 'u2', id: 'd1' }), notFound(/bộ thẻ/));
});

test('thêm, sửa, xoá thẻ trả bộ thẻ sau khi đổi', async () => {
  const card = { front: '学生', back: 'học sinh' };
  const updated = { ...DECK, cards: [{ _id: 'c1', ...card }], total_cards: 1 };
  const { calls, service } = build({ pushCard: updated, updateCard: updated, pullCard: DECK });

  assert.equal(await service.addCard({ userId: 'u1', deckId: 'd1', card }), updated);
  assert.equal(await service.updateCard({ userId: 'u1', deckId: 'd1', cardId: 'c1', changes: { back: 'sinh viên' } }), updated);
  assert.equal(await service.removeCard({ userId: 'u1', deckId: 'd1', cardId: 'c1' }), DECK);

  assert.deepEqual(calls, [
    ['pushCard', { id: 'd1', userId: 'u1', card }],
    ['updateCard', { id: 'd1', userId: 'u1', cardId: 'c1', changes: { back: 'sinh viên' } }],
    ['pullCard', { id: 'd1', userId: 'u1', cardId: 'c1' }],
  ]);
});

test('thẻ không có trong bộ và bộ không phải của mình báo đúng thứ không tìm thấy', async () => {
  const deckExists = build({ updateCard: null, pullCard: null, findOwned: DECK });
  await assert.rejects(
    deckExists.service.updateCard({ userId: 'u1', deckId: 'd1', cardId: 'c9', changes: { back: 'x' } }),
    notFound(/thẻ\./),
  );
  await assert.rejects(deckExists.service.removeCard({ userId: 'u1', deckId: 'd1', cardId: 'c9' }), notFound(/thẻ\./));

  const noDeck = build({ pushCard: null, pullCard: null, findOwned: null });
  await assert.rejects(noDeck.service.addCard({ userId: 'u2', deckId: 'd1', card: { front: 'a', back: 'b' } }), notFound(/bộ thẻ/));
  await assert.rejects(noDeck.service.removeCard({ userId: 'u2', deckId: 'd1', cardId: 'c1' }), notFound(/bộ thẻ/));
});

test('ghi một lượt học trên bộ xem được; bộ riêng của người khác không đếm được', async () => {
  const { calls, service } = build({ countStudy: { _id: 'd1', study_count: 4 } });

  assert.deepEqual(await service.recordStudy({ userId: 'u1', id: 'd1' }), { study_count: 4 });
  assert.deepEqual(calls, [['countStudy', { id: 'd1', userId: 'u1' }]]);

  await assert.rejects(build({ countStudy: null }).service.recordStudy({ userId: 'u2', id: 'd1' }), notFound(/bộ thẻ/));
});
