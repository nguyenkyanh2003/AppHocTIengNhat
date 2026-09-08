import assert from 'node:assert/strict';
import test from 'node:test';

import express from 'express';
import request from 'supertest';

import { createRateLimiter } from '../src/middleware/security.middleware.js';

/**
 * App tối thiểu: một handler duy nhất được gắn ở nhiều biến thể đường dẫn.
 *
 * Express mặc định không phân biệt hoa/thường và không bắt buộc dấu `/` cuối,
 * nên `/login`, `/Login` và `/login/` đều vào cùng handler này.
 */
const buildApp = (limiters) => {
  const app = express();
  const router = express.Router();

  for (const [path, limiter] of Object.entries(limiters)) {
    router.post(path, limiter, (_req, res) => res.json({ ok: true }));
  }

  app.use('/api/users', router);
  return app;
};

const limiterFor = (name, max = 2) =>
  createRateLimiter({
    name,
    max,
    windowMs: 60_000,
    message: 'Bạn đã thử quá nhiều lần. Vui lòng thử lại sau.',
  });

test('limiter bắt buộc có tên cố định', () => {
  assert.throws(
    () => createRateLimiter({ windowMs: 1000, max: 5, message: 'x' }),
    /name/,
  );
  assert.throws(() => createRateLimiter({ name: '  ', windowMs: 1000, max: 5 }), /name/);
});

test('biến thể hoa/thường và dấu gạch chéo cuối dùng chung một ngân sách thử', async () => {
  const app = buildApp({ '/login': limiterFor('case-variants', 2) });

  const statuses = [];
  for (const path of ['/login', '/Login', '/LOGIN', '/login/']) {
    const response = await request(app).post(`/api/users${path}`);
    statuses.push(response.status);
  }

  // Hai lần đầu nằm trong hạn mức, hai lần sau bị chặn dù URL viết khác đi.
  assert.deepEqual(statuses, [200, 200, 429, 429]);
});

test('mỗi nghiệp vụ có quota riêng', async () => {
  const app = buildApp({
    '/login': limiterFor('login-quota', 1),
    '/forgot-password': limiterFor('forgot-quota', 1),
  });

  assert.equal((await request(app).post('/api/users/login')).status, 200);
  assert.equal((await request(app).post('/api/users/login')).status, 429);

  // Đăng nhập bị khóa không được kéo theo đường khôi phục mật khẩu.
  assert.equal((await request(app).post('/api/users/forgot-password')).status, 200);
});

test('phản hồi 429 kèm Retry-After', async () => {
  const app = buildApp({ '/login': limiterFor('retry-after', 1) });

  await request(app).post('/api/users/login');
  const blocked = await request(app).post('/api/users/login');

  assert.equal(blocked.status, 429);
  assert.ok(Number(blocked.headers['retry-after']) > 0);
  assert.match(blocked.body.message, /quá nhiều lần/);
});
