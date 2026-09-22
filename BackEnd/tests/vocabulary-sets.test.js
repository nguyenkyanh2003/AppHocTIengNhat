import assert from 'node:assert/strict';
import test from 'node:test';

import express from 'express';
import request from 'supertest';

import { errorHandler } from '../src/middleware/error.middleware.js';
import {
  buildSets,
  levelOfSetId,
  SET_SIZE,
} from '../src/modules/vocabulary/vocabulary-sets.js';
import { createVocabularyRoutes } from '../src/modules/vocabulary/vocabulary.routes.js';
import { createVocabularyService } from '../src/modules/vocabulary/vocabulary.service.js';

const words = (count, fields, prefix = 'w') =>
  Array.from({ length: count }, (_, index) => ({ _id: `${prefix}${index}`, ...fields }));

// --- chia bộ ---------------------------------------------------------------

test('N5 chia theo chủ đề, theo thứ tự chủ đề trong danh mục', () => {
  const sets = buildSets('N5', [
    ...words(3, { topic: 'food' }, 'f'),
    ...words(2, { topic: 'greet' }, 'g'),
  ]);

  assert.deepEqual(sets.map((set) => set.id), ['N5.greet.1', 'N5.food.1']);
  assert.equal(sets[0].title, 'Chào hỏi & giao tiếp');
  assert.equal(sets[0].section, null);
  assert.deepEqual(sets[1].wordIds, ['f0', 'f1', 'f2']);
});

test('nhóm lớn được cắt đều, không có bộ lẻ vài từ', () => {
  const sets = buildSets('N4', words(SET_SIZE + 3, { topic: 'work' }));

  assert.deepEqual(sets.map((set) => set.wordIds.length), [12, 11]);
  assert.deepEqual(sets.map((set) => [set.part, set.partCount]), [[1, 2], [2, 2]]);
});

test('tên riêng và từ chưa gắn chủ đề không vào bộ nào', () => {
  const sets = buildSets('N5', [
    ...words(2, { topic: 'proper' }, 'p'),
    ...words(1, {}, 'x'),
    ...words(1, { topic: 'time' }, 't'),
  ]);

  assert.deepEqual(sets.map((set) => set.id), ['N5.time.1']);
});

test('N3 chia theo độ khó trước, rồi đến từ loại', () => {
  const sets = buildSets('N3', [
    ...words(2, { word_type: 'v', difficulty: 2 }, 'a'),
    ...words(2, { word_type: 'v', difficulty: 1 }, 'b'),
    ...words(2, { word_type: 'n', difficulty: 1 }, 'c'),
  ]);

  assert.deepEqual(sets.map((set) => set.id), ['N3.1.n.1', 'N3.1.v.1', 'N3.2.v.1']);
  assert.deepEqual(sets.map((set) => [set.section, set.title]), [
    ['Cơ bản', 'Danh từ'],
    ['Cơ bản', 'Động từ'],
    ['Trung bình', 'Động từ'],
  ]);
});

test('N3 gộp tính từ い/な và gom từ loại hiếm thành một nhóm cuối', () => {
  const sets = buildSets('N3', [
    ...words(1, { word_type: 'conj', difficulty: 1 }, 'c'),
    ...words(1, { word_type: 'expr', difficulty: 3 }, 'e'),
    ...words(1, { word_type: 'ai', difficulty: 1 }, 'i'),
    ...words(1, { word_type: 'ana', difficulty: 1 }, 'a'),
  ]);

  assert.deepEqual(sets.map((set) => set.id), ['N3.1.adj.1', 'N3.x.other.1']);
  assert.deepEqual(sets[0].wordIds, ['i0', 'a0']);
  assert.equal(sets[1].section, 'Từ khác');
  assert.equal(levelOfSetId('N3.x.other.1'), 'N3');
});

test('đọc được cấp từ mã bộ, mã sai trả về null', () => {
  assert.equal(levelOfSetId('N5.food.2'), 'N5');
  assert.equal(levelOfSetId('N2.3.adv.1'), 'N2');
  assert.equal(levelOfSetId('N6.food.1'), null);
  assert.equal(levelOfSetId('food'), null);
});

// --- service ---------------------------------------------------------------

const buildService = ({ setFields, learned = [] }) => {
  const docs = new Map(setFields.map((word) => [word._id, { ...word, word: `từ ${word._id}` }]));
  return createVocabularyService({
    vocabularyRepository: {
      findSetFields: async () => setFields,
      findByIdsInOrder: async (ids) => ids.map((id) => docs.get(id)),
    },
    srsRepository: { findLearnedItemIds: async () => learned },
  });
};

test('danh sách bộ trả số từ và số từ đã học, không lộ danh sách id', async () => {
  const service = buildService({
    setFields: words(3, { topic: 'food' }),
    learned: ['w0', 'w2', 'không-thuộc-bộ'],
  });

  const [set] = await service.listSets({ userId: 'u1', level: 'N5' });

  assert.equal(set.wordCount, 3);
  assert.equal(set.learnedCount, 2);
  assert.equal(set.wordIds, undefined);
});

test('chi tiết bộ trả từ theo thứ tự học và đánh dấu từ đã học', async () => {
  const service = buildService({ setFields: words(2, { topic: 'food' }), learned: ['w1'] });

  const set = await service.getSet({ userId: 'u1', setId: 'N5.food.1' });

  assert.deepEqual(set.words.map((word) => [word._id, word.isLearned]), [
    ['w0', false],
    ['w1', true],
  ]);
  assert.equal(set.learnedCount, 1);
});

test('mã bộ không tồn tại trả 404', async () => {
  const service = buildService({ setFields: words(2, { topic: 'food' }) });

  await assert.rejects(
    service.getSet({ userId: 'u1', setId: 'N5.food.9' }),
    (error) => error.status === 404,
  );
});

// --- route -----------------------------------------------------------------

const buildApp = (service) => {
  const app = express();
  app.use(
    '/api/vocabulary',
    createVocabularyRoutes({
      service,
      authenticate: (req, _res, next) => {
        req.user = { _id: 'user-1' };
        next();
      },
    }),
  );
  app.use(errorHandler);
  return app;
};

test('GET /sets trả danh sách bộ, thiếu cấp độ là 400', async () => {
  let received = null;
  const app = buildApp({
    listSets: async (args) => {
      received = args;
      return [{ id: 'N5.food.1' }];
    },
  });

  const ok = await request(app).get('/api/vocabulary/sets?level=N5');
  assert.equal(ok.status, 200);
  assert.deepEqual(ok.body, { data: [{ id: 'N5.food.1' }], total: 1 });
  assert.deepEqual(received, { userId: 'user-1', level: 'N5' });

  const missing = await request(app).get('/api/vocabulary/sets');
  assert.equal(missing.status, 400);
});

test('GET /sets/:setId không bị route /:id bắt nhầm và kiểm mã bộ', async () => {
  const app = buildApp({
    getSet: async ({ setId }) => ({ id: setId, words: [] }),
  });

  const ok = await request(app).get('/api/vocabulary/sets/N3.1.v.2');
  assert.equal(ok.status, 200);
  assert.equal(ok.body.data.id, 'N3.1.v.2');

  const invalid = await request(app).get('/api/vocabulary/sets/abc');
  assert.equal(invalid.status, 400);
});
