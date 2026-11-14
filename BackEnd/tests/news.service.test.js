import assert from 'node:assert/strict';
import test from 'node:test';

import { createNewsService } from '../src/modules/news/news.service.js';

const ID = '507f1f77bcf86cd799439011';

const fakeRepository = (results = {}) => {
  const calls = [];
  const repository = new Proxy({}, {
    get: (_target, name) => async (args) => {
      calls.push([name, args]);
      return results[name];
    },
  });
  return { calls, repository };
};

test('danh sách mới nhất trước, lọc cấp độ, phân trang', async () => {
  const { calls, repository } = fakeRepository({ findPage: [{ title: 'Tin' }], count: 12 });

  const result = await createNewsService({ repository }).list({ page: 2, limit: 5, level: 'N4' });

  assert.deepEqual(result, { items: [{ title: 'Tin' }], total: 12, page: 2, limit: 5 });
  assert.deepEqual(calls, [
    ['findPage', { filter: { level: 'N4' }, skip: 5, limit: 5 }],
    ['count', { level: 'N4' }],
  ]);
});

test('từ khoá được khớp nguyên văn ở tiêu đề, mô tả và nội dung — ký tự đặc biệt không thành biểu thức', async () => {
  const { calls, repository } = fakeRepository({ findPage: [], count: 0 });

  await createNewsService({ repository }).list({ page: 1, limit: 10, search: 'C++ (N5)' });

  const pattern = { $regex: 'C\\+\\+ \\(N5\\)', $options: 'i' };
  assert.deepEqual(calls[1][1], {
    $or: [{ title: pattern }, { description: pattern }, { content_html: pattern }],
  });
});

test('chi tiết cộng một lượt xem; không có là 404', async () => {
  const found = fakeRepository({ findAndCountView: { _id: ID, views: 3 } });
  assert.deepEqual(await createNewsService(found).getDetail(ID), { _id: ID, views: 3 });
  assert.deepEqual(found.calls, [['findAndCountView', ID]]);

  await assert.rejects(createNewsService(fakeRepository({ findAndCountView: null })).getDetail(ID), { status: 404 });
});

test('tin liên quan cùng cấp độ, không gồm chính bài đang đọc; bài không cấp độ đi với bài không cấp độ', async () => {
  const { calls, repository } = fakeRepository({ findLevel: { level: 'N3' }, findRelated: [{ title: 'Khác' }] });

  assert.deepEqual(await createNewsService({ repository }).related({ id: ID, limit: 3 }), [{ title: 'Khác' }]);
  assert.deepEqual(calls[1], ['findRelated', { excludeId: ID, level: 'N3', limit: 3 }]);

  const noLevel = fakeRepository({ findLevel: {}, findRelated: [] });
  await createNewsService(noLevel).related({ id: ID, limit: 3 });
  assert.equal(noLevel.calls[1][1].level, null);

  await assert.rejects(createNewsService(fakeRepository({ findLevel: null })).related({ id: ID, limit: 3 }), { status: 404 });
});
