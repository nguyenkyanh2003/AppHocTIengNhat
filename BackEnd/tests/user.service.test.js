import assert from 'node:assert/strict';
import test from 'node:test';

import { createUserService } from '../src/modules/users/user.service.js';
import { ApiError } from '../src/shared/http/api-error.js';

const NOW = new Date('2026-11-14T03:00:00.000Z');
const ME = '507f1f77bcf86cd799439011';
const OTHER = '507f1f77bcf86cd799439012';
const USER = { _id: ME, TenDangNhap: 'an', HoTen: 'Nguyễn An', Email: 'an@example.com', VaiTro: 'user' };

const fakeRepository = (results = {}) => {
  const calls = [];
  const repository = new Proxy({}, {
    get: (_target, name) => async (args) => {
      calls.push([name, args]);
      const result = results[name];
      return typeof result === 'function' ? result(args) : result;
    },
  });
  return { calls, repository };
};

const build = (results) => {
  const fake = fakeRepository(results);
  const service = createUserService({
    repository: fake.repository,
    passwordHasher: { hash: async (plain) => `hashed:${plain}` },
    now: () => NOW,
  });
  return { ...fake, service };
};

const asUser = { _id: ME, VaiTro: 'user' };
const asAdmin = { _id: OTHER, VaiTro: 'admin' };

const rejectsWith = (status) => (error) => {
  assert.ok(error instanceof ApiError, error);
  assert.equal(error.status, status);
  return true;
};

test('đăng ký: băm mật khẩu, mặc định N5 và vai trò người học; không trả mật khẩu', async () => {
  const { calls, service } = build({
    usernameTaken: false,
    emailTaken: false,
    create: (doc) => ({ _id: ME, ...doc, __v: 0 }),
  });

  const user = await service.register({ username: 'an', hoTen: 'Nguyễn An', email: 'an@example.com', password: '12345678' });

  assert.deepEqual(calls.at(-1), ['create', {
    TenDangNhap: 'an',
    HoTen: 'Nguyễn An',
    Email: 'an@example.com',
    MatKhau: 'hashed:12345678',
    TrinhDo: 'N5',
    VaiTro: 'user',
    NgayTao: NOW,
    LanDangNhapCuoi: NOW,
  }]);
  assert.equal('MatKhau' in user, false);
  assert.equal('__v' in user, false);
});

test('đăng ký: tên đăng nhập hay email đã dùng là 409', async () => {
  const input = { username: 'an', hoTen: 'An', email: 'an@example.com', password: '12345678' };
  await assert.rejects(build({ usernameTaken: true }).service.register(input), rejectsWith(409));
  await assert.rejects(build({ usernameTaken: false, emailTaken: true }).service.register(input), rejectsWith(409));
});

test('hồ sơ: tự xem hoặc quản trị viên xem; người khác 403; không có 404', async () => {
  const { service } = build({ findPublicById: USER });

  assert.equal((await service.profile({ actor: asUser, userId: ME })).HoTen, 'Nguyễn An');
  assert.equal((await service.profile({ actor: asAdmin, userId: ME })).HoTen, 'Nguyễn An');
  await assert.rejects(service.profile({ actor: asUser, userId: OTHER }), rejectsWith(403));
  await assert.rejects(build({ findPublicById: null }).service.profile({ actor: asUser, userId: ME }), rejectsWith(404));
});

test('sửa hồ sơ: đổi tên trường sang model; email người khác đang dùng là 409', async () => {
  const { calls, service } = build({ emailTaken: false, updateById: ({ set }) => ({ ...USER, ...set }) });

  const user = await service.updateProfile({
    actor: asUser,
    userId: ME,
    changes: { hoTen: 'An Nguyễn', email: 'moi@example.com', trinhDo: 'N4', gioiTinh: 'Nữ' },
  });

  assert.equal(user.HoTen, 'An Nguyễn');
  assert.deepEqual(calls, [
    ['emailTaken', { email: 'moi@example.com', excludeId: ME }],
    ['updateById', { id: ME, set: { HoTen: 'An Nguyễn', Email: 'moi@example.com', TrinhDo: 'N4', GioiTinh: 'Nữ' } }],
  ]);

  await assert.rejects(build().service.updateProfile({ actor: asUser, userId: OTHER, changes: { hoTen: 'x' } }), rejectsWith(403));
  await assert.rejects(
    build({ emailTaken: true }).service.updateProfile({ actor: asUser, userId: ME, changes: { email: 'trung@example.com' } }),
    rejectsWith(409),
  );
});

test('ảnh đại diện chỉ đổi được của chính mình', async () => {
  const { calls, service } = build({ updateById: ({ set }) => ({ ...USER, ...set }) });

  assert.equal((await service.setAvatar({ actor: asUser, userId: ME, avatar: '/uploads/avatars/a.png' })).AnhDaiDien, '/uploads/avatars/a.png');
  assert.deepEqual(calls, [['updateById', { id: ME, set: { AnhDaiDien: '/uploads/avatars/a.png' } }]]);
  await assert.rejects(service.setAvatar({ actor: asAdmin, userId: ME, avatar: 'x' }), rejectsWith(403));
});

test('quản trị: lọc người dùng theo từ khoá nguyên văn, vai trò, trạng thái, trình độ', async () => {
  const { calls, service } = build({ findPage: [USER], count: 1 });

  await service.adminList({ page: 1, limit: 20, search: 'an (N5)', role: 'user', status: 'active', trinhDo: 'N5' });

  const pattern = { $regex: 'an \\(N5\\)', $options: 'i' };
  assert.deepEqual(calls[0][1].filter, {
    VaiTro: 'user',
    TrangThai: 'active',
    TrinhDo: 'N5',
    $or: [{ HoTen: pattern }, { Email: pattern }, { TenDangNhap: pattern }],
  });
});

test('quản trị: sửa người dùng đổi tên trường sang model; không có 404', async () => {
  const { calls, service } = build({ emailTaken: false, updateById: (args) => ({ ...USER, ...args.set }) });

  await service.adminUpdate({ userId: ME, changes: { vaiTro: 'admin', trangThai: 'banned' } });
  assert.deepEqual(calls, [['updateById', { id: ME, set: { VaiTro: 'admin', TrangThai: 'banned' } }]]);

  await assert.rejects(build({ updateById: null }).service.adminUpdate({ userId: ME, changes: { hoTen: 'x' } }), rejectsWith(404));
});

test('quản trị: không tự xoá tài khoản của mình; người không có là 404', async () => {
  const { calls, service } = build({ deleteById: USER });

  await service.adminRemove({ actor: asAdmin, userId: ME });
  assert.deepEqual(calls, [['deleteById', ME]]);

  await assert.rejects(service.adminRemove({ actor: asAdmin, userId: OTHER }), rejectsWith(400));
  await assert.rejects(build({ deleteById: null }).service.adminRemove({ actor: asAdmin, userId: ME }), rejectsWith(404));
});
