import assert from 'node:assert/strict';
import test from 'node:test';

import express from 'express';
import request from 'supertest';

import { errorHandler } from '../src/middleware/error.middleware.js';
import { ApiError } from '../src/shared/http/api-error.js';
import { createReportRoutes } from '../src/modules/reports/report.routes.js';

const ID = '507f1f77bcf86cd799439011';
const REPORT = { _id: ID, title: 'Lỗi', status: 'pending' };

const buildApp = (service, { admin = true } = {}) => {
  const app = express();
  app.use(express.json());
  app.use('/api/report', createReportRoutes({
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

const body = { type: 'bug', title: 'Lỗi', description: 'Không mở được bài học', priority: 'high', related_id: null };

test('POST /create gửi báo cáo của chính người đăng nhập, 201', async () => {
  const { calls, service } = recording({ create: REPORT });

  const response = await request(buildApp(service)).post('/api/report/create').send(body);

  assert.equal(response.status, 201);
  assert.equal(response.body.data._id, ID);
  assert.match(response.body.message, /thành công/);
  assert.deepEqual(calls, [['create', { userId: 'user-1', input: { ...body, related_id: null } }]]);
});

test('POST /create thiếu tiêu đề, loại lạ hay tự đặt trạng thái là 400', async () => {
  const { calls, service } = recording({ create: REPORT });
  const app = buildApp(service);

  for (const invalid of [{ ...body, title: ' ' }, { ...body, type: 'spam' }, { ...body, priority: 'max' }, { ...body, related_id: 'abc' }]) {
    assert.equal((await request(app).post('/api/report/create').send(invalid)).status, 400, JSON.stringify(invalid));
  }
  const withStatus = await request(app).post('/api/report/create').send({ ...body, status: 'resolved' });
  assert.equal(withStatus.status, 201);
  assert.equal('status' in calls.at(-1)[1].input, false, 'trạng thái do server đặt, không lấy từ body');
});

test('GET /my-reports trả trang báo cáo của mình theo contract phân trang', async () => {
  const { calls, service } = recording({ listMine: { items: [REPORT], total: 1, page: 1, limit: 10 } });

  const response = await request(buildApp(service)).get('/api/report/my-reports?limit=10&status=pending');

  assert.deepEqual(response.body, { data: [REPORT], page: 1, limit: 10, total: 1, totalPages: 1 });
  assert.deepEqual(calls, [['listMine', { userId: 'user-1', page: 1, limit: 10, status: 'pending' }]]);
});

test('quản trị: danh sách, đổi trạng thái, xoá, thống kê đều trả `{ data }`', async () => {
  const { calls, service } = recording({
    listAll: { items: [REPORT], total: 1, page: 1, limit: 20 },
    updateStatus: { ...REPORT, status: 'resolved' },
    remove: undefined,
    stats: { total: 1 },
  });
  const app = buildApp(service);

  assert.deepEqual((await request(app).get('/api/report/admin/all?type=bug&user_id=')).body.data, [REPORT]);
  assert.deepEqual(calls.at(-1), ['listAll', { page: 1, limit: 20, type: 'bug', status: undefined, priority: undefined, userId: undefined }]);

  const updated = await request(app).put(`/api/report/admin/${ID}/status`).send({ status: 'resolved', admin_response: '' });
  assert.equal(updated.body.data.status, 'resolved');
  assert.deepEqual(calls.at(-1), ['updateStatus', { id: ID, status: 'resolved', adminResponse: undefined }]);

  assert.deepEqual((await request(app).delete(`/api/report/admin/${ID}`)).body.data, { deleted: true });
  assert.deepEqual((await request(app).get('/api/report/admin/stats')).body, { data: { total: 1 } });
});

test('quản trị: trạng thái lạ là 400; báo cáo không có là 404; người thường bị chặn', async () => {
  const missing = recording({ updateStatus: ApiError.notFound('Không tìm thấy báo cáo.') });
  const app = buildApp(missing.service);
  assert.equal((await request(app).put(`/api/report/admin/${ID}/status`).send({ status: 'done' })).status, 400);
  assert.equal((await request(app).put(`/api/report/admin/${ID}/status`).send({ status: 'resolved' })).status, 404);

  const { calls, service } = recording({ listAll: {} });
  assert.equal((await request(buildApp(service, { admin: false })).get('/api/report/admin/all')).status, 403);
  assert.deepEqual(calls, []);
});
