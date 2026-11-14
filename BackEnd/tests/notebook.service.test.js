import assert from 'node:assert/strict';
import test from 'node:test';

import { ApiError } from '../src/shared/http/api-error.js';
import { createNotebookService } from '../src/modules/notebook/notebook.service.js';

const ID = '507f1f77bcf86cd799439011';

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

const service = (results) => {
  const fake = fakeRepository(results);
  return { ...fake, service: createNotebookService({ repository: fake.repository }) };
};

const isNotFound = (error) => error instanceof ApiError && error.status === 404;

test('danh sách chỉ lấy ghi chú của chính người dùng, phân trang', async () => {
  const { calls, service: notebook } = service({ findPage: [{ _id: ID }], count: 21 });

  const page = await notebook.list({ userId: 'u1', page: 2, limit: 20 });

  assert.deepEqual(page, { items: [{ _id: ID }], total: 21, page: 2, limit: 20 });
  assert.deepEqual(calls, [
    ['findPage', { filter: { user_id: 'u1' }, skip: 20, limit: 20 }],
    ['count', { user_id: 'u1' }],
  ]);
});

test('lọc theo loại và tìm nguyên văn trong tiêu đề hoặc nội dung', async () => {
  const { calls, service: notebook } = service({ findPage: [], count: 0 });

  await notebook.list({ userId: 'u1', page: 1, limit: 20, type: 'kanji', search: 'C++ (N5)' });

  const pattern = { $regex: 'C\\+\\+ \\(N5\\)', $options: 'i' };
  assert.deepEqual(calls[0][1].filter, {
    user_id: 'u1',
    type: 'kanji',
    $or: [{ title: pattern }, { content: pattern }],
  });
});

test('ghi chú mới gắn với người đang đăng nhập', async () => {
  const { calls, service: notebook } = service({ create: (doc) => ({ _id: ID, ...doc }) });
  const input = { title: 'Trợ từ は', content: 'Đánh dấu chủ đề', type: 'grammar', tags: ['N5'] };

  const note = await notebook.create({ userId: 'u1', input });

  assert.equal(note._id, ID);
  assert.deepEqual(calls, [['create', { ...input, user_id: 'u1' }]]);
});

test('xem, sửa, xoá chỉ chạm ghi chú của chính mình; không có là 404', async () => {
  const note = { _id: ID, title: 'Cũ' };
  const { calls, service: notebook } = service({
    findOwned: note,
    updateOwned: ({ set }) => ({ ...note, ...set }),
    deleteOwned: note,
  });

  assert.equal(await notebook.detail({ userId: 'u1', id: ID }), note);
  assert.equal((await notebook.update({ userId: 'u1', id: ID, changes: { title: 'Mới' } })).title, 'Mới');
  await notebook.remove({ userId: 'u1', id: ID });

  assert.deepEqual(calls, [
    ['findOwned', { id: ID, userId: 'u1' }],
    ['updateOwned', { id: ID, userId: 'u1', set: { title: 'Mới' } }],
    ['deleteOwned', { id: ID, userId: 'u1' }],
  ]);

  const { service: missing } = service({ findOwned: null, updateOwned: null, deleteOwned: null });
  await assert.rejects(missing.detail({ userId: 'u2', id: ID }), isNotFound);
  await assert.rejects(missing.update({ userId: 'u2', id: ID, changes: { title: 'x' } }), isNotFound);
  await assert.rejects(missing.remove({ userId: 'u2', id: ID }), isNotFound);
});
