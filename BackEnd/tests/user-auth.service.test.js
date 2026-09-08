import assert from 'node:assert/strict';
import test from 'node:test';

import { createAuthenticateUser } from '../src/middleware/auth.middleware.js';
import {
  buildResetLink,
  createUserAuthService,
} from '../src/modules/users/user-auth.service.js';

const JWT_SECRET = 'test-secret-at-least-32-characters-long';

const VICTIM = {
  _id: 'user-victim',
  TenDangNhap: 'victim',
  HoTen: 'Nạn Nhân',
  Email: 'victim@example.com',
  MatKhau: 'hashed:correct-horse',
  VaiTro: 'user',
  TrangThai: 'active',
  tokenVersion: 0,
};

const clone = (value) => (value ? { ...value } : null);

/** Repository giả giữ nguyên ngữ nghĩa version của bản thật, không cần MongoDB. */
const fakeUserRepository = (seed = [VICTIM]) => {
  const store = seed.map((user) => ({ ...user }));

  const find = (predicate) => store.find(predicate) ?? null;

  return {
    store,
    findByUsername: async (username) =>
      clone(find((user) => user.TenDangNhap === username)),
    findByEmail: async (email) => clone(find((user) => user.Email === email)),
    findById: async (id) => clone(find((user) => String(user._id) === String(id))),

    touchLastLogin: async ({ id, at }) => {
      const user = find((entry) => String(entry._id) === String(id));
      if (!user) return null;
      user.LanDangNhapCuoi = at;
      return clone(user);
    },

    replacePasswordIfVersionMatches: async ({ id, expectedVersion, passwordHash }) => {
      const user = find((entry) => String(entry._id) === String(id));
      if (!user) return null;
      if ((user.tokenVersion ?? 0) !== expectedVersion) return null;

      user.MatKhau = passwordHash;
      user.tokenVersion = (user.tokenVersion ?? 0) + 1;
      return clone(user);
    },

    replacePassword: async ({ id, passwordHash }) => {
      const user = find((entry) => String(entry._id) === String(id));
      if (!user) return null;

      user.MatKhau = passwordHash;
      user.tokenVersion = (user.tokenVersion ?? 0) + 1;
      return clone(user);
    },

    recordLoginStreak: async () => ({
      current: 1,
      longest: 1,
      total_xp: 10,
      is_new_day: true,
      streak_broken: false,
    }),
  };
};

const fakeMailer = ({ configured = true } = {}) => {
  const sent = [];
  return {
    sent,
    isConfigured: () => configured,
    sendPasswordReset: async (payload) => {
      sent.push(payload);
    },
  };
};

const fakeHasher = {
  hash: async (plain) => `hashed:${plain}`,
  compare: async (plain, hashed) => hashed === `hashed:${plain}`,
};

const buildService = ({ repository, mailer } = {}) =>
  createUserAuthService({
    userRepository: repository ?? fakeUserRepository(),
    mailer: mailer ?? fakeMailer(),
    passwordHasher: fakeHasher,
    jwtSecret: JWT_SECRET,
    frontendUrl: 'http://localhost:8080',
    now: () => new Date('2026-01-01T00:00:00.000Z'),
  });

/** Middleware thật, chỉ thay nguồn đọc user bằng repository giả. */
const buildAuthenticate = (repository) =>
  createAuthenticateUser({
    findUserById: (id) => repository.findById(id),
    jwtSecret: JWT_SECRET,
    bypassAuth: false,
  });

const runMiddleware = async (middleware, token) => {
  const req = { headers: { authorization: `Bearer ${token}` } };
  let statusCode = 200;
  let body = null;
  let passed = false;

  const res = {
    status(code) {
      statusCode = code;
      return this;
    },
    json(payload) {
      body = payload;
      return this;
    },
  };

  await middleware(req, res, () => {
    passed = true;
  });

  return { passed, statusCode, body, user: req.user };
};

const expectApiError = async (promise, status) => {
  await assert.rejects(promise, (error) => {
    assert.equal(error.status, status);
    return true;
  });
};

test('đăng nhập trả token mang tokenVersion và không lộ mật khẩu', async () => {
  const repository = fakeUserRepository();
  const service = buildService({ repository });

  const result = await service.login({
    username: 'victim',
    password: 'correct-horse',
  });

  assert.ok(result.token);
  assert.equal(result.user.MatKhau, undefined);
  assert.equal(result.user.tokenVersion, undefined);
  assert.equal(result.streak.total_xp, 10);

  const authenticate = buildAuthenticate(repository);
  const outcome = await runMiddleware(authenticate, result.token);
  assert.equal(outcome.passed, true);
  assert.equal(outcome.user.tokenVersion, undefined);
});

test('sai mật khẩu trả 401, tài khoản không hoạt động trả 403', async () => {
  const service = buildService();
  await expectApiError(
    service.login({ username: 'victim', password: 'sai' }),
    401,
  );

  const locked = buildService({
    repository: fakeUserRepository([{ ...VICTIM, TrangThai: 'banned' }]),
  });
  await expectApiError(
    locked.login({ username: 'victim', password: 'correct-horse' }),
    403,
  );
});

test('quên mật khẩu chỉ gửi tới địa chỉ lưu trong database', async () => {
  const mailer = fakeMailer();
  const service = buildService({ mailer });

  const result = await service.forgotPassword({ email: 'victim@example.com' });

  assert.equal(mailer.sent.length, 1);
  assert.equal(mailer.sent[0].to, 'victim@example.com');
  assert.match(mailer.sent[0].resetLink, /^http:\/\/localhost:8080\/#\/reset-password\?token=/);
  assert.match(result.message, /Nếu email tồn tại/);
});

test('email không tồn tại vẫn trả thông báo chung và không gửi thư', async () => {
  const mailer = fakeMailer();
  const service = buildService({ mailer });

  const result = await service.forgotPassword({ email: 'khong-co@example.com' });

  assert.equal(mailer.sent.length, 0);
  assert.match(result.message, /Nếu email tồn tại/);
});

test('email chưa cấu hình trả 503 trước khi tra cứu người dùng', async () => {
  const repository = fakeUserRepository();
  let lookups = 0;
  repository.findByEmail = async () => {
    lookups += 1;
    return null;
  };

  const service = buildService({
    repository,
    mailer: fakeMailer({ configured: false }),
  });

  await expectApiError(service.forgotPassword({ email: 'victim@example.com' }), 503);
  assert.equal(lookups, 0);
});

test('đặt lại mật khẩu tăng version và token cũ không dùng lại được', async () => {
  const repository = fakeUserRepository();
  const mailer = fakeMailer();
  const service = buildService({ repository, mailer });

  await service.forgotPassword({ email: 'victim@example.com' });
  const resetToken = new URL(mailer.sent[0].resetLink.replace('/#/', '/')).searchParams.get('token');

  const first = await service.resetPassword({
    token: resetToken,
    newPassword: 'mat-khau-moi',
  });
  assert.match(first.message, /thành công/);
  assert.equal(repository.store[0].tokenVersion, 1);
  assert.equal(repository.store[0].MatKhau, 'hashed:mat-khau-moi');

  await expectApiError(
    service.resetPassword({ token: resetToken, newPassword: 'mat-khau-khac' }),
    401,
  );
});

test('hai request đồng thời cùng một token reset chỉ một request thành công', async () => {
  const repository = fakeUserRepository();
  const mailer = fakeMailer();
  const service = buildService({ repository, mailer });

  await service.forgotPassword({ email: 'victim@example.com' });
  const resetToken = new URL(mailer.sent[0].resetLink.replace('/#/', '/')).searchParams.get('token');

  const results = await Promise.allSettled([
    service.resetPassword({ token: resetToken, newPassword: 'mat-khau-a' }),
    service.resetPassword({ token: resetToken, newPassword: 'mat-khau-b' }),
  ]);

  const fulfilled = results.filter((entry) => entry.status === 'fulfilled');
  assert.equal(fulfilled.length, 1);
  assert.equal(repository.store[0].tokenVersion, 1);
});

test('token reset sai loại hoặc sai chữ ký đều bị từ chối', async () => {
  const repository = fakeUserRepository();
  const service = buildService({ repository });

  await expectApiError(
    service.resetPassword({ token: 'khong-phai-jwt', newPassword: 'mat-khau-moi' }),
    401,
  );

  const login = await service.login({ username: 'victim', password: 'correct-horse' });
  await expectApiError(
    service.resetPassword({ token: login.token, newPassword: 'mat-khau-moi' }),
    401,
  );
});

test('chuỗi đăng nhập → đổi mật khẩu → token cũ bị từ chối → đăng nhập lại', async () => {
  const repository = fakeUserRepository();
  const service = buildService({ repository });
  const authenticate = buildAuthenticate(repository);

  const session = await service.login({
    username: 'victim',
    password: 'correct-horse',
  });
  assert.equal((await runMiddleware(authenticate, session.token)).passed, true);

  await service.changePassword({
    actor: { _id: VICTIM._id, VaiTro: 'user' },
    targetUserId: VICTIM._id,
    oldPassword: 'correct-horse',
    newPassword: 'mat-khau-moi',
  });

  const revoked = await runMiddleware(authenticate, session.token);
  assert.equal(revoked.passed, false);
  assert.equal(revoked.statusCode, 401);

  const renewed = await service.login({
    username: 'victim',
    password: 'mat-khau-moi',
  });
  assert.equal((await runMiddleware(authenticate, renewed.token)).passed, true);
});

test('token cũ không có tokenVersion chỉ dùng được khi database cũng ở version 0', async () => {
  const repository = fakeUserRepository();
  const authenticate = buildAuthenticate(repository);

  const legacyToken = (await import('jsonwebtoken')).default.sign(
    { id: VICTIM._id, type: 'access' },
    JWT_SECRET,
    { expiresIn: '1h' },
  );

  assert.equal((await runMiddleware(authenticate, legacyToken)).passed, true);

  repository.store[0].tokenVersion = 1;
  const afterChange = await runMiddleware(authenticate, legacyToken);
  assert.equal(afterChange.passed, false);
  assert.equal(afterChange.statusCode, 401);
});

test('đổi mật khẩu người khác bị chặn, admin đổi hộ không đụng phiên của admin', async () => {
  const admin = {
    ...VICTIM,
    _id: 'user-admin',
    TenDangNhap: 'admin',
    Email: 'admin@example.com',
    VaiTro: 'admin',
    tokenVersion: 0,
  };
  const repository = fakeUserRepository([VICTIM, admin]);
  const service = buildService({ repository });

  await expectApiError(
    service.changePassword({
      actor: { _id: 'user-khac', VaiTro: 'user' },
      targetUserId: VICTIM._id,
      oldPassword: 'correct-horse',
      newPassword: 'mat-khau-moi',
    }),
    403,
  );

  await service.changePassword({
    actor: { _id: admin._id, VaiTro: 'admin' },
    targetUserId: VICTIM._id,
    newPassword: 'admin-dat-lai',
  });

  assert.equal(repository.store[0].tokenVersion, 1);
  assert.equal(repository.store[1].tokenVersion, 0);
});

test('tự đổi mật khẩu sai mật khẩu cũ trả 401 và không đổi version', async () => {
  const repository = fakeUserRepository();
  const service = buildService({ repository });

  await expectApiError(
    service.changePassword({
      actor: { _id: VICTIM._id, VaiTro: 'user' },
      targetUserId: VICTIM._id,
      oldPassword: 'sai',
      newPassword: 'mat-khau-moi',
    }),
    401,
  );

  assert.equal(repository.store[0].tokenVersion, 0);
});

test('token reset hết hạn bị từ chối', async () => {
  const repository = fakeUserRepository();
  const service = buildService({ repository });

  const jwt = (await import('jsonwebtoken')).default;
  const expired = jwt.sign(
    { id: VICTIM._id, type: 'password-reset', tokenVersion: 0 },
    JWT_SECRET,
    { expiresIn: -10 },
  );

  await expectApiError(
    service.resetPassword({ token: expired, newPassword: 'mat-khau-moi' }),
    401,
  );
  assert.equal(repository.store[0].tokenVersion, 0);
});

test('đổi mật khẩu hai lần liên tiếp thu hồi cả token vừa phát', async () => {
  const repository = fakeUserRepository();
  const service = buildService({ repository });
  const authenticate = buildAuthenticate(repository);

  await service.changePassword({
    actor: { _id: VICTIM._id, VaiTro: 'user' },
    targetUserId: VICTIM._id,
    oldPassword: 'correct-horse',
    newPassword: 'mat-khau-1',
  });

  const second = await service.login({
    username: 'victim',
    password: 'mat-khau-1',
  });
  assert.equal((await runMiddleware(authenticate, second.token)).passed, true);

  await service.changePassword({
    actor: { _id: VICTIM._id, VaiTro: 'user' },
    targetUserId: VICTIM._id,
    oldPassword: 'mat-khau-1',
    newPassword: 'mat-khau-2',
  });

  assert.equal(repository.store[0].tokenVersion, 2);
  const revoked = await runMiddleware(authenticate, second.token);
  assert.equal(revoked.passed, false);
  assert.equal(revoked.statusCode, 401);
});

test('link đặt lại mật khẩu luôn có hash route và chuẩn hóa dấu gạch chéo', () => {
  assert.equal(
    buildResetLink('http://localhost:8080', 'abc'),
    'http://localhost:8080/#/reset-password?token=abc',
  );
  assert.equal(
    buildResetLink('http://localhost:8080/', 'abc'),
    'http://localhost:8080/#/reset-password?token=abc',
  );
  assert.equal(
    buildResetLink('https://host/app///', 'a b+c'),
    'https://host/app/#/reset-password?token=a+b%2Bc',
  );
});
