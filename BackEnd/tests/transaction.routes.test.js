import assert from 'node:assert/strict';
import test from 'node:test';

import express from 'express';
import request from 'supertest';

import { errorHandler } from '../src/middleware/error.middleware.js';
import { ApiError } from '../src/shared/http/api-error.js';
import { createTransactionRoutes } from '../src/modules/transactions/transaction.routes.js';

const ID = '507f1f77bcf86cd799439011';
const TRANSACTION = { _id: ID, type: 'SUBSCRIPTION', amount: 79000, status: 'pending' };

/**
 * Đi qua routing Express 5 thật: `req.query` ở đây là getter chỉ đọc, nên giá
 * trị đã ép kiểu chỉ có ở `req.valid` — đúng chỗ bản cũ từng mất bộ lọc.
 */
const buildApp = (service, { admin = true } = {}) => {
  const app = express();
  app.use(express.json());
  app.use('/api/transactions', createTransactionRoutes({
    service,
    authenticate: (req, _res, next) => { req.user = { _id: 'user-1' }; next(); },
    authorizeAdmin: (req, res, next) => {
      if (!admin) return res.status(403).json({ message: 'Chỉ admin.' });
      req.user = { _id: 'admin-1' };
      return next();
    },
  }));
  app.use(errorHandler);
  return app;
};

const recording = (methods) => {
  const calls = [];
  const service = Object.fromEntries(Object.entries(methods).map(([name, result]) => [name, async (args) => {
    calls.push([name, args]);
    if (result instanceof Error) throw result;
    return result;
  }]));
  return { calls, service };
};

const body = { type: 'SUBSCRIPTION', amount: 79000, payment_method: 'NONE', package_id: 'pro', description: 'Đăng ký gói pro' };

test('POST /create tạo yêu cầu của chính người đăng nhập, 201 kèm mặc định của server', async () => {
  const { calls, service } = recording({ create: TRANSACTION });

  const response = await request(buildApp(service)).post('/api/transactions/create').send(body);

  assert.equal(response.status, 201);
  assert.deepEqual(response.body.data, TRANSACTION);
  assert.match(response.body.message, /yêu cầu giao dịch/);
  assert.deepEqual(calls, [['create', { userId: 'user-1', input: { ...body, currency: 'VND' } }]]);
});

test('POST /create sai loại, số tiền, phương thức hay tiền tệ là 400; trạng thái và người dùng do server đặt', async () => {
  const { calls, service } = recording({ create: TRANSACTION });
  const app = buildApp(service);

  for (const invalid of [
    { ...body, type: 'GIFT' },
    { ...body, amount: 0 },
    { ...body, amount: '79000' },
    { ...body, payment_method: 'PAYPAL' },
    { ...body, currency: 'USD' },
  ]) {
    assert.equal((await request(app).post('/api/transactions/create').send(invalid)).status, 400, JSON.stringify(invalid));
  }
  assert.deepEqual(calls, []);

  await request(app).post('/api/transactions/create').send({ ...body, status: 'completed', user: 'someone-else' });
  const { input } = calls.at(-1)[1];
  assert.equal('status' in input, false);
  assert.equal('user' in input, false);
});

test('GET /admin/all trả trang giao dịch theo contract phân trang, đọc bộ lọc đã ép kiểu', async () => {
  const { calls, service } = recording({ listAll: { items: [TRANSACTION], total: 21, page: 2, limit: 20 } });

  const response = await request(buildApp(service))
    .get(`/api/transactions/admin/all?page=2&status=pending&type=&userId=${ID}&startDate=2026-11-01`);

  assert.deepEqual(response.body, { data: [TRANSACTION], page: 2, limit: 20, total: 21, totalPages: 2 });
  assert.deepEqual(calls, [['listAll', {
    page: 2,
    limit: 20,
    status: 'pending',
    type: undefined,
    userId: ID,
    startDate: new Date('2026-11-01'),
  }]]);
});

test('GET /admin/all: bộ lọc sai hay khoảng ngày ngược là 400; người thường bị chặn', async () => {
  const { calls, service } = recording({ listAll: { items: [], total: 0, page: 1, limit: 20 } });
  const app = buildApp(service);

  for (const query of ['status=done', 'userId=abc', 'startDate=hôm-qua', 'startDate=2026-11-14&endDate=2026-11-01']) {
    assert.equal((await request(app).get(`/api/transactions/admin/all?${query}`)).status, 400, query);
  }
  assert.equal((await request(buildApp(service, { admin: false })).get('/api/transactions/admin/all')).status, 403);
  assert.deepEqual(calls, []);
});

test('PUT /admin/:id/status đổi trạng thái kèm ghi chú; trạng thái lạ 400, không có giao dịch 404', async () => {
  const { calls, service } = recording({ updateStatus: { ...TRANSACTION, status: 'completed' } });

  const response = await request(buildApp(service))
    .put(`/api/transactions/admin/${ID}/status`)
    .send({ status: 'completed', notes: '' });

  assert.equal(response.body.data.status, 'completed');
  assert.match(response.body.message, /thành công/);
  assert.deepEqual(calls, [['updateStatus', { id: ID, status: 'completed', notes: undefined }]]);

  const missing = buildApp(recording({ updateStatus: ApiError.notFound('Không tìm thấy giao dịch.') }).service);
  assert.equal((await request(missing).put(`/api/transactions/admin/${ID}/status`).send({ status: 'paid' })).status, 400);
  assert.equal((await request(missing).put('/api/transactions/admin/abc/status').send({ status: 'completed' })).status, 400);
  assert.equal((await request(missing).put(`/api/transactions/admin/${ID}/status`).send({ status: 'completed' })).status, 404);
});
