import assert from 'node:assert/strict';
import test from 'node:test';

import express from 'express';
import request from 'supertest';

import Transaction from '../model/Transaction.js';
import { getAdminAll } from '../src/modules/transactions/transaction.controller.js';

/**
 * App chạy trên Express 5 thật.
 *
 * Bắt buộc phải đi qua routing thật: bản lỗi cũ gán `req.query.userId` rồi gọi
 * lại handler khác, và chỉ getter `req.query` của Express 5 mới lộ ra rằng phép
 * gán đó bị mất. Một object `req` giả tự dựng sẽ che mất đúng lỗi cần bắt.
 */
const buildApp = () => {
  const app = express();
  const router = express.Router();

  router.get('/admin/all', getAdminAll);

  app.use('/api/transactions', router);
  return app;
};

/** Thay static của model bằng chain giả và ghi lại filter đã dùng. */
const stubTransaction = (rows = []) => {
  const original = { find: Transaction.find, countDocuments: Transaction.countDocuments };
  const captured = { findFilters: [], countFilters: [] };

  const chain = {
    populate: () => chain,
    sort: () => chain,
    skip: () => chain,
    limit: () => chain,
    lean: async () => rows,
  };

  Transaction.find = (filter) => {
    captured.findFilters.push(filter);
    return chain;
  };
  Transaction.countDocuments = async (filter) => {
    captured.countFilters.push(filter);
    return rows.length;
  };

  return {
    captured,
    restore() {
      Transaction.find = original.find;
      Transaction.countDocuments = original.countDocuments;
    },
  };
};

test('danh sách quản trị không có user vẫn không tự thêm bộ lọc user', async () => {
  const stub = stubTransaction([{ _id: 'tx1' }]);

  try {
    await request(buildApp()).get('/api/transactions/admin/all?status=pending');

    assert.deepEqual(stub.captured.findFilters[0], { status: 'pending' });
  } finally {
    stub.restore();
  }
});
