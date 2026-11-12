import assert from 'node:assert/strict';
import test from 'node:test';

import { createVocabularyMergeRepository } from '../src/modules/vocabulary/vocabulary-merge.repository.js';

/** Model giả: ghi lại lời gọi, trả kết quả cho sẵn theo tên hàm. */
const fakeModel = (name, calls, results = {}) => {
  const record = (method) => async (...args) => {
    calls.push([name, method, ...args]);
    return results[method] ?? { modifiedCount: 1, deletedCount: 1 };
  };
  return {
    updateMany: record('updateMany'),
    updateOne: record('updateOne'),
    deleteOne: record('deleteOne'),
    countDocuments: record('countDocuments'),
    distinct: record('distinct'),
  };
};

const setup = (results = {}) => {
  const calls = [];
  const models = Object.fromEntries(
    ['Vocabulary', 'Lesson', 'LessonProgress', 'SRSProgress', 'NoteBook'].map((name) => [
      name,
      fakeModel(name, calls, results[name]),
    ]),
  );
  return { calls, repository: createVocabularyMergeRepository(models) };
};

const FILTER = { _id: 'd1', word: '便利', hiragana: 'べんり', meaning: 'tiện lợi' };
const merge = (repository, over = {}) =>
  repository.merge({ fromId: 'd1', intoId: 'c1', lesson: 'L7', filter: FILTER, session: 'sess', ...over });

test('gộp chuyển mọi chỗ trỏ tới bản sao sang bản giữ lại, tại chỗ, trong cùng session', async () => {
  const { calls, repository } = setup();

  const moved = await merge(repository);

  const inPlace = { arrayFilters: [{ item: 'd1' }], session: 'sess' };
  assert.deepEqual(calls, [
    // Thay đúng vị trí trong danh sách từ của bài: thứ tự từ trong bài không đổi.
    ['Lesson', 'updateMany', { vocabularies: 'd1' }, { $set: { 'vocabularies.$[item]': 'c1' } }, inPlace],
    ['LessonProgress', 'updateMany', { learned_vocabulary_ids: 'd1' }, { $set: { 'learned_vocabulary_ids.$[item]': 'c1' } }, inPlace],
    ['SRSProgress', 'updateMany', { item_type: 'Vocabulary', item_id: 'd1' }, { $set: { item_id: 'c1' } }, { session: 'sess' }],
    ['NoteBook', 'updateMany', { related_item_id: 'd1' }, { $set: { related_item_id: 'c1' } }, { session: 'sess' }],
    ['NoteBook', 'updateMany', { 'items.item_id': 'd1' }, { $set: { 'items.$[entry].item_id': 'c1' } }, { arrayFilters: [{ 'entry.item_id': 'd1' }], session: 'sess' }],
    // Chỉ điền bài học khi bản giữ lại chưa thuộc bài nào — không cướp từ của bài khác.
    ['Vocabulary', 'updateOne', { _id: 'c1', lesson: null }, { $set: { lesson: 'L7' } }, { session: 'sess' }],
    ['Vocabulary', 'deleteOne', FILTER, { session: 'sess' }],
  ]);
  assert.deepEqual(moved, { lessons: 1, progresses: 1, cards: 1, notes: 2 });
});

test('bản sao không thuộc bài nào thì không đụng tới bài học của bản giữ lại', async () => {
  const { calls, repository } = setup();
  await merge(repository, { lesson: null });
  assert.equal(calls.some(([model, method]) => model === 'Vocabulary' && method === 'updateOne'), false);
});

test('bản sao đã đổi khác lúc soát thì ném lỗi để transaction huỷ mọi bước trước', async () => {
  const { repository } = setup({ Vocabulary: { deleteOne: { deletedCount: 0 } } });
  await assert.rejects(() => merge(repository), /便利 \(べんり\)/);
});

test('tìm chỗ cùng lúc trỏ tới cả hai bản — gộp ở đó sẽ sinh trùng', async () => {
  const { calls, repository } = setup({
    Lesson: { countDocuments: 1 },
    LessonProgress: { countDocuments: 0 },
    SRSProgress: { distinct: ['u1', 'u2'], countDocuments: 1 },
  });

  const overlaps = await repository.findOverlaps({ fromId: 'd1', intoId: 'c1' });

  assert.deepEqual(overlaps, { lessons: 1, progresses: 0, cards: 1 });
  assert.deepEqual(calls, [
    ['Lesson', 'countDocuments', { vocabularies: { $all: ['d1', 'c1'] } }],
    ['LessonProgress', 'countDocuments', { learned_vocabulary_ids: { $all: ['d1', 'c1'] } }],
    ['SRSProgress', 'distinct', 'user', { item_type: 'Vocabulary', item_id: 'd1' }],
    ['SRSProgress', 'countDocuments', { item_type: 'Vocabulary', item_id: 'c1', user: { $in: ['u1', 'u2'] } }],
  ]);
});

test('không ai ôn bản sao thì không cần hỏi thẻ của bản giữ lại', async () => {
  const { calls, repository } = setup({
    Lesson: { countDocuments: 0 },
    LessonProgress: { countDocuments: 0 },
    SRSProgress: { distinct: [] },
  });
  assert.deepEqual(await repository.findOverlaps({ fromId: 'd1', intoId: 'c1' }), { lessons: 0, progresses: 0, cards: 0 });
  assert.equal(calls.filter(([model]) => model === 'SRSProgress').length, 1);
});
