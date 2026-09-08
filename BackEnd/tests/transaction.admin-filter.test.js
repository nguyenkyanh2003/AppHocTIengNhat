import assert from 'node:assert/strict';
import test from 'node:test';

import express from 'express';
import request from 'supertest';

import Transaction from '../model/Transaction.js';
import {
  getAdminAll,
  getAdminUserByUserId,
} from '../src/modules/transactions/transaction.controller.js';

const USER_ID = '507f1f77bcf86cd799439011';
const OTHER_USER_ID = '507f1f77bcf86cd799439012';

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
  router.get('/admin/user/:userId', getAdminUserByUserId);

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

test('lịch sử giao dịch của một người dùng lọc đúng theo user trong path', async () => {
  const stub = stubTransaction([{ _id: 'tx1' }]);

  try {
    const response = await request(buildApp()).get(
      `/api/transactions/admin/user/${USER_ID}`,
    );

    assert.equal(response.status, 200);
    assert.equal(stub.captured.findFilters.length, 1);
    assert.deepEqual(stub.captured.findFilters[0], { user: USER_ID });
    // Danh sách và đếm phải dùng chung một filter.
    assert.deepEqual(stub.captured.countFilters[0], stub.captured.findFilters[0]);
  } finally {
    stub.restore();
  }
});

test('userId trên query không ghi đè được user trong path', async () => {
  const stub = stubTransaction();

  try {
    const response = await request(buildApp()).get(
      `/api/transactions/admin/user/${USER_ID}?userId=${OTHER_USER_ID}`,
    );

    assert.equal(response.status, 200);
    assert.equal(stub.captured.findFilters[0].user, USER_ID);
  } finally {
    stub.restore();
  }
});

test('các bộ lọc bổ sung vẫn có hiệu lực cùng user trong path', async () => {
  const stub = stubTransaction();

  try {
    await request(buildApp()).get(
      `/api/transactions/admin/user/${USER_ID}?status=completed&type=DEPOSIT&startDate=2026-01-01&endDate=2026-02-01`,
    );

    const filter = stub.captured.findFilters[0];
    assert.equal(filter.user, USER_ID);
    assert.equal(filter.status, 'completed');
    assert.equal(filter.type, 'DEPOSIT');
    assert.equal(filter.createdAt.$gte.toISOString(), new Date('2026-01-01').toISOString());
    assert.equal(filter.createdAt.$lte.toISOString(), new Date('2026-02-01').toISOString());
  } finally {
    stub.restore();
  }
});

test('danh sách rỗng trả 200 với mảng rỗng và phân trang hợp lệ', async () => {
  const stub = stubTransaction([]);

  try {
    const response = await request(buildApp()).get(
      `/api/transactions/admin/user/${USER_ID}?page=2&limit=5`,
    );

    assert.equal(response.status, 200);
    assert.deepEqual(response.body.data, []);
    assert.equal(response.body.totalItems, 0);
    assert.equal(response.body.currentPage, 2);
  } finally {
    stub.restore();
  }
});

test('danh sách quản trị không có user vẫn không tự thêm bộ lọc user', async () => {
  const stub = stubTransaction([{ _id: 'tx1' }]);

  try {
    await request(buildApp()).get('/api/transactions/admin/all?status=pending');

    assert.deepEqual(stub.captured.findFilters[0], { status: 'pending' });
  } finally {
    stub.restore();
  }
});
