import assert from 'node:assert/strict';
import test from 'node:test';

import { createGrammarService } from '../src/modules/grammar/grammar.service.js';

const ID = '507f1f77bcf86cd799439011';
const LESSON = '507f1f77bcf86cd799439022';

const duplicateKey = () => Object.assign(new Error('E11000 duplicate key error'), { code: 11000 });

/** Repository giả ghi lại mọi lời gọi; mỗi phương thức trả kết quả cho trước. */
const fakeRepository = (results = {}) => {
  const calls = [];
  const repository = new Proxy({}, {
    get: (_target, name) => async (args) => {
      calls.push([name, args]);
      const result = results[name];
      if (result instanceof Error) throw result;
      return typeof result === 'function' ? result(args) : result;
    },
  });
  return { calls, repository };
};

test('danh sách chỉ lấy ngữ pháp đang hoạt động, lọc cấp độ và từ khoá, phân trang', async () => {
  const { calls, repository } = fakeRepository({ findPage: [{ title: 'が' }], count: 31 });
  const service = createGrammarService({ repository });

  const result = await service.list({ page: 2, limit: 10, level: 'N5', search: 'が', sortBy: 'popular' });

  assert.deepEqual(result, { items: [{ title: 'が' }], total: 31, page: 2, limit: 10 });
  const filter = { is_active: true, level: 'N5', $text: { $search: 'が' } };
  assert.deepEqual(calls, [
    ['findPage', { filter, sort: { view_count: -1, _id: 1 }, skip: 10, limit: 10 }],
    ['count', filter],
  ]);
});

test('không chọn cách sắp xếp thì theo tiêu đề; không lọc gì thì chỉ còn điều kiện đang hoạt động', async () => {
  const { calls, repository } = fakeRepository({ findPage: [], count: 0 });

  await createGrammarService({ repository }).list({ page: 1, limit: 20 });

  assert.deepEqual(calls[0][1], { filter: { is_active: true }, sort: { title: 1, _id: 1 }, skip: 0, limit: 20 });
});

test('chi tiết cộng một lượt xem; ngữ pháp đã xoá hoặc không có là 404', async () => {
  const found = fakeRepository({ findActiveAndCountView: { _id: ID, view_count: 7 } });
  assert.deepEqual(await createGrammarService(found).getDetail(ID), { _id: ID, view_count: 7 });
  assert.deepEqual(found.calls, [['findActiveAndCountView', ID]]);

  const missing = fakeRepository({ findActiveAndCountView: null });
  await assert.rejects(createGrammarService(missing).getDetail(ID), { status: 404 });
});

const input = {
  title: 'です / だ',
  structure: 'N + です',
  meaning: 'là',
  level: 'N5',
  examples: [],
  difficulty: 3,
  lessonID: LESSON,
  relatedGrammar: [ID],
};

test('thêm mới đổi tên trường của form sang tên trường của model', async () => {
  const { calls, repository } = fakeRepository({ reviveInactive: null, create: (doc) => ({ _id: 'g1', ...doc }) });

  const result = await createGrammarService({ repository }).create(input);

  const document = {
    title: 'です / だ', structure: 'N + です', meaning: 'là', level: 'N5', examples: [], difficulty: 3,
    lesson_id: LESSON, related_grammar: [ID],
  };
  assert.deepEqual(calls, [
    ['reviveInactive', { level: 'N5', title: 'です / だ', set: document }],
    ['create', document],
  ]);
  assert.deepEqual(result, { grammar: { _id: 'g1', ...document }, revived: false });
});

test('thêm lại đúng ngữ pháp đã xoá mềm thì khôi phục bản đó, giữ `_id` để tiến độ học nối lại', async () => {
  const { calls, repository } = fakeRepository({ reviveInactive: { _id: ID, title: 'です / だ' } });

  const result = await createGrammarService({ repository }).create({ title: 'です / だ', level: 'N5' });

  assert.deepEqual(result, { grammar: { _id: ID, title: 'です / だ' }, revived: true });
  assert.equal(calls.some(([name]) => name === 'create'), false);
});

test('trường không gửi không được ghi thành undefined đè lên nội dung cũ', async () => {
  const { calls, repository } = fakeRepository({ reviveInactive: { _id: ID } });

  await createGrammarService({ repository }).create({ title: 'は', level: 'N5', notes: undefined, lessonID: undefined });

  assert.deepEqual(calls[0][1].set, { title: 'は', level: 'N5' });
});

test('trùng ngữ pháp đang hoạt động là 409 có tên và cấp độ, không phải 500', async () => {
  const { repository } = fakeRepository({ reviveInactive: null, create: duplicateKey() });

  await assert.rejects(createGrammarService({ repository }).create(input), (error) => {
    assert.equal(error.status, 409);
    assert.equal(error.code, 'DUPLICATE_GRAMMAR');
    assert.match(error.message, /です \/ だ/);
    assert.match(error.message, /N5/);
    return true;
  });
});

test('lỗi khác của DB đi ra nguyên vẹn để thành 500', async () => {
  const { repository } = fakeRepository({ reviveInactive: null, create: new Error('mất kết nối') });

  await assert.rejects(createGrammarService({ repository }).create(input), /mất kết nối/);
});

test('sửa chỉ ghi trường được gửi; bỏ trống bài học là gỡ bài', async () => {
  const { calls, repository } = fakeRepository({ updateById: { _id: ID } });

  await createGrammarService({ repository }).update(ID, { meaning: 'là (lịch sự)', lessonID: null });

  assert.deepEqual(calls, [['updateById', { id: ID, set: { meaning: 'là (lịch sự)', lesson_id: null } }]]);
});

test('sửa ngữ pháp không có là 404; đổi tên trùng ngữ pháp khác là 409', async () => {
  const missing = fakeRepository({ updateById: null });
  await assert.rejects(createGrammarService(missing).update(ID, { title: 'は' }), { status: 404 });

  const duplicate = fakeRepository({ updateById: duplicateKey() });
  await assert.rejects(createGrammarService(duplicate).update(ID, { title: 'は' }), { status: 409, code: 'DUPLICATE_GRAMMAR' });
});

test('xoá là xoá mềm; ngữ pháp không có là 404', async () => {
  const { calls, repository } = fakeRepository({ deactivate: { _id: ID } });
  await createGrammarService({ repository }).remove(ID);
  assert.deepEqual(calls, [['deactivate', ID]]);

  const missing = fakeRepository({ deactivate: null });
  await assert.rejects(createGrammarService(missing).remove(ID), { status: 404 });
});
