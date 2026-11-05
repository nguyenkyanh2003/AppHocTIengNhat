import assert from 'node:assert/strict';
import test from 'node:test';

import express from 'express';
import request from 'supertest';

import { errorHandler } from '../src/middleware/error.middleware.js';
import { createUserRoutes } from '../src/modules/users/user.routes.js';
import { PASSWORD_MIN_LENGTH, registerBody } from '../src/modules/users/user.schema.js';

const VALID = { username: 'an', hoTen: 'Nguyễn An', email: 'an@example.com', password: '12345678' };

/** Router thật; mọi ca ở đây bị chặn ở schema nên không chạm tới MongoDB. */
const buildApp = () => {
  const app = express();
  app.use(express.json());
  app.use('/api/users', createUserRoutes({
    authService: {},
    authenticate: (_req, _res, next) => next(),
    authorizeAdmin: (_req, _res, next) => next(),
    uploadAvatar: (_req, _res, next) => next(),
  }));
  app.use(errorHandler);
  return app;
};

test('một ngưỡng mật khẩu chung cho đăng ký, đặt lại và đổi mật khẩu: 8 ký tự', () => {
  assert.equal(PASSWORD_MIN_LENGTH, 8);
  assert.equal(registerBody.safeParse({ ...VALID, password: '1234567' }).success, false);
  assert.equal(registerBody.safeParse({ ...VALID, password: '12345678' }).success, true);
});

test('đăng ký: mật khẩu dưới 8 ký tự bị chặn 400 với đúng thông điệp', async () => {
  const response = await request(buildApp()).post('/api/users/register').send({ ...VALID, password: '1234567' });

  assert.equal(response.status, 400);
  assert.equal(response.body.code, 'VALIDATION_ERROR');
  assert.deepEqual(response.body.details, [{ path: 'password', message: 'Mật khẩu phải có ít nhất 8 ký tự.' }]);
});

test('đăng ký: thiếu trường, email sai, hoặc giá trị dạng object/mảng bị chặn trước khi truy vấn', async () => {
  const app = buildApp();

  for (const body of [
    { ...VALID, hoTen: '   ' },
    { ...VALID, email: 'khong-phai-email' },
    { ...VALID, username: { $ne: null } },
    { ...VALID, email: ['an@example.com', 'b@example.com'] },
    { ...VALID, password: 12345678 },
    { ...VALID, trinhDo: 'N6' },
  ]) {
    const response = await request(app).post('/api/users/register').send(body);
    assert.equal(response.status, 400, JSON.stringify(body));
  }
});

test('đăng ký: cắt khoảng trắng, email về chữ thường, mật khẩu giữ nguyên', () => {
  const parsed = registerBody.parse({
    username: '  an  ', hoTen: ' Nguyễn An ', email: '  An@Example.COM ', password: ' pass word ', trinhDo: 'N4',
  });

  assert.deepEqual(parsed, {
    username: 'an', hoTen: 'Nguyễn An', email: 'an@example.com', password: ' pass word ', trinhDo: 'N4',
  });
});
