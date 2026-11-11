import assert from 'node:assert/strict';
import test from 'node:test';

import { createNotificationRepository } from '../src/modules/notifications/notification.repository.js';

/** Model giả: ghi lại lời gọi, mọi chuỗi truy vấn kết thúc bằng `lean()`. */
const fakeModel = (calls, results = {}) => {
  const chain = (name, args) => {
    calls.push([name, ...args]);
    const query = {
      sort: (order) => { calls.push(['sort', order]); return query; },
      skip: (count) => { calls.push(['skip', count]); return query; },
      limit: (count) => { calls.push(['limit', count]); return query; },
      select: (fields) => { calls.push(['select', fields]); return query; },
      lean: async () => results[name],
    };
    return query;
  };
  return {
    find: (...args) => chain('find', args),
    findOne: (...args) => chain('findOne', args),
    findOneAndUpdate: (...args) => chain('findOneAndUpdate', args),
    countDocuments: async (filter) => { calls.push(['countDocuments', filter]); return results.countDocuments; },
    updateMany: async (...args) => { calls.push(['updateMany', ...args]); return results.updateMany; },
    deleteOne: async (filter) => { calls.push(['deleteOne', filter]); return results.deleteOne; },
    insertMany: async (docs) => { calls.push(['insertMany', docs]); return docs; },
    create: async (docs, options) => {
      calls.push(['create', docs, options]);
      return docs.map((doc) => ({ toObject: () => ({ _id: 'n1', ...doc }) }));
    },
    exists: async (filter) => { calls.push(['exists', filter]); return results.exists; },
  };
};

const READ_AT = new Date('2026-11-04T08:00:00.000Z');

test('danh sách mới nhất trước, phân trang', async () => {
  const calls = [];
  const repository = createNotificationRepository({ Notification: fakeModel(calls, { find: [] }), User: {} });

  await repository.findPage({ filter: { recipient: 'a' }, skip: 20, limit: 10 });

  assert.deepEqual(calls, [
    ['find', { recipient: 'a' }],
    ['sort', { createdAt: -1, _id: -1 }],
    ['skip', 20],
    ['limit', 10],
  ]);
});

test('đọc một thông báo chỉ khớp bản chưa đọc của đúng người nhận', async () => {
  const calls = [];
  const repository = createNotificationRepository({ Notification: fakeModel(calls, { findOneAndUpdate: null }), User: {} });

  assert.equal(await repository.markRead({ id: 'n1', recipient: 'a', readAt: READ_AT }), null);

  assert.deepEqual(calls, [[
    'findOneAndUpdate',
    { _id: 'n1', recipient: 'a', is_read: false },
    { $set: { is_read: true, read_at: READ_AT } },
    { new: true },
  ]]);
});

test('đọc tất cả, xoá và tìm đều lọc theo người nhận', async () => {
  const calls = [];
  const Notification = fakeModel(calls, { updateMany: { modifiedCount: 3 }, deleteOne: { deletedCount: 0 }, findOne: null });
  const repository = createNotificationRepository({ Notification, User: {} });

  assert.equal(await repository.markAllRead({ recipient: 'a', readAt: READ_AT }), 3);
  assert.equal(await repository.deleteOwned({ id: 'n1', recipient: 'a' }), 0);
  assert.equal(await repository.findOwned({ id: 'n1', recipient: 'a' }), null);

  assert.deepEqual(calls, [
    ['updateMany', { recipient: 'a', is_read: false }, { $set: { is_read: true, read_at: READ_AT } }],
    ['deleteOne', { _id: 'n1', recipient: 'a' }],
    ['findOne', { _id: 'n1', recipient: 'a' }],
  ]);
});

test('tạo thông báo ghi trong session được truyền vào — cùng transaction với việc cấp huy hiệu', async () => {
  const calls = [];
  const repository = createNotificationRepository({ Notification: fakeModel(calls), User: {} });

  const created = await repository.create({ recipient: 'a', title: 'T', message: 'M' }, { session: 'sess' });
  await repository.create({ recipient: 'b', title: 'T', message: 'M' });

  assert.deepEqual(created, { _id: 'n1', recipient: 'a', title: 'T', message: 'M' });
  assert.deepEqual(calls, [
    ['create', [{ recipient: 'a', title: 'T', message: 'M' }], { session: 'sess' }],
    ['create', [{ recipient: 'b', title: 'T', message: 'M' }], { session: undefined }],
  ]);
});

test('gửi tất cả chỉ tới tài khoản người học chưa bị khoá hay cấm', async () => {
  const calls = [];
  const User = fakeModel(calls, { find: [{ _id: 'u1' }, { _id: 'u2' }], exists: { _id: 'u1' } });
  const repository = createNotificationRepository({ Notification: fakeModel(calls), User });

  assert.deepEqual(await repository.findBroadcastRecipientIds(), ['u1', 'u2']);
  assert.equal(await repository.userExists('u1'), true);
  assert.equal(await repository.insertMany([{ recipient: 'u1' }, { recipient: 'u2' }]), 2);

  assert.deepEqual(calls.slice(0, 3), [
    ['find', { VaiTro: 'user', TrangThai: { $nin: ['locked', 'banned'] } }],
    ['select', '_id'],
    ['exists', { _id: 'u1' }],
  ]);
});
