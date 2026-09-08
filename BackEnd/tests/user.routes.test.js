import assert from 'node:assert/strict';
import test from 'node:test';

import express from 'express';
import request from 'supertest';

import { errorHandler } from '../src/middleware/error.middleware.js';
import { createUserRoutes } from '../src/modules/users/user.routes.js';

const USER_ID = '507f1f77bcf86cd799439011';

const passthrough = (user) => (req, _res, next) => {
  req.user = user;
  next();
};

/** App tối thiểu: router thật + service giả + auth giả, không cần MongoDB. */
const buildApp = (authService) => {
  const app = express();
  app.use(express.json());
  app.use(
    '/api/users',
    createUserRoutes({
      authService,
      authenticate: passthrough({ _id: USER_ID, VaiTro: 'user' }),
      authorizeAdmin: passthrough({ _id: USER_ID, VaiTro: 'admin' }),
      uploadAvatar: (_req, _res, next) => next(),
    }),
  );
  app.use(errorHandler);
  return app;
};

/** Service giả ghi lại mọi lời gọi để khẳng định "không chạm tới nghiệp vụ". */
const recordingService = (overrides = {}) => {
  const calls = [];
  const record = (name) => async (args) => {
    calls.push([name, args]);
    return { message: 'ok' };
  };

  return {
    calls,
    login: record('login'),
    forgotPassword: record('forgotPassword'),
    resetPassword: record('resetPassword'),
    changePassword: record('changePassword'),
    ...overrides,
  };
};

test('email dạng mảng bị chặn trước khi chạm tới nghiệp vụ', async () => {
  const service = recordingService();
  const app = buildApp(service);

  const response = await request(app)
    .post('/api/users/forgot-password')
    .send({ email: ['victim@example.com', 'attacker@example.com'] });

  assert.equal(response.status, 400);
  assert.equal(response.body.code, 'VALIDATION_ERROR');
  assert.equal(service.calls.length, 0);
});

test('email dạng toán tử Mongo bị chặn', async () => {
  const service = recordingService();
  const app = buildApp(service);

  for (const email of [{ $ne: null }, { $gt: '' }, { $regex: '.*' }, null, 42]) {
    const response = await request(app)
      .post('/api/users/forgot-password')
      .send({ email });

    assert.equal(response.status, 400, `email=${JSON.stringify(email)}`);
  }

  assert.equal(service.calls.length, 0);
});

test('email hợp lệ đi tới service đúng một lần', async () => {
  const service = recordingService({
    forgotPassword: async (args) => {
      service.calls.push(['forgotPassword', args]);
      return { message: 'Nếu email tồn tại, hướng dẫn đặt lại mật khẩu sẽ được gửi.' };
    },
  });
  const app = buildApp(service);

  const response = await request(app)
    .post('/api/users/forgot-password')
    .send({ email: '  victim@example.com  ' });

  assert.equal(response.status, 200);
  assert.match(response.body.message, /Nếu email tồn tại/);
  assert.deepEqual(service.calls, [
    ['forgotPassword', { email: 'victim@example.com' }],
  ]);
});

test('tên đăng nhập dạng mảng bị chặn trước khi truy vấn', async () => {
  const service = recordingService();
  const app = buildApp(service);

  const response = await request(app)
    .post('/api/users/login')
    .send({ username: ['a', 'b'], password: 'x' });

  assert.equal(response.status, 400);
  assert.equal(service.calls.length, 0);
});

test('đăng nhập thành công giữ nguyên vỏ response cũ', async () => {
  const service = recordingService({
    login: async () => ({
      user: { _id: USER_ID, TenDangNhap: 'victim' },
      token: 'jwt-token',
      streak: { current: 1 },
    }),
  });
  const app = buildApp(service);

  const response = await request(app)
    .post('/api/users/login')
    .send({ username: 'victim', password: 'correct-horse' });

  assert.equal(response.status, 200);
  assert.equal(response.body.message, 'Đăng nhập thành công');
  assert.equal(response.body.token, 'jwt-token');
  assert.equal(response.body.user.TenDangNhap, 'victim');
  assert.deepEqual(response.body.streak, { current: 1 });
});

test('đặt lại mật khẩu yêu cầu token và mật khẩu tối thiểu 8 ký tự', async () => {
  const service = recordingService();
  const app = buildApp(service);

  const missingToken = await request(app)
    .post('/api/users/reset-password')
    .send({ newPassword: 'mat-khau-du-dai' });
  assert.equal(missingToken.status, 400);

  const shortPassword = await request(app)
    .post('/api/users/reset-password')
    .send({ token: 'abc', newPassword: 'ngan' });
  assert.equal(shortPassword.status, 400);

  assert.equal(service.calls.length, 0);
});

test('đổi mật khẩu kiểm tra định dạng id và truyền actor từ req.user', async () => {
  const service = recordingService();
  const app = buildApp(service);

  const badId = await request(app)
    .put('/api/users/change-password/khong-phai-id')
    .send({ oldPassword: 'cu', newPassword: 'mat-khau-moi' });
  assert.equal(badId.status, 400);

  const ok = await request(app)
    .put(`/api/users/change-password/${USER_ID}`)
    .send({ oldPassword: 'cu', newPassword: 'mat-khau-moi' });

  assert.equal(ok.status, 200);
  assert.deepEqual(service.calls, [
    [
      'changePassword',
      {
        actor: { _id: USER_ID, VaiTro: 'user' },
        targetUserId: USER_ID,
        oldPassword: 'cu',
        newPassword: 'mat-khau-moi',
      },
    ],
  ]);
});

test('lỗi nghiệp vụ được error middleware dịch sang status tương ứng', async () => {
  const { ApiError } = await import('../src/shared/http/api-error.js');
  const app = buildApp(
    recordingService({
      login: async () => {
        throw ApiError.unauthorized('Mật khẩu không đúng.');
      },
    }),
  );

  const response = await request(app)
    .post('/api/users/login')
    .send({ username: 'victim', password: 'sai' });

  assert.equal(response.status, 401);
  assert.equal(response.body.message, 'Mật khẩu không đúng.');
});
