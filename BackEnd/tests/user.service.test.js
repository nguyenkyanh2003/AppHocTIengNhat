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

/** Kho ảnh giả: ghi lại thao tác, `replace` gọi `apply` với một đường dẫn mới như kho thật. */
const fakeImages = () => {
  const calls = [];
  return {
    calls,
    async replace({ folder, prefix, previous, apply }) {
      calls.push(['replace', { folder, prefix, previous }]);
      return apply(`/uploads/${folder}/${prefix}-moi.jpg`);
    },
    async remove(publicPath) {
      calls.push(['remove', publicPath]);
    },
  };
};

const build = (results) => {
  const fake = fakeRepository(results);
  const images = fakeImages();
  const service = createUserService({
    repository: fake.repository,
    passwordHasher: { hash: async (plain) => `hashed:${plain}` },
    now: () => NOW,
    images,
  });
  return { ...fake, images, service };
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

const IMAGE = Buffer.from([0xff, 0xd8, 0xff]);

test('ảnh đại diện: lưu ảnh mới, ghi vào hồ sơ, thay ảnh cũ', async () => {
  const { calls, images, service } = build({
    findPublicById: { ...USER, AnhDaiDien: '/uploads/avatars/cu.png' },
    updateById: ({ set }) => ({ ...USER, ...set }),
  });

  const user = await service.setAvatar({ actor: asUser, userId: ME, image: IMAGE });

  assert.equal(user.AnhDaiDien, '/uploads/avatars/user-moi.jpg');
  assert.deepEqual(calls.at(-1), ['updateById', { id: ME, set: { AnhDaiDien: '/uploads/avatars/user-moi.jpg' } }]);
  assert.deepEqual(images.calls, [['replace', { folder: 'avatars', prefix: 'user', previous: '/uploads/avatars/cu.png' }]]);
});

test('ảnh đại diện của người khác: từ chối trước khi đụng tới tệp', async () => {
  const { calls, images, service } = build();

  await assert.rejects(service.setAvatar({ actor: asAdmin, userId: ME, image: IMAGE }), rejectsWith(403));
  assert.deepEqual(calls, []);
  assert.deepEqual(images.calls, []);
});

test('ảnh đại diện: người dùng không còn thì 404 và kho ảnh dọn được tệp vừa lưu', async () => {
  await assert.rejects(
    build({ findPublicById: null }).service.setAvatar({ actor: asUser, userId: ME, image: IMAGE }),
    rejectsWith(404),
  );
  // Bị xoá giữa lúc tải lên: apply ném 404 để kho ảnh xoá tệp vừa ghi.
  await assert.rejects(
    build({ findPublicById: USER, updateById: null }).service.setAvatar({ actor: asUser, userId: ME, image: IMAGE }),
    rejectsWith(404),
  );
});

test('quản trị: lọc người dùng theo từ khoá nguyên văn, vai trò, trạng thái, trình độ', async () => {
  const { calls, service } = build({ findPage: [USER], count: 1, streakSummaries: new Map() });

  await service.adminList({ page: 1, limit: 20, search: 'an (N5)', role: 'user', status: 'active', trinhDo: 'N5' });

  const pattern = { $regex: 'an \\(N5\\)', $options: 'i' };
  assert.deepEqual(calls[0][1].filter, {
    VaiTro: 'user',
    TrangThai: 'active',
    TrinhDo: 'N5',
    $or: [{ HoTen: pattern }, { Email: pattern }, { TenDangNhap: pattern }],
  });
});

test('quản trị: XP và chuỗi ngày lấy từ streak thật, không từ trường cũ của User', async () => {
  const legacy = { ...USER, DiemTichLuy: 0, StreakHienTai: 0, StreakDaiNhat: 0, TongThoiGianHoc: 0 };
  const { calls, service } = build({
    findPage: [legacy, { ...legacy, _id: OTHER }],
    count: 2,
    streakSummaries: new Map([[ME, { total_xp: 120, current_streak: 3 }]]),
  });

  const { items } = await service.adminList({ page: 1, limit: 20 });

  assert.deepEqual(calls.find(([name]) => name === 'streakSummaries'), ['streakSummaries', { userIds: [ME, OTHER], now: NOW }]);
  assert.deepEqual(
    items.map(({ _id, total_xp: xp, current_streak: streak }) => [_id, xp, streak]),
    [[ME, 120, 3], [OTHER, 0, 0]],
  );
  for (const field of ['DiemTichLuy', 'StreakHienTai', 'StreakDaiNhat', 'TongThoiGianHoc']) {
    assert.ok(!(field in items[0]), `${field} là trường cũ không ai ghi, không được trả ra`);
  }
});

test('hồ sơ không trả các trường XP/chuỗi ngày cũ (luôn 0, gây hiểu nhầm)', async () => {
  const { service } = build({ findPublicById: { ...USER, DiemTichLuy: 0, StreakHienTai: 0, TongThoiGianHoc: 0 } });

  const profile = await service.profile({ actor: asUser, userId: ME });

  assert.ok(!('DiemTichLuy' in profile) && !('StreakHienTai' in profile) && !('TongThoiGianHoc' in profile));
});

test('quản trị: sửa người dùng đổi tên trường sang model; không có 404', async () => {
  const { calls, service } = build({ emailTaken: false, updateById: (args) => ({ ...USER, ...args.set }) });

  await service.adminUpdate({ userId: ME, changes: { vaiTro: 'admin', trangThai: 'banned' } });
  assert.deepEqual(calls, [['updateById', { id: ME, set: { VaiTro: 'admin', TrangThai: 'banned' } }]]);

  await assert.rejects(build({ updateById: null }).service.adminUpdate({ userId: ME, changes: { hoTen: 'x' } }), rejectsWith(404));
});

test('quản trị: không tự xoá tài khoản của mình; người không có là 404', async () => {
  const { calls, images, service } = build({ deleteById: { ...USER, AnhDaiDien: '/uploads/avatars/cu.png' } });

  await service.adminRemove({ actor: asAdmin, userId: ME });
  assert.deepEqual(calls, [['deleteById', ME]]);
  assert.deepEqual(images.calls, [['remove', '/uploads/avatars/cu.png']], 'xoá tài khoản thì xoá luôn ảnh đại diện');

  await assert.rejects(service.adminRemove({ actor: asAdmin, userId: OTHER }), rejectsWith(400));
  await assert.rejects(build({ deleteById: null }).service.adminRemove({ actor: asAdmin, userId: ME }), rejectsWith(404));
});
