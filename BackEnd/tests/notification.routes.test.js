import assert from 'node:assert/strict';
import test from 'node:test';

import express from 'express';
import request from 'supertest';

import { errorHandler } from '../src/middleware/error.middleware.js';
import { timezoneMiddleware } from '../src/middleware/timezone.middleware.js';
import { ApiError } from '../src/shared/http/api-error.js';
import { createNotificationRoutes } from '../src/modules/notifications/notification.routes.js';

const ID = '507f1f77bcf86cd799439011';
const DTO = { id: ID, title: 'Chào', message: 'Học tiếp nhé', type: 'SYSTEM', data: {}, is_read: false, read_at: null, created_at: '2026-11-04T08:00:00.000Z' };

/**
 * App tối thiểu: router thật + service giả + auth giả, không cần MongoDB. Gắn
 * cả `timezoneMiddleware` như `app.js`, để test thấy đúng response client nhận.
 */
const buildApp = (service, { admin = true } = {}) => {
  const app = express();
  app.use(express.json());
  app.use(timezoneMiddleware);
  app.use(
    '/api/notifications',
    createNotificationRoutes({
      service,
      authenticate: (req, _res, next) => { req.user = { _id: 'user-1' }; next(); },
      authorizeAdmin: (req, _res, next) => {
        if (!admin) return next(ApiError.forbidden('Chỉ admin.'));
        req.user = { _id: 'admin-1' };
        return next();
      },
    }),
  );
  app.use(errorHandler);
  return app;
};

const recording = (methods) => {
  const calls = [];
  const service = Object.fromEntries(
    Object.entries(methods).map(([name, result]) => [name, async (args) => {
      calls.push([name, args]);
      if (result instanceof Error) throw result;
      return result;
    }]),
  );
  return { calls, service };
};

test('GET / trả danh sách phân trang của người đang đăng nhập', async () => {
  const { calls, service } = recording({ list: { items: [DTO], page: 1, limit: 20, total: 1 } });

  const response = await request(buildApp(service)).get('/api/notifications');

  assert.equal(response.status, 200);
  assert.deepEqual(response.body, { data: [DTO], page: 1, limit: 20, total: 1, totalPages: 1 });
  assert.deepEqual(calls, [['list', { userId: 'user-1', page: 1, limit: 20, status: 'all' }]]);
});

test('GET / lọc chưa đọc; bộ lọc lạ hoặc limit vượt trần là 400', async () => {
  const { calls, service } = recording({ list: { items: [], page: 2, limit: 5, total: 0 } });
  const app = buildApp(service);

  const response = await request(app).get('/api/notifications?status=unread&page=2&limit=5');
  assert.equal(response.status, 200);
  assert.deepEqual(response.body.data, []);
  assert.equal(calls[0][1].status, 'unread');

  for (const query of ['status=ChuaDoc', 'limit=1000', 'type=achievement']) {
    assert.equal((await request(app).get(`/api/notifications?${query}`)).status, 400, query);
  }
});

test('GET / lọc theo loại; không gửi loại thì không lọc', async () => {
  const { calls, service } = recording({ list: { items: [], page: 1, limit: 5, total: 0 } });
  const app = buildApp(service);

  assert.equal((await request(app).get('/api/notifications?status=unread&type=ACHIEVEMENT&limit=5')).status, 200);
  assert.equal((await request(app).get('/api/notifications')).status, 200);

  assert.deepEqual(calls[0][1], { userId: 'user-1', page: 1, limit: 5, status: 'unread', type: 'ACHIEVEMENT' });
  assert.equal('type' in calls[1][1], false);
});

test('admin không gửi được thông báo huy hiệu giả — loại đó chỉ hệ thống tạo', async () => {
  const { calls, service } = recording({ sendToUser: DTO, broadcast: 2 });
  const app = buildApp(service);

  const one = await request(app)
    .post('/api/notifications')
    .send({ recipient_id: ID, title: 'Huy hiệu', message: 'X', type: 'ACHIEVEMENT' });
  const all = await request(app)
    .post('/api/notifications/broadcast/all')
    .send({ title: 'Huy hiệu', message: 'X', type: 'ACHIEVEMENT' });

  assert.equal(one.status, 400);
  assert.equal(all.status, 400);
  assert.deepEqual(calls, []);
});

test('GET /count/unread trả { data: { unread_count } }', async () => {
  const { calls, service } = recording({ countUnread: 3 });

  const response = await request(buildApp(service)).get('/api/notifications/count/unread');

  assert.deepEqual(response.body, { data: { unread_count: 3 } });
  assert.deepEqual(calls, [['countUnread', 'user-1']]);
});

test('PUT /read/:id trả thông báo đã đọc; ID sai định dạng 400, không thuộc mình 404', async () => {
  const { calls, service } = recording({ markRead: { ...DTO, is_read: true } });
  const app = buildApp(service);

  const response = await request(app).put(`/api/notifications/read/${ID}`);
  assert.equal(response.status, 200);
  assert.equal(response.body.data.is_read, true);
  assert.deepEqual(calls, [['markRead', { id: ID, userId: 'user-1' }]]);

  assert.equal((await request(app).put('/api/notifications/read/khong-hop-le')).status, 400);

  const missing = recording({ markRead: ApiError.notFound('Không tìm thấy thông báo.') });
  assert.equal((await request(buildApp(missing.service)).put(`/api/notifications/read/${ID}`)).status, 404);
});

test('PUT /read-all không còn gì để đọc vẫn 200', async () => {
  const { service } = recording({ markAllRead: 0 });

  const response = await request(buildApp(service)).put('/api/notifications/read-all');

  assert.equal(response.status, 200);
  assert.deepEqual(response.body, { data: { updated: 0 } });
});

test('DELETE /:id xoá thông báo của mình; không thuộc mình là 404', async () => {
  const { calls, service } = recording({ remove: undefined });

  const response = await request(buildApp(service)).delete(`/api/notifications/${ID}`);
  assert.equal(response.status, 200);
  assert.deepEqual(response.body, { data: { deleted: true } });
  assert.deepEqual(calls, [['remove', { id: ID, userId: 'user-1' }]]);

  const missing = recording({ remove: ApiError.notFound('Không tìm thấy thông báo.') });
  assert.equal((await request(buildApp(missing.service)).delete(`/api/notifications/${ID}`)).status, 404);
});

test('POST / admin gửi cho một người, loại mặc định SYSTEM, ghi người gửi', async () => {
  const { calls, service } = recording({ sendToUser: DTO });

  const response = await request(buildApp(service))
    .post('/api/notifications')
    .send({ recipient_id: ID, title: '  Chào  ', message: 'Học tiếp nhé' });

  assert.equal(response.status, 201);
  assert.deepEqual(response.body, { data: DTO });
  assert.deepEqual(calls, [['sendToUser', { recipientId: ID, senderId: 'admin-1', title: 'Chào', message: 'Học tiếp nhé', type: 'SYSTEM' }]]);
});

test('POST / chặn 400 khi thiếu nội dung, sai loại hoặc gửi tên trường cũ', async () => {
  const { service } = recording({ sendToUser: DTO });
  const app = buildApp(service);

  for (const body of [
    { recipient_id: ID, title: 'Chào' },
    { recipient_id: ID, title: 'Chào', message: 'X', type: 'admin_message' },
    { NguoiHocID: ID, TieuDe: 'Chào', NoiDung: 'X' },
    { recipient_id: 'abc', title: 'Chào', message: 'X' },
  ]) {
    const response = await request(app).post('/api/notifications').send(body);
    assert.equal(response.status, 400, JSON.stringify(body));
  }
});

test('POST /broadcast/all trả số người đã gửi', async () => {
  const { calls, service } = recording({ broadcast: 2 });

  const response = await request(buildApp(service))
    .post('/api/notifications/broadcast/all')
    .send({ title: 'Kỳ thi', message: 'Tháng 12', type: 'EXAM' });

  assert.equal(response.status, 201);
  assert.deepEqual(response.body, { data: { sent: 2 } });
  assert.deepEqual(calls, [['broadcast', { senderId: 'admin-1', title: 'Kỳ thi', message: 'Tháng 12', type: 'EXAM' }]]);
});

test('thời điểm tạo và đọc giữ ISO 8601 có múi giờ sau middleware giờ Việt Nam', async () => {
  const read = { ...DTO, is_read: true, read_at: '2026-11-04T09:00:00.000Z' };
  const { service } = recording({ list: { items: [read], page: 1, limit: 20, total: 1 }, markRead: read });
  const app = buildApp(service);

  const list = await request(app).get('/api/notifications');
  const single = await request(app).put(`/api/notifications/read/${ID}`);

  for (const item of [list.body.data[0], single.body.data]) {
    assert.equal(item.created_at, '2026-11-04T08:00:00.000Z');
    assert.equal(item.read_at, '2026-11-04T09:00:00.000Z');
  }
});

test('người dùng thường không gọi được hai route gửi', async () => {
  const { calls, service } = recording({ sendToUser: DTO, broadcast: 2 });
  const app = buildApp(service, { admin: false });

  assert.equal((await request(app).post('/api/notifications').send({ recipient_id: ID, title: 'A', message: 'B' })).status, 403);
  assert.equal((await request(app).post('/api/notifications/broadcast/all').send({ title: 'A', message: 'B' })).status, 403);
  assert.deepEqual(calls, []);
});
