import assert from 'node:assert/strict';
import test from 'node:test';

import { createKanjiService } from '../src/modules/kanji/kanji.service.js';
import { ApiError } from '../src/shared/http/api-error.js';

const LESSON = '64b7f0c2a1b2c3d4e5f60718';
const OTHER_LESSON = '64b7f0c2a1b2c3d4e5f60719';
const KANJI = { _id: 'k1', character: '学', meaning: 'học', level: 'N5', lessonId: LESSON };

/** Repository ghi lại mọi lời gọi; kết quả lấy theo tên method. */
const recordingRepository = (results = {}) => {
  const calls = [];
  const repository = new Proxy({}, {
    get: (_target, name) => async (args, options) => {
      calls.push(options === undefined ? [name, args] : [name, args, options]);
      const result = results[name];
      if (result instanceof Error) throw result;
      return typeof result === 'function' ? result(args) : result;
    },
  });
  return { calls, repository };
};

/** Unit of work giả: chạy ngay với một session đánh dấu được. */
const unitOfWork = { run: (fn) => fn({ session: 'tx' }) };

const build = ({ results, sheetRows = [] } = {}) => {
  const { calls, repository } = recordingRepository(results);
  const service = createKanjiService({
    repository,
    srs: {},
    unitOfWork,
    readSheet: async () => sheetRows,
  });
  return { calls, service };
};

const rejectsWith = (status, code) => (error) => {
  assert.ok(error instanceof ApiError, error);
  assert.equal(error.status, status);
  if (code) assert.equal(error.code, code);
  return true;
};

test('danh sách theo cấp độ, phân trang; không chọn cấp thì lấy mọi cấp', async () => {
  const { calls, service } = build({ results: { findPage: [KANJI], count: 41 } });

  assert.deepEqual(await service.list({ page: 3, limit: 20, level: 'N5' }), { items: [KANJI], total: 41, page: 3, limit: 20 });
  await service.list({ page: 1, limit: 20 });

  assert.deepEqual(calls, [
    ['findPage', { filter: { level: 'N5' }, skip: 40, limit: 20 }],
    ['count', { level: 'N5' }],
    ['findPage', { filter: {}, skip: 0, limit: 20 }],
    ['count', {}],
  ]);
});

test('tìm nguyên văn trên chữ, Hán Việt, âm On/Kun và nghĩa; không thấy là danh sách rỗng', async () => {
  const { calls, service } = build({ results: { search: [] } });

  assert.deepEqual(await service.search({ keyword: 'HỌC (N5)', level: 'N5' }), []);

  const pattern = { $regex: 'HỌC \\(N5\\)', $options: 'i' };
  assert.deepEqual(calls, [['search', {
    filter: {
      level: 'N5',
      $or: ['character', 'hanviet', 'onyomi', 'kunyomi', 'meaning'].map((field) => ({ [field]: pattern })),
    },
    limit: 50,
  }]]);
});

test('thêm chữ: bài học phải tồn tại; chữ đã có là 409', async () => {
  const input = { character: '学', meaning: 'học', level: 'N5', lessonId: LESSON, onyomi: ['ガク'], kunyomi: [], examples: [] };

  const { calls, service } = build({ results: { existingLessonIds: [LESSON], create: (doc) => ({ _id: 'k1', ...doc }) } });
  assert.equal((await service.create(input))._id, 'k1');
  assert.deepEqual(calls, [['existingLessonIds', [LESSON]], ['create', input]]);

  const missing = build({ results: { existingLessonIds: [] } });
  await assert.rejects(missing.service.create(input), rejectsWith(404));

  const duplicate = Object.assign(new Error('E11000'), { code: 11000 });
  const taken = build({ results: { existingLessonIds: [LESSON], create: duplicate } });
  await assert.rejects(taken.service.create(input), rejectsWith(409, 'DUPLICATE_KANJI'));
});

test('sửa chữ: chỉ kiểm bài học khi đổi bài; gỡ bài (null) không cần kiểm; không có chữ là 404', async () => {
  const { calls, service } = build({ results: { existingLessonIds: [OTHER_LESSON], updateById: ({ set }) => ({ ...KANJI, ...set }) } });

  assert.equal((await service.update('k1', { meaning: 'học tập' })).meaning, 'học tập');
  await service.update('k1', { lessonId: OTHER_LESSON });
  await service.update('k1', { lessonId: null });

  assert.deepEqual(calls, [
    ['updateById', { id: 'k1', set: { meaning: 'học tập' } }],
    ['existingLessonIds', [OTHER_LESSON]],
    ['updateById', { id: 'k1', set: { lessonId: OTHER_LESSON } }],
    ['updateById', { id: 'k1', set: { lessonId: null } }],
  ]);

  const gone = build({ results: { updateById: null } });
  await assert.rejects(gone.service.update('k1', { meaning: 'x' }), rejectsWith(404));
});

const row = (overrides = {}) => ({ BaiHocID: LESSON, KyTuKanji: '学', AmOn: 'ガク', AmKun: 'まな.ぶ', Nghia: 'học', CapDo: 'N5', ...overrides });

test('nhập Excel: cả file vào một transaction, trả số chữ đã thêm', async () => {
  const { calls, service } = build({
    sheetRows: [row(), row({ KyTuKanji: '日', AmOn: 'ニチ; ジツ', AmKun: '' })],
    results: { existingLessonIds: [LESSON], findCharacters: [], insertMany: (docs) => docs },
  });

  assert.deepEqual(await service.importSheet(Buffer.from('xlsx')), { insertedCount: 2 });

  const [, documents, options] = calls.at(-1);
  assert.equal(calls.at(-1)[0], 'insertMany');
  assert.deepEqual(options, { session: 'tx' });
  assert.deepEqual(documents[1], { lessonId: LESSON, character: '日', meaning: 'học', level: 'N5', onyomi: ['ニチ', 'ジツ'], kunyomi: [] });
});

test('nhập Excel: một dòng sai là bỏ cả file, nêu từng dòng lỗi; không ghi gì', async () => {
  const { calls, service } = build({
    sheetRows: [row(), row({ Nghia: '' }), row({ CapDo: 'N6', KyTuKanji: '日' }), row({ AmOn: 'セイ' })],
  });

  await assert.rejects(service.importSheet(Buffer.from('xlsx')), (error) => {
    rejectsWith(400, 'INVALID_SHEET')(error);
    assert.deepEqual(error.details.map(({ path }) => path), ['dòng 3', 'dòng 4', 'dòng 5']);
    assert.match(error.details[2].message, /trùng với dòng 2/);
    return true;
  });
  assert.deepEqual(calls, []);
});

test('nhập Excel: file rỗng 400; bài học không có 404; chữ đã có trong kho 409 kèm tên chữ', async () => {
  await assert.rejects(build({ sheetRows: [] }).service.importSheet(Buffer.from('')), rejectsWith(400));

  const noLesson = build({ sheetRows: [row()], results: { existingLessonIds: [] } });
  await assert.rejects(noLesson.service.importSheet(Buffer.from('x')), rejectsWith(404));

  const taken = build({ sheetRows: [row(), row({ KyTuKanji: '日' })], results: { existingLessonIds: [LESSON], findCharacters: ['日'] } });
  await assert.rejects(taken.service.importSheet(Buffer.from('x')), (error) => {
    rejectsWith(409, 'DUPLICATE_KANJI')(error);
    assert.match(error.message, /日/);
    return true;
  });
  assert.equal(taken.calls.some(([name]) => name === 'insertMany'), false);
});
