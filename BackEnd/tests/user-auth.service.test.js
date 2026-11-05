import assert from 'node:assert/strict';
import test from 'node:test';

import {
  createAuthenticateUser,
  SESSION_EXPIRED,
} from '../src/middleware/auth.middleware.js';
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

/**
 * Kho phiên giả giữ đúng điều kiện ghi của bản thật: chỉ thu hồi phiên chưa
 * thu hồi; đổi refresh token chỉ khớp khi token hiện tại vẫn là token vừa đọc.
 */
const fakeSessionRepository = () => {
  const store = [];
  let sequence = 0;
  const find = (predicate) => store.find(predicate) ?? null;
  const live = (session) => session.revoked_at === null;
  const retired = (session, hash) => session.previous_token_hash === hash || session.superseded_token_hash === hash;
  const revokeWhere = (predicate, { reason, at }) => {
    for (const session of store.filter((entry) => live(entry) && predicate(entry))) {
      Object.assign(session, { revoked_at: at, revoked_reason: reason });
    }
  };

  return {
    store,
    create: async ({ userId, tokenHash, expiresAt }) => {
      sequence += 1;
      const session = {
        _id: `session-${sequence}`, user: userId, refresh_token_hash: tokenHash, previous_token_hash: null,
        previous_retired_at: null, superseded_token_hash: null, rotation: 0, expires_at: expiresAt, revoked_at: null, revoked_reason: null,
      };
      store.push(session);
      return clone(session);
    },
    findById: async (id) => clone(find((session) => session._id === String(id))),
    findByTokenHash: async (hash) => clone(find((session) => session.refresh_token_hash === hash)),
    findByRetiredHash: async (hash) => clone(find((session) => retired(session, hash))),
    rotate: async ({ id, fromHash, toHash, previousHash, previousRetiredAt, supersededHash, expiresAt, at }) => {
      const session = find((entry) => entry._id === String(id) && entry.refresh_token_hash === fromHash && live(entry));
      if (!session) return null;
      Object.assign(session, {
        refresh_token_hash: toHash,
        previous_token_hash: previousHash,
        previous_retired_at: previousRetiredAt,
        superseded_token_hash: supersededHash,
        rotation: session.rotation + 1,
        expires_at: expiresAt,
        last_used_at: at,
      });
      return clone(session);
    },
    revoke: async ({ id, ...change }) => revokeWhere((session) => session._id === String(id), change),
    revokeByTokenHash: async ({ hash, ...change }) =>
      revokeWhere((session) => session.refresh_token_hash === hash || retired(session, hash), change),
    revokeAllForUser: async ({ userId, ...change }) => revokeWhere((session) => String(session.user) === String(userId), change),
  };
};

/** Repository giả giữ nguyên ngữ nghĩa version của bản thật, không cần MongoDB. */
const fakeUserRepository = (seed = [VICTIM]) => {
  const store = seed.map((user) => ({ ...user }));

  const find = (predicate) => store.find(predicate) ?? null;

  return {
    store,
    // Phiên đăng nhập đi cùng repository để service và middleware của một test
    // dùng chung một kho phiên.
    sessions: fakeSessionRepository(),
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

    // Chỉ có đường đọc streak. Không khai báo hàm ghi nào: login mà lỡ gọi
    // một writer streak thì test nổ ngay với "is not a function".
    streakReads: 0,
    async readStreakSummary() {
      this.streakReads += 1;
      return { current: 1, longest: 1, total_xp: 10, is_new_day: false, streak_broken: false };
    },
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

const NOW = new Date('2026-01-01T00:00:00.000Z');

const buildService = ({ repository, mailer, hasher = fakeHasher, now = () => NOW } = {}) => {
  const users = repository ?? fakeUserRepository();
  return createUserAuthService({
    userRepository: users,
    sessionRepository: users.sessions,
    mailer: mailer ?? fakeMailer(),
    passwordHasher: hasher,
    jwtSecret: JWT_SECRET,
    frontendUrl: 'http://localhost:8080',
    now,
  });
};

/** Middleware thật, chỉ thay nguồn đọc user và phiên bằng repository giả. */
const buildAuthenticate = (repository, now = () => NOW) =>
  createAuthenticateUser({
    findUserById: (id) => repository.findById(id),
    findSession: (id) => repository.sessions.findById(id),
    jwtSecret: JWT_SECRET,
    bypassAuth: false,
    now,
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
  // Đăng nhập chỉ đọc tóm tắt streak, không nối chuỗi và không cộng XP.
  assert.equal(repository.streakReads, 1);
  assert.equal(result.streak.is_new_day, false);

  const authenticate = buildAuthenticate(repository);
  const outcome = await runMiddleware(authenticate, result.token);
  assert.equal(outcome.passed, true);
  assert.equal(outcome.user.tokenVersion, undefined);
});

test('sai tên đăng nhập hay sai mật khẩu đều trả cùng một thông báo', async () => {
  const service = buildService();
  const failures = [];
  for (const credentials of [
    { username: 'khong-ton-tai', password: 'correct-horse' },
    { username: 'victim', password: 'sai' },
  ]) {
    await assert.rejects(service.login(credentials), (error) => {
      failures.push([error.status, error.code, error.message]);
      return true;
    });
  }

  assert.deepEqual(failures, [
    [401, 'INVALID_CREDENTIALS', 'Tên đăng nhập hoặc mật khẩu không đúng.'],
    [401, 'INVALID_CREDENTIALS', 'Tên đăng nhập hoặc mật khẩu không đúng.'],
  ]);
});

test('tên không tồn tại vẫn chạy so mật khẩu, để thời gian phản hồi không lộ tài khoản', async () => {
  const compared = [];
  const hasher = { ...fakeHasher, compare: async (plain, hashed) => { compared.push(hashed); return false; } };

  await expectApiError(buildService({ hasher }).login({ username: 'khong-ton-tai', password: 'x' }), 401);

  assert.equal(compared.length, 1);
  assert.match(compared[0], /^\$2[aby]\$10\$/, 'so với một bcrypt hash giả, cùng chi phí với hash thật');
});

test('tài khoản bị khoá: chỉ người có đúng mật khẩu mới biết là bị khoá', async () => {
  const locked = buildService({
    repository: fakeUserRepository([{ ...VICTIM, TrangThai: 'banned' }]),
  });

  await expectApiError(locked.login({ username: 'victim', password: 'sai' }), 401);
  await expectApiError(locked.login({ username: 'victim', password: 'correct-horse' }), 403);
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
  assert.equal(revoked.body.code, SESSION_EXPIRED);

  const renewed = await service.login({
    username: 'victim',
    password: 'mat-khau-moi',
  });
  assert.equal((await runMiddleware(authenticate, renewed.token)).passed, true);
});

test('token hết hạn, sai chữ ký hay sai loại đều trả 401 kèm mã SESSION_EXPIRED', async () => {
  const jwt = (await import('jsonwebtoken')).default;
  const authenticate = buildAuthenticate(fakeUserRepository());
  const tokens = [
    jwt.sign({ id: VICTIM._id, type: 'access' }, JWT_SECRET, { expiresIn: -10 }),
    jwt.sign({ id: VICTIM._id, type: 'access' }, 'another-secret-at-least-32-characters'),
    jwt.sign({ id: VICTIM._id, type: 'refresh' }, JWT_SECRET, { expiresIn: '1h' }),
  ];

  for (const token of tokens) {
    const result = await runMiddleware(authenticate, token);
    assert.equal(result.passed, false);
    assert.equal(result.statusCode, 401);
    assert.equal(result.body.code, SESSION_EXPIRED);
  }
});

test('token không gắn phiên (phát trước khi có refresh token) bị từ chối — đăng nhập lại một lần', async () => {
  // Token 24 giờ kiểu cũ không thu hồi riêng được khi đăng xuất, nên không
  // được dùng tiếp; client nhận SESSION_EXPIRED và về màn đăng nhập.
  const authenticate = buildAuthenticate(fakeUserRepository());
  const legacyToken = (await import('jsonwebtoken')).default.sign(
    { id: VICTIM._id, type: 'access', tokenVersion: 0 },
    JWT_SECRET,
    { expiresIn: '1h' },
  );

  const result = await runMiddleware(authenticate, legacyToken);
  assert.equal(result.passed, false);
  assert.equal(result.statusCode, 401);
  assert.equal(result.body.code, SESSION_EXPIRED);
});

test('đăng nhập mở một phiên: access token 15 phút mang mã phiên, refresh token chỉ lưu bản băm', async () => {
  const repository = fakeUserRepository();
  const result = await buildService({ repository }).login({ username: 'victim', password: 'correct-horse' });
  const jwt = (await import('jsonwebtoken')).default;
  const payload = jwt.decode(result.token);

  assert.equal(typeof result.refreshToken, 'string');
  assert.ok(result.refreshToken.length >= 40);
  const [session] = repository.sessions.store;
  assert.equal(payload.sid, session._id);
  assert.equal(payload.exp - payload.iat, 15 * 60);
  assert.notEqual(session.refresh_token_hash, result.refreshToken);
  assert.equal(session.refresh_token_hash.length, 64, 'sha256 hex');
  assert.equal(session.expires_at.toISOString(), '2026-01-31T00:00:00.000Z');
});

test('làm mới phiên: cấp cặp token mới, token cũ hết dùng được', async () => {
  const repository = fakeUserRepository();
  const service = buildService({ repository });
  const authenticate = buildAuthenticate(repository);
  const first = await service.login({ username: 'victim', password: 'correct-horse' });

  const renewed = await service.refresh({ refreshToken: first.refreshToken });

  assert.notEqual(renewed.refreshToken, first.refreshToken);
  assert.equal((await runMiddleware(authenticate, renewed.token)).passed, true);
  assert.equal(repository.sessions.store.length, 1, 'vẫn là phiên cũ, không mở phiên mới');
  // Flutter so `sid` để phân biệt "tab khác vừa làm mới" với "tab khác đã đổi tài khoản".
  const jwt = (await import('jsonwebtoken')).default;
  assert.equal(jwt.decode(renewed.token).sid, jwt.decode(first.token).sid);
  await expectApiError(service.refresh({ refreshToken: 'khong-phai-token-nao' }), 401);
});

/** Service có đồng hồ chỉnh được, tính bằng giây sau [NOW]. */
const withClock = (repository) => {
  let seconds = 0;
  const service = buildService({ repository, now: () => new Date(NOW.getTime() + seconds * 1000) });
  return { service, at: (value) => { seconds = value; } };
};

test('mỗi lần xoay tăng số đời trong access token, kể cả lần thử lại trong ân hạn', async () => {
  const repository = fakeUserRepository();
  const { service } = withClock(repository);
  const jwt = (await import('jsonwebtoken')).default;

  const first = await service.login({ username: 'victim', password: 'correct-horse' });
  const second = await service.refresh({ refreshToken: first.refreshToken });
  const retried = await service.refresh({ refreshToken: first.refreshToken });
  const third = await service.refresh({ refreshToken: retried.refreshToken });

  // Các tab web dùng chung kho lưu so số này để phản hồi về muộn không ghi đè cặp mới hơn.
  assert.deepEqual([first, second, retried, third].map(({ token }) => jwt.decode(token).rotation), [0, 1, 2, 3]);
});

test('dùng lại refresh token đã bị thay sau khoảng ân hạn: thu hồi cả phiên', async () => {
  const repository = fakeUserRepository();
  const { service, at } = withClock(repository);
  const authenticate = buildAuthenticate(repository);
  const first = await service.login({ username: 'victim', password: 'correct-horse' });
  const renewed = await service.refresh({ refreshToken: first.refreshToken });

  at(61);
  await assert.rejects(service.refresh({ refreshToken: first.refreshToken }), (error) => {
    assert.deepEqual([error.status, error.code], [401, 'SESSION_EXPIRED']);
    return true;
  });

  assert.equal(repository.sessions.store[0].revoked_reason, 'reuse_detected');
  await expectApiError(service.refresh({ refreshToken: renewed.refreshToken }), 401);
  assert.equal((await runMiddleware(authenticate, renewed.token)).passed, false, 'access token của phiên cũng mất hiệu lực');
});

test('phản hồi làm mới bị mất: thử lại bằng token cũ trong 60 giây vẫn nhận cặp mới, phiên không bị thu hồi', async () => {
  const repository = fakeUserRepository();
  const { service, at } = withClock(repository);
  const authenticate = buildAuthenticate(repository);
  const first = await service.login({ username: 'victim', password: 'correct-horse' });

  await service.refresh({ refreshToken: first.refreshToken }); // Phản hồi này không về tới máy.
  at(30);
  const retried = await service.refresh({ refreshToken: first.refreshToken });
  at(40);
  const again = await service.refresh({ refreshToken: first.refreshToken }); // Lần thử lại cũng mất phản hồi.

  assert.equal(repository.sessions.store[0].revoked_at, null);
  assert.notEqual(retried.refreshToken, again.refreshToken);
  assert.equal((await runMiddleware(authenticate, again.token)).passed, true);
  assert.ok(await service.refresh({ refreshToken: again.refreshToken }), 'token cuối cùng dùng tiếp bình thường');
});

test('thử lại không kéo dài khoảng ân hạn: 60 giây tính từ lần thay đầu tiên', async () => {
  const repository = fakeUserRepository();
  const { service, at } = withClock(repository);
  const first = await service.login({ username: 'victim', password: 'correct-horse' });
  await service.refresh({ refreshToken: first.refreshToken });

  at(50);
  await service.refresh({ refreshToken: first.refreshToken });
  at(61);
  await expectApiError(service.refresh({ refreshToken: first.refreshToken }), 401);

  assert.equal(repository.sessions.store[0].revoked_reason, 'reuse_detected');
});

test('token bị thay trong lúc ân hạn lại xuất hiện: hai bên cùng giữ phiên, thu hồi cả phiên', async () => {
  // Kẻ cắp dùng token cũ trong khoảng ân hạn sẽ đẩy người dùng thật ra ngoài;
  // token của người dùng thật quay lại chính là dấu hiệu để đóng phiên của cả hai.
  const repository = fakeUserRepository();
  const { service } = withClock(repository);
  const first = await service.login({ username: 'victim', password: 'correct-horse' });
  const genuine = await service.refresh({ refreshToken: first.refreshToken });
  const stolen = await service.refresh({ refreshToken: first.refreshToken });

  await expectApiError(service.refresh({ refreshToken: genuine.refreshToken }), 401);

  assert.equal(repository.sessions.store[0].revoked_reason, 'reuse_detected');
  await expectApiError(service.refresh({ refreshToken: stolen.refreshToken }), 401);
});

test('hai request làm mới cùng lúc: bên thua lệnh ghi thử lại trong ân hạn, phiên không bị thu hồi', async () => {
  const repository = fakeUserRepository();
  const { service } = withClock(repository);
  const first = await service.login({ username: 'victim', password: 'correct-horse' });
  const sessions = repository.sessions;
  const rotate = sessions.rotate;
  let raced = false;
  // Đúng lúc service này định ghi, một request khác đã kịp đổi token trước.
  sessions.rotate = async (args) => {
    if (raced) return rotate(args);
    raced = true;
    await rotate({ ...args, toHash: 'hash-cua-request-khac', previousHash: args.fromHash, previousRetiredAt: NOW, supersededHash: null });
    return null;
  };

  const result = await service.refresh({ refreshToken: first.refreshToken });

  assert.ok(result.refreshToken);
  assert.equal(sessions.store[0].revoked_at, null);
});

test('thua lệnh ghi liên tục: báo xung đột tạm thời, không thu hồi phiên', async () => {
  const repository = fakeUserRepository();
  const { service } = withClock(repository);
  const first = await service.login({ username: 'victim', password: 'correct-horse' });
  repository.sessions.rotate = async () => null;

  await assert.rejects(service.refresh({ refreshToken: first.refreshToken }), (error) => {
    assert.deepEqual([error.status, error.code], [409, 'REFRESH_CONFLICT']);
    return true;
  });
  assert.equal(repository.sessions.store[0].revoked_at, null);
});

test('đăng xuất bằng refresh token vừa bị thay (phản hồi làm mới bị mất) vẫn đóng được phiên', async () => {
  const repository = fakeUserRepository();
  const { service } = withClock(repository);
  const first = await service.login({ username: 'victim', password: 'correct-horse' });
  await service.refresh({ refreshToken: first.refreshToken });

  await service.logout({ refreshToken: first.refreshToken });

  assert.equal(repository.sessions.store[0].revoked_reason, 'logout');
});

test('phiên hết hạn hay tài khoản bị khoá thì không làm mới được', async () => {
  const repository = fakeUserRepository();
  const login = await buildService({ repository }).login({ username: 'victim', password: 'correct-horse' });

  const later = buildService({ repository, now: () => new Date('2026-02-01T00:00:00.000Z') });
  await expectApiError(later.refresh({ refreshToken: login.refreshToken }), 401);

  const other = fakeUserRepository();
  const session = await buildService({ repository: other }).login({ username: 'victim', password: 'correct-horse' });
  other.store[0].TrangThai = 'banned';
  await expectApiError(buildService({ repository: other }).refresh({ refreshToken: session.refreshToken }), 401);
  assert.equal(other.sessions.store[0].revoked_reason, 'account_inactive');
});

test('đăng xuất thu hồi đúng phiên đó: access token bị từ chối ngay, phiên khác giữ nguyên', async () => {
  const repository = fakeUserRepository();
  const service = buildService({ repository });
  const authenticate = buildAuthenticate(repository);
  const phone = await service.login({ username: 'victim', password: 'correct-horse' });
  const laptop = await service.login({ username: 'victim', password: 'correct-horse' });

  await service.logout({ refreshToken: phone.refreshToken, accessToken: phone.token });

  const rejected = await runMiddleware(authenticate, phone.token);
  assert.deepEqual([rejected.passed, rejected.statusCode, rejected.body.code], [false, 401, SESSION_EXPIRED]);
  await expectApiError(service.refresh({ refreshToken: phone.refreshToken }), 401);
  assert.equal((await runMiddleware(authenticate, laptop.token)).passed, true);
  assert.equal(repository.sessions.store[0].revoked_reason, 'logout');
});

test('đăng xuất luôn thành công: token lạ, token đã thu hồi hay access token đã hết hạn', async () => {
  const repository = fakeUserRepository();
  const service = buildService({ repository });
  const login = await service.login({ username: 'victim', password: 'correct-horse' });
  const jwt = (await import('jsonwebtoken')).default;
  const expired = jwt.sign({ id: VICTIM._id, type: 'access', sid: repository.sessions.store[0]._id }, JWT_SECRET, { expiresIn: -10 });

  assert.equal((await service.logout({ refreshToken: 'la' })).message, 'Đăng xuất thành công');
  await service.logout({ accessToken: expired });
  assert.equal(repository.sessions.store[0].revoked_reason, 'logout', 'token hết hạn nhưng đúng chữ ký vẫn đóng được phiên');
  await service.logout({ refreshToken: login.refreshToken });
  await service.logout({});
});

test('đổi hay đặt lại mật khẩu thu hồi mọi phiên của tài khoản', async () => {
  const repository = fakeUserRepository();
  const service = buildService({ repository });
  await service.login({ username: 'victim', password: 'correct-horse' });
  await service.login({ username: 'victim', password: 'correct-horse' });

  await service.changePassword({
    actor: { _id: VICTIM._id, VaiTro: 'user' },
    targetUserId: VICTIM._id,
    oldPassword: 'correct-horse',
    newPassword: 'mat-khau-moi',
  });

  assert.deepEqual(repository.sessions.store.map((session) => session.revoked_reason), ['password_changed', 'password_changed']);
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
