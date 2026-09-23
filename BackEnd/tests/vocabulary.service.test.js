import assert from 'node:assert/strict';
import test from 'node:test';

import { createVocabularyService } from '../src/modules/vocabulary/vocabulary.service.js';

const VOCABULARY = { _id: 'v1', word: '学生', level: 'N5' };

/** Repository giả: chỉ trả về dữ liệu đã dựng sẵn và ghi lại lời gọi. */
const fakeVocabularyRepository = (overrides = {}) => {
  const calls = [];
  const base = {
    calls,
    findPage: async (args) => {
      calls.push(['findPage', args]);
      return [VOCABULARY];
    },
    count: async (filter) => {
      calls.push(['count', filter]);
      return 1;
    },
    findAll: async (args) => {
      calls.push(['findAll', args]);
      return [];
    },
    findDetailById: async (id) => {
      calls.push(['findDetailById', id]);
      return VOCABULARY;
    },
    findById: async (id) => {
      calls.push(['findById', id]);
      return VOCABULARY;
    },
    findPopulatedById: async (id) => ({ ...VOCABULARY, _id: id }),
    distinctUsageContexts: async () => ['Nhà hàng', 'Bưu điện'],
    sample: async (args) => {
      calls.push(['sample', args]);
      return [];
    },
    create: async (payload) => ({ _id: 'new-id', ...payload }),
    updateById: async (id, data) => ({ _id: id, ...data }),
    deleteById: async () => VOCABULARY,
    deleteManyByIds: async (ids) => ids.length,
    insertMany: async (rows) => rows,
    lessonExists: async () => true,
    stats: async () => ({ totalVocabularies: 1 }),
    findForExport: async () => [VOCABULARY],
    findKanjiByCharacters: async () => [],
    findRelated: async () => [],
  };

  return { ...base, ...overrides, calls };
};

const fakeSrsRepository = (overrides = {}) => ({
  findLearnedItemIds: async () => [],
  findProgress: async () => null,
  ensureProgress: async ({ initial, ...payload }) => ({
    progress: { _id: 'p1', ...payload, ...initial },
    created: true,
  }),
  deleteProgress: async () => 1,
  ...overrides,
});

const buildService = ({ repository, srs, importer } = {}) =>
  createVocabularyService({
    vocabularyRepository: repository ?? fakeVocabularyRepository(),
    srsRepository: srs ?? fakeSrsRepository(),
    ...(importer ? { importer } : {}),
  });

test('danh sách tính skip/limit từ page và limit', async () => {
  const repository = fakeVocabularyRepository();
  const service = buildService({ repository });

  const result = await service.list({
    userId: 'u1',
    page: 3,
    limit: 20,
    sortBy: 'alphabet',
  });

  const [, findPageArgs] = repository.calls.find(([name]) => name === 'findPage');
  assert.equal(findPageArgs.skip, 40);
  assert.equal(findPageArgs.limit, 20);
  assert.deepEqual(findPageArgs.sort, { word: 1 });
  assert.deepEqual(result, { items: [VOCABULARY], page: 3, limit: 20, total: 1 });
});

test('sort mặc định là mới nhất theo _id vì model không có createdAt', async () => {
  const repository = fakeVocabularyRepository();
  const service = buildService({ repository });

  await service.list({ userId: 'u1', page: 1, limit: 20 });

  const [, findPageArgs] = repository.calls.find(([name]) => name === 'findPage');
  assert.deepEqual(findPageArgs.sort, { _id: -1 });
});

test('lọc "đã học" được đẩy vào filter, và count dùng đúng filter đó', async () => {
  const repository = fakeVocabularyRepository();
  const srs = fakeSrsRepository({
    findLearnedItemIds: async () => ['v1', 'v2'],
  });
  const service = buildService({ repository, srs });

  await service.list({
    userId: 'u1',
    page: 1,
    limit: 20,
    level: 'N5',
    studyStatus: 'learned',
  });

  const expectedFilter = { level: 'N5', _id: { $in: ['v1', 'v2'] } };
  const [, findPageArgs] = repository.calls.find(([name]) => name === 'findPage');
  const [, countFilter] = repository.calls.find(([name]) => name === 'count');

  assert.deepEqual(findPageArgs.filter, expectedFilter);
  assert.deepEqual(
    countFilter,
    expectedFilter,
    'total phải đếm trên tập đã lọc, nếu không phân trang sẽ sai',
  );
});

test('lọc "chưa học" loại bỏ các item đã học', async () => {
  const repository = fakeVocabularyRepository();
  const srs = fakeSrsRepository({ findLearnedItemIds: async () => ['v1'] });
  const service = buildService({ repository, srs });

  await service.list({
    userId: 'u1',
    page: 1,
    limit: 20,
    studyStatus: 'unlearned',
  });

  const [, findPageArgs] = repository.calls.find(([name]) => name === 'findPage');
  assert.deepEqual(findPageArgs.filter, { _id: { $nin: ['v1'] } });
});

test('không lọc trạng thái học thì không hỏi SRS', async () => {
  let asked = false;
  const srs = fakeSrsRepository({
    findLearnedItemIds: async () => {
      asked = true;
      return [];
    },
  });

  await buildService({ srs }).list({ userId: 'u1', page: 1, limit: 20 });

  assert.equal(asked, false);
});

test('tìm kiếm khớp word/hiragana/meaning và escape ký tự regex', async () => {
  const repository = fakeVocabularyRepository();
  const service = buildService({ repository });

  await service.search({ keyword: 'a.b', level: 'N5' });

  const [, args] = repository.calls.find(([name]) => name === 'findAll');
  assert.equal(args.filter.level, 'N5');
  assert.equal(args.filter.$or.length, 3);
  assert.equal(args.filter.$or[0].word.source, 'a\\.b');
  assert.equal(args.filter.$or[0].word.test('xAxbx'), false);
});

test('danh sách rỗng vẫn là danh sách, không phải lỗi', async () => {
  const repository = fakeVocabularyRepository({ findAll: async () => [] });
  const service = buildService({ repository });

  assert.deepEqual(await service.search({ keyword: 'không có' }), []);
  assert.deepEqual(await service.listByLevel('N1'), []);
  assert.deepEqual(await service.searchBySituation('không có'), []);
});

test('chi tiết từ vựng gắn trạng thái đã học', async () => {
  const learnedAt = new Date('2026-02-01T00:00:00.000Z');
  const srs = fakeSrsRepository({
    findProgress: async () => ({
      _id: 'p1',
      item_id: 'v1',
      item_type: 'Vocabulary',
      box: 3,
      streak: 2,
      next_review: new Date('2026-02-08T00:00:00.000Z'),
      createdAt: learnedAt,
    }),
  });

  const detail = await buildService({ srs }).getById({ id: 'v1', userId: 'u1' });

  assert.equal(detail.isLearned, true);
  assert.equal(detail.reviewBox, 3);
  assert.equal(detail.learnedAt, learnedAt);
  assert.deepEqual(detail.srs_progress, {
    _id: 'p1',
    item_id: 'v1',
    item_type: 'Vocabulary',
    box: 3,
    next_review: '2026-02-08T00:00:00.000Z',
    streak: 2,
  });
});

test('chi tiết từ vựng chưa học có srs_progress null', async () => {
  const detail = await buildService().getById({ id: 'v1', userId: 'u1' });
  assert.equal(detail.srs_progress, null);
});

test('chi tiết từ vựng không tồn tại trả về lỗi 404', async () => {
  const repository = fakeVocabularyRepository({ findDetailById: async () => null });

  await assert.rejects(
    () => buildService({ repository }).getById({ id: 'v404', userId: 'u1' }),
    (error) => error.status === 404,
  );
});

test('tạo từ vựng kiểm tra bài học tồn tại', async () => {
  const repository = fakeVocabularyRepository({ lessonExists: async () => false });

  await assert.rejects(
    () => buildService({ repository }).create({ lesson: 'l404', word: 'a' }),
    (error) => error.status === 404,
  );
});

test('cập nhật từ vựng không tồn tại trả về lỗi 404', async () => {
  const repository = fakeVocabularyRepository({ updateById: async () => null });

  await assert.rejects(
    () => buildService({ repository }).update('v404', { word: 'a' }),
    (error) => error.status === 404,
  );
});

test('đánh dấu đã học tạo tiến độ box 1 khi chưa có', async () => {
  let ensured = null;
  const srs = fakeSrsRepository({
    ensureProgress: async (args) => {
      ensured = args;
      return { progress: { _id: 'p1', ...args.initial }, created: true };
    },
  });

  const result = await buildService({ srs }).markLearned({
    id: 'v1',
    userId: 'u1',
  });

  assert.equal(result.created, true);
  assert.equal(ensured.itemType, 'Vocabulary');
  assert.equal(ensured.initial.box, 1);
  assert.equal(ensured.initial.streak, 0);
  assert.ok(ensured.initial.next_review instanceof Date);
});

test('đánh dấu đã học lần nữa giữ nguyên lịch đã có', async () => {
  const srs = fakeSrsRepository({
    ensureProgress: async () => ({ progress: { _id: 'p1', box: 2 }, created: false }),
  });

  const result = await buildService({ srs }).markLearned({
    id: 'v1',
    userId: 'u1',
  });

  assert.equal(result.created, false);
  assert.equal(result.progress.box, 2);
  assert.equal(result.message, 'Từ vựng đã được đánh dấu là đã học.');
});

test('bỏ đánh dấu khi chưa có tiến độ trả về lỗi 404', async () => {
  const srs = fakeSrsRepository({ deleteProgress: async () => 0 });

  await assert.rejects(
    () => buildService({ srs }).unmarkLearned({ id: 'v1', userId: 'u1' }),
    (error) => error.status === 404,
  );
});

test('import Excel rỗng trả về lỗi 400', async () => {
  const importer = {
    readWorkbookRows: async () => [],
    toVocabularyRows: () => [],
    buildExportWorkbook: () => ({}),
  };

  await assert.rejects(
    () =>
      buildService({ importer }).importFromExcel({
        buffer: Buffer.from(''),
        lesson: 'l1',
        level: 'N5',
      }),
    (error) => error.status === 400,
  );
});

test('import Excel gắn lesson/level cho mọi dòng hợp lệ', async () => {
  const importer = {
    readWorkbookRows: async () => [{ TuVung: '本' }],
    toVocabularyRows: (rows, context) =>
      rows.map((row) => ({ word: row.TuVung, ...context })),
    buildExportWorkbook: () => ({}),
  };

  const inserted = await buildService({ importer }).importFromExcel({
    buffer: Buffer.from(''),
    lesson: 'l1',
    level: 'N5',
  });

  assert.deepEqual(inserted, [{ word: '本', lesson: 'l1', level: 'N5' }]);
});

test('chi tiết từ vựng kèm phân tích chữ Hán và từ liên quan', async () => {
  const repository = fakeVocabularyRepository({
    findDetailById: async () => ({ _id: 'v1', word: '名前', hanviet: 'DANH TIỀN', level: 'N5' }),
    findRelated: async ({ characters }) => {
      assert.deepEqual(characters, ['名', '前']);
      return [{ _id: 'v2', word: '名刺' }];
    },
  });

  const detail = await buildService({ repository }).getById({ id: 'v1', userId: 'u1' });

  assert.deepEqual(detail.kanjiBreakdown.map((item) => item.hanviet), ['DANH', 'TIỀN']);
  assert.deepEqual(detail.relatedWords, [{ _id: 'v2', word: '名刺' }]);
});
