import assert from 'node:assert/strict';
import test from 'node:test';

import { createLessonService } from '../src/modules/lessons/lesson.service.js';

const fakeRepository = (overrides = {}) => ({
  findMany: async () => [],
  count: async () => 0,
  findById: async () => null,
  findVocabulariesByLesson: async () => [],
  findActiveGrammarsByLesson: async () => [],
  findKanjisByLesson: async () => [],
  findByLevel: async () => [],
  distinctSituations: async () => [],
  findByTypePattern: async () => [],
  aggregateStats: async () => ({ totalLessons: 0, byLevel: [], byType: [] }),
  create: async (input) => ({ _id: 'new', ...input }),
  createMany: async (inputs) => inputs.map((item, index) => ({ _id: `n${index}`, ...item })),
  updateById: async () => null,
  findByIdLean: async () => null,
  deleteById: async () => null,
  deleteManyByIds: async () => 0,
  countRelated: async () => ({ vocabulary: 0, kanji: 0, grammar: 0 }),
  ...overrides,
});

test('list dựng filter theo level/type/situation/search và tính totalPages', async () => {
  let captured = null;
  const repository = fakeRepository({
    findMany: async (args) => { captured = args; return [{ _id: 'l1' }]; },
    count: async () => 12,
  });
  const service = createLessonService({ lessonRepository: repository });

  const result = await service.list({
    page: 2,
    limit: 5,
    level: 'N5',
    type: 'ngữ pháp',
    situation: 'train',
    search: 'tàu',
  });

  assert.equal(captured.filter.level, 'N5');
  assert.equal(captured.filter.situation, 'train');
  assert.deepEqual(captured.filter.type, { $regex: 'ngữ pháp', $options: 'i' });
  assert.deepEqual(captured.filter.$or, [
    { title: { $regex: 'tàu', $options: 'i' } },
    { description: { $regex: 'tàu', $options: 'i' } },
  ]);
  assert.equal(captured.skip, 5);
  assert.equal(captured.limit, 5);
  assert.equal(result.total, 12);
  assert.equal(result.totalPages, 3);
  assert.deepEqual(result.items, [{ _id: 'l1' }]);
});

test('list không lọc situation khi không truyền — không loại bài chưa gắn tình huống', async () => {
  let captured = null;
  const repository = fakeRepository({
    findMany: async (args) => { captured = args; return []; },
  });
  const service = createLessonService({ lessonRepository: repository });

  await service.list({ page: 1, limit: 10 });

  assert.ok(!('situation' in captured.filter));
  assert.ok(!('level' in captured.filter));
});

test('listSituations chỉ trả tình huống có bài, đã sort', async () => {
  const repository = fakeRepository({
    distinctSituations: async () => ['train', 'restaurant', 'supermarket'],
  });
  const service = createLessonService({ lessonRepository: repository });

  const situations = await service.listSituations();

  assert.deepEqual(situations, ['restaurant', 'supermarket', 'train']);
});

test('listSituations chuyển cấp độ xuống repository để chỉ trả chủ đề có bài ở cấp đó', async () => {
  let received = null;
  const repository = fakeRepository({
    distinctSituations: async (args) => { received = args; return ['bus']; },
  });
  const service = createLessonService({ lessonRepository: repository });

  const situations = await service.listSituations({ level: 'N4' });

  assert.deepEqual(received, { level: 'N4' });
  assert.deepEqual(situations, ['bus']);
});

test('listSituations trả mảng rỗng khi chưa bài nào gắn tình huống', async () => {
  const service = createLessonService({ lessonRepository: fakeRepository() });

  assert.deepEqual(await service.listSituations(), []);
});

test('getDetail báo 404 khi không tìm thấy bài học', async () => {
  const service = createLessonService({ lessonRepository: fakeRepository() });

  await assert.rejects(service.getDetail('missing'), (error) => error.status === 404);
});

test('getDetail dùng fallback query khi mảng tham chiếu rỗng, và gắn alias tuvungs/nguphaps', async () => {
  const repository = fakeRepository({
    findById: async () => ({ _id: 'l1', vocabularies: [], grammars: [], kanjis: [] }),
    findVocabulariesByLesson: async () => [{ _id: 'v1' }],
    findActiveGrammarsByLesson: async () => [{ _id: 'g1' }],
    findKanjisByLesson: async () => [{ _id: 'k1' }],
  });
  const service = createLessonService({ lessonRepository: repository });

  const detail = await service.getDetail('l1');

  assert.deepEqual(detail.vocabularies, [{ _id: 'v1' }]);
  assert.deepEqual(detail.tuvungs, [{ _id: 'v1' }]);
  assert.deepEqual(detail.grammars, [{ _id: 'g1' }]);
  assert.deepEqual(detail.nguphaps, [{ _id: 'g1' }]);
  assert.deepEqual(detail.kanjis, [{ _id: 'k1' }]);
});

test('getDetail giữ mảng đã populate khi không rỗng, không gọi fallback', async () => {
  let fallbackCalled = false;
  const repository = fakeRepository({
    findById: async () => ({
      _id: 'l1',
      vocabularies: [{ _id: 'v1' }],
      grammars: [{ _id: 'g1' }],
      kanjis: [{ _id: 'k1' }],
    }),
    findVocabulariesByLesson: async () => { fallbackCalled = true; return []; },
  });
  const service = createLessonService({ lessonRepository: repository });

  const detail = await service.getDetail('l1');

  assert.equal(fallbackCalled, false);
  assert.deepEqual(detail.vocabularies, [{ _id: 'v1' }]);
});

test('remove chặn 409 kèm details khi còn tham chiếu', async () => {
  const repository = fakeRepository({
    countRelated: async () => ({ vocabulary: 2, kanji: 0, grammar: 0 }),
  });
  const service = createLessonService({ lessonRepository: repository });

  await assert.rejects(service.remove('l1'), (error) => {
    assert.equal(error.status, 409);
    assert.deepEqual(error.details, { vocabulary: 2, kanji: 0, grammar: 0 });
    return true;
  });
});

test('remove xóa được khi không còn tham chiếu, báo 404 khi bài học không tồn tại', async () => {
  const repository = fakeRepository({ deleteById: async () => null });
  const service = createLessonService({ lessonRepository: repository });

  await assert.rejects(service.remove('missing'), (error) => error.status === 404);
});

test('removeMany chặn 409 kèm details, xóa được khi không còn tham chiếu', async () => {
  const blocked = createLessonService({
    lessonRepository: fakeRepository({
      countRelated: async () => ({ vocabulary: 0, kanji: 1, grammar: 0 }),
    }),
  });
  await assert.rejects(blocked.removeMany(['l1']), (error) => error.status === 409);

  const allowed = createLessonService({
    lessonRepository: fakeRepository({ deleteManyByIds: async () => 3 }),
  });
  const deletedCount = await allowed.removeMany(['l1', 'l2', 'l3']);
  assert.equal(deletedCount, 3);
});

test('update báo 404 khi bài học không tồn tại', async () => {
  const service = createLessonService({ lessonRepository: fakeRepository() });

  await assert.rejects(service.update('missing', { title: 'x' }), (error) => error.status === 404);
});

test('duplicate xóa _id/createdAt/updatedAt và thêm hậu tố Bản sao vào title', async () => {
  const repository = fakeRepository({
    findByIdLean: async () => ({
      _id: 'l1',
      title: 'Bài 1',
      createdAt: new Date(),
      updatedAt: new Date(),
      level: 'N5',
    }),
    create: async (input) => ({ _id: 'l2', ...input }),
  });
  const service = createLessonService({ lessonRepository: repository });

  const copy = await service.duplicate('l1');

  assert.ok(copy.title.startsWith('Bài 1 (Bản sao '));
  assert.equal(copy._id, 'l2');
  assert.equal(copy.level, 'N5');
});

test('duplicate báo 404 khi bài học gốc không tồn tại', async () => {
  const service = createLessonService({ lessonRepository: fakeRepository() });

  await assert.rejects(service.duplicate('missing'), (error) => error.status === 404);
});
