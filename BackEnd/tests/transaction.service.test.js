import assert from 'node:assert/strict';
import test from 'node:test';

import { ApiError } from '../src/shared/http/api-error.js';
import { createTransactionService } from '../src/modules/transactions/transaction.service.js';

const ID = '507f1f77bcf86cd799439011';

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

const service = (results) => {
  const fake = fakeRepository(results);
  return { ...fake, service: createTransactionService({ repository: fake.repository }) };
};

const input = { type: 'SUBSCRIPTION', amount: 79000, currency: 'VND', payment_method: 'NONE', package_id: 'pro' };

test('yêu cầu giao dịch gắn với người đang đăng nhập và luôn chờ quản trị duyệt', async () => {
  const { calls, service: transactions } = service({ create: (doc) => ({ _id: ID, ...doc }) });

  const transaction = await transactions.create({ userId: 'u1', input });

  assert.equal(transaction._id, ID);
  assert.deepEqual(calls, [['create', { ...input, user: 'u1', status: 'pending' }]]);
});

test('mã thanh toán đã dùng là 409, không phải lỗi máy chủ', async () => {
  const duplicate = Object.assign(new Error('E11000 duplicate key'), { code: 11000 });
  const { service: transactions } = service({ create: duplicate });

  await assert.rejects(
    transactions.create({ userId: 'u1', input: { ...input, payment_ref_id: 'MOMO-1' } }),
    (error) => error instanceof ApiError && error.status === 409 && error.code === 'DUPLICATE_PAYMENT_REF',
  );
});

test('danh sách quản trị không truyền bộ lọc nào thì không tự thêm điều kiện', async () => {
  const { calls, service: transactions } = service({ findPage: [{ _id: ID }], count: 41 });

  const page = await transactions.listAll({ page: 3, limit: 20 });

  assert.deepEqual(page, { items: [{ _id: ID }], total: 41, page: 3, limit: 20 });
  assert.deepEqual(calls, [
    ['findPage', { filter: {}, skip: 40, limit: 20 }],
    ['count', {}],
  ]);
});

test('danh sách quản trị lọc theo trạng thái, loại, người dùng và khoảng ngày', async () => {
  const { calls, service: transactions } = service({ findPage: [], count: 0 });
  const startDate = new Date('2026-11-01T00:00:00.000Z');
  const endDate = new Date('2026-11-14T00:00:00.000Z');

  await transactions.listAll({ page: 1, limit: 20, status: 'pending', type: 'DEPOSIT', userId: 'u2', startDate });
  await transactions.listAll({ page: 1, limit: 20, startDate, endDate });

  assert.deepEqual(calls[0][1].filter, { status: 'pending', type: 'DEPOSIT', user: 'u2', createdAt: { $gte: startDate } });
  assert.deepEqual(calls[2][1].filter, { createdAt: { $gte: startDate, $lte: endDate } });
});

test('đổi trạng thái kèm ghi chú; ghi chú bỏ trống thì giữ ghi chú cũ', async () => {
  const { calls, service: transactions } = service({ updateStatus: ({ set }) => ({ _id: ID, ...set }) });

  assert.equal((await transactions.updateStatus({ id: ID, status: 'completed', notes: 'Đã nhận tiền' })).status, 'completed');
  await transactions.updateStatus({ id: ID, status: 'cancelled' });

  assert.deepEqual(calls, [
    ['updateStatus', { id: ID, set: { status: 'completed', notes: 'Đã nhận tiền' } }],
    ['updateStatus', { id: ID, set: { status: 'cancelled' } }],
  ]);
});

test('đổi trạng thái giao dịch không tồn tại là 404', async () => {
  const { service: transactions } = service({ updateStatus: null });

  await assert.rejects(
    transactions.updateStatus({ id: ID, status: 'completed' }),
    (error) => error instanceof ApiError && error.status === 404,
  );
});
