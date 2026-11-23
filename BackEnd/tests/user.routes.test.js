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
const buildApp = (authService, { userService = {}, file } = {}) => {
  const app = express();
  app.use(express.json());
  app.use(
    '/api/users',
    createUserRoutes({
      authService,
      userService,
      authenticate: passthrough({ _id: USER_ID, VaiTro: 'user' }),
      authorizeAdmin: passthrough({ _id: USER_ID, VaiTro: 'admin' }),
      uploadAvatar: (req, _res, next) => {
        if (file) req.file = file;
        next();
      },
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

test('đăng nhập thành công bọc phiên trong `data`', async () => {
  const service = recordingService({
    login: async () => ({
      user: { _id: USER_ID, TenDangNhap: 'victim' },
      token: 'jwt-token',
      refreshToken: 'refresh-token',
      streak: { current: 1 },
    }),
  });
  const app = buildApp(service);

  const response = await request(app)
    .post('/api/users/login')
    .send({ username: 'victim', password: 'correct-horse' });

  assert.equal(response.status, 200);
  assert.equal(response.body.message, 'Đăng nhập thành công');
  assert.deepEqual(response.body.data, {
    user: { _id: USER_ID, TenDangNhap: 'victim' },
    token: 'jwt-token',
    refreshToken: 'refresh-token',
    streak: { current: 1 },
  });
});

test('làm mới phiên trả cặp token mới trong `data`', async () => {
  const service = recordingService({
    refresh: async (args) => {
      service.calls.push(['refresh', args]);
      return { token: 'access-moi', refreshToken: 'refresh-moi' };
    },
  });
  const app = buildApp(service);

  const response = await request(app).post('/api/users/refresh-token').send({ refreshToken: 'refresh-cu' });

  assert.equal(response.status, 200);
  assert.deepEqual(response.body, { data: { token: 'access-moi', refreshToken: 'refresh-moi' } });
  assert.deepEqual(service.calls, [['refresh', { refreshToken: 'refresh-cu' }]]);

  for (const body of [{}, { refreshToken: '' }, { refreshToken: ['a', 'b'] }, { refreshToken: { $ne: null } }]) {
    assert.equal((await request(app).post('/api/users/refresh-token').send(body)).status, 400, JSON.stringify(body));
  }
});

test('đăng xuất không cần access token còn hạn; gửi kèm token nào thì service nhận token đó', async () => {
  const service = recordingService({
    logout: async (args) => {
      service.calls.push(['logout', args]);
      return { message: 'Đăng xuất thành công' };
    },
  });
  const app = buildApp(service);

  const withoutHeader = await request(app).post('/api/users/logout').send({ refreshToken: 'refresh-cu' });
  const withHeader = await request(app)
    .post('/api/users/logout')
    .set('Authorization', 'Bearer access-cu')
    .send({});

  assert.equal(withoutHeader.status, 200);
  assert.equal(withHeader.status, 200);
  assert.deepEqual(service.calls, [
    ['logout', { refreshToken: 'refresh-cu', accessToken: undefined }],
    ['logout', { refreshToken: undefined, accessToken: 'access-cu' }],
  ]);
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

const recording = (methods) => {
  const calls = [];
  const service = Object.fromEntries(Object.entries(methods).map(([name, result]) => [name, async (args) => {
    calls.push([name, args]);
    return result;
  }]));
  return { calls, service };
};

const PROFILE = { _id: USER_ID, HoTen: 'Nguyễn An' };

test('đăng ký 201 bọc người dùng trong `data`', async () => {
  const { calls, service } = recording({ register: PROFILE });
  const body = { username: 'an', hoTen: 'Nguyễn An', email: 'an@example.com', password: '12345678' };

  const response = await request(buildApp({}, { userService: service })).post('/api/users/register').send(body);

  assert.equal(response.status, 201);
  assert.deepEqual(response.body.data, PROFILE);
  assert.deepEqual(calls, [['register', body]]);
});

test('hồ sơ: xem, sửa, đổi ảnh đều theo id trong path và người đang đăng nhập', async () => {
  const { calls, service } = recording({ profile: PROFILE, updateProfile: PROFILE, setAvatar: PROFILE });
  const image = Buffer.from([0xff, 0xd8, 0xff]);
  const app = buildApp({}, { userService: service, file: { buffer: image } });
  const actor = { _id: USER_ID, VaiTro: 'user' };

  assert.deepEqual((await request(app).get(`/api/users/profile/${USER_ID}`)).body, { data: PROFILE });
  await request(app).put(`/api/users/profile/${USER_ID}`).send({ hoTen: 'An', VaiTro: 'admin' });
  await request(app).put(`/api/users/profile/${USER_ID}/avatar`);
  assert.equal((await request(app).put(`/api/users/profile/${USER_ID}`).send({ gioiTinh: 'Không rõ' })).status, 400);

  assert.deepEqual(calls, [
    ['profile', { actor, userId: USER_ID }],
    ['updateProfile', { actor, userId: USER_ID, changes: { hoTen: 'An' } }],
    ['setAvatar', { actor, userId: USER_ID, image }],
  ]);
});

test('quản trị: danh sách phân trang, sửa, xoá một người, thống kê; xoá hàng loạt đã bị gỡ', async () => {
  const { calls, service } = recording({
    adminList: { items: [PROFILE], total: 1, page: 1, limit: 20 },
    adminUpdate: PROFILE,
    adminRemove: undefined,
    adminStats: { totalUsers: 1 },
  });
  const app = buildApp({}, { userService: service });

  assert.deepEqual((await request(app).get('/api/users/admin/users?role=admin')).body, {
    data: [PROFILE], page: 1, limit: 20, total: 1, totalPages: 1,
  });
  await request(app).put(`/api/users/admin/users/${USER_ID}`).send({ trangThai: 'banned' });
  assert.deepEqual((await request(app).delete(`/api/users/admin/users/${USER_ID}`)).body.data, { deleted: true });
  assert.deepEqual((await request(app).get('/api/users/admin/stats')).body, { data: { totalUsers: 1 } });
  assert.equal((await request(app).put(`/api/users/admin/users/${USER_ID}`).send({ vaiTro: 'root' })).status, 400);
  assert.equal((await request(app).delete('/api/users/admin/users')).status, 404);

  assert.deepEqual(calls, [
    ['adminList', { page: 1, limit: 20, role: 'admin' }],
    ['adminUpdate', { userId: USER_ID, changes: { trangThai: 'banned' } }],
    ['adminRemove', { actor: { _id: USER_ID, VaiTro: 'admin' }, userId: USER_ID }],
    ['adminStats', undefined],
  ]);
});

test('giới hạn đăng nhập chỉ đếm lần sai: cả lớp đăng nhập đúng qua một mạng không bị chặn', async () => {
  const { ApiError } = await import('../src/shared/http/api-error.js');
  let correct = true;
  const app = buildApp(recordingService({
    login: async () => {
      if (!correct) throw ApiError.unauthorized('Tên đăng nhập hoặc mật khẩu không đúng.');
      return { token: 't' };
    },
  }));
  const login = async () => (await request(app).post('/api/users/login').send({ username: 'lop', password: 'mat-khau' })).status;

  const successes = [];
  for (let i = 0; i < 25; i += 1) successes.push(await login());
  assert.ok(successes.every((status) => status === 200), `đăng nhập đúng bị chặn: ${successes}`);

  correct = false;
  const failures = [];
  for (let i = 0; i < 21; i += 1) failures.push(await login());
  assert.ok(failures.includes(429), 'đoán sai mật khẩu mãi mà không bị chặn');
});
