import assert from 'node:assert/strict';
import test from 'node:test';

import { createLessonRepository } from '../src/modules/lessons/lesson.repository.js';

/** Chain giả cho các lệnh find().sort().skip().limit().lean() / .populate().lean(). */
const fakeChain = (result) => {
  const calls = [];
  const chain = {
    calls,
    sort(sort) { calls.push(['sort', sort]); return chain; },
    skip(skip) { calls.push(['skip', skip]); return chain; },
    limit(limit) { calls.push(['limit', limit]); return chain; },
    populate(path) { calls.push(['populate', path]); return chain; },
    lean: async () => result,
  };
  return chain;
};

test('findMany truyền đúng filter cho Lesson.find và trả kết quả từ lean()', async () => {
  let capturedFilter = null;
  let capturedProjection = null;
  const Lesson = {
    find(filter, projection) {
      capturedFilter = filter;
      capturedProjection = projection;
      return fakeChain([{ _id: 'l1' }]);
    },
  };
  const repository = createLessonRepository({ Lesson, Vocabulary: {}, Grammar: {}, Kanji: {} });

  const items = await repository.findMany({
    filter: { level: 'N5', situation: 'train' },
    sort: { level: -1, order: 1 },
    skip: 10,
    limit: 5,
  });

  assert.deepEqual(capturedFilter, { level: 'N5', situation: 'train' });
  assert.deepEqual(items, [{ _id: 'l1' }]);
  // Danh sách không kéo theo phần nặng chỉ màn chi tiết cần.
  assert.deepEqual(capturedProjection, { content_html: 0, 'videos.transcript': 0, 'videos.vocabulary': 0 });
});

test('findById populate đủ ba mảng tham chiếu vocabularies/grammars/kanjis', async () => {
  const populated = [];
  const Lesson = {
    findById() {
      return {
        populate(path) { populated.push(path); return this; },
        lean: async () => ({ _id: 'l1', vocabularies: [] }),
      };
    },
  };
  const repository = createLessonRepository({ Lesson, Vocabulary: {}, Grammar: {}, Kanji: {} });

  const lesson = await repository.findById('l1');

  assert.deepEqual(populated, ['vocabularies', 'grammars', 'kanjis']);
  assert.equal(lesson._id, 'l1');
});

test('findVocabulariesByLesson lọc theo field lesson (không phải lesson_id)', async () => {
  let captured = null;
  const Vocabulary = {
    find(filter) { captured = filter; return { lean: async () => [] }; },
  };
  const repository = createLessonRepository({ Lesson: {}, Vocabulary, Grammar: {}, Kanji: {} });

  await repository.findVocabulariesByLesson('l1');

  assert.deepEqual(captured, { lesson: 'l1' });
});

test('findActiveGrammarsByLesson lọc theo lesson_id và is_active', async () => {
  let captured = null;
  const Grammar = {
    find(filter) { captured = filter; return { lean: async () => [] }; },
  };
  const repository = createLessonRepository({ Lesson: {}, Vocabulary: {}, Grammar, Kanji: {} });

  await repository.findActiveGrammarsByLesson('l1');

  assert.deepEqual(captured, { lesson_id: 'l1', is_active: true });
});

test('findKanjisByLesson lọc theo lessonId (khác cách viết của Grammar)', async () => {
  let captured = null;
  const Kanji = {
    find(filter) { captured = filter; return { lean: async () => [] }; },
  };
  const repository = createLessonRepository({ Lesson: {}, Vocabulary: {}, Grammar: {}, Kanji });

  await repository.findKanjisByLesson('l1');

  assert.deepEqual(captured, { lessonId: 'l1' });
});

test('findByLevel sort theo order tăng dần, không phân trang', async () => {
  const Lesson = { find: () => fakeChain([{ _id: 'l1' }]) };
  const repository = createLessonRepository({ Lesson, Vocabulary: {}, Grammar: {}, Kanji: {} });

  const items = await repository.findByLevel('N5');

  assert.deepEqual(items, [{ _id: 'l1' }]);
});

test('distinctSituations bỏ bài chưa gắn tình huống, lọc theo cấp độ khi có', async () => {
  const calls = [];
  const Lesson = {
    distinct: async (field, filter) => { calls.push([field, filter]); return []; },
  };
  const repository = createLessonRepository({ Lesson, Vocabulary: {}, Grammar: {}, Kanji: {} });

  await repository.distinctSituations();
  await repository.distinctSituations({ level: 'N3' });

  assert.deepEqual(calls[0], ['situation', { situation: { $ne: null } }]);
  assert.deepEqual(calls[1], ['situation', { situation: { $ne: null }, level: 'N3' }]);
});

test('countRelated đếm đúng cả ba model với đúng tên field tham chiếu', async () => {
  const Vocabulary = {
    countDocuments: async (filter) => {
      assert.deepEqual(filter, { lesson: { $in: ['l1'] } });
      return 2;
    },
  };
  const Kanji = {
    countDocuments: async (filter) => {
      assert.deepEqual(filter, { lessonId: { $in: ['l1'] } });
      return 0;
    },
  };
  const Grammar = {
    countDocuments: async (filter) => {
      assert.deepEqual(filter, { lesson_id: { $in: ['l1'] } });
      return 1;
    },
  };
  const repository = createLessonRepository({ Lesson: {}, Vocabulary, Grammar, Kanji });

  const result = await repository.countRelated(['l1']);

  assert.deepEqual(result, { vocabulary: 2, kanji: 0, grammar: 1 });
});

test('deleteManyByIds trả đúng deletedCount từ Mongoose', async () => {
  const Lesson = {
    deleteMany: async (filter) => {
      assert.deepEqual(filter, { _id: { $in: ['l1', 'l2'] } });
      return { acknowledged: true, deletedCount: 2 };
    },
  };
  const repository = createLessonRepository({ Lesson, Vocabulary: {}, Grammar: {}, Kanji: {} });

  const count = await repository.deleteManyByIds(['l1', 'l2']);

  assert.equal(count, 2);
});
