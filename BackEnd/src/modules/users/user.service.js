import bcrypt from 'bcrypt';

import { ApiError } from '../../shared/http/api-error.js';
import { toSkip } from '../../shared/http/pagination.js';
import { withoutUndefined } from '../../shared/utils/object.js';
import { escapeRegExp } from '../../shared/utils/regexp.js';
import { getVietnamTime } from '../../shared/utils/timezone.js';
import { userRepository } from './user.repository.js';

const BCRYPT_ROUNDS = 10;

/** Tên trường client gửi -> field tiếng Việt của model `User`. */
const PROFILE_FIELDS = Object.freeze({
  hoTen: 'HoTen',
  email: 'Email',
  trinhDo: 'TrinhDo',
  soDienThoai: 'SoDienThoai',
  diaChi: 'DiaChi',
  gioiTinh: 'GioiTinh',
  ngaySinh: 'NgaySinh',
  vaiTro: 'VaiTro',
  trangThai: 'TrangThai',
});

const toModelFields = (changes) =>
  Object.fromEntries(Object.entries(changes).map(([field, value]) => [PROFILE_FIELDS[field], value]));

/** Bỏ mật khẩu, version phiên và khoá nội bộ của Mongoose. */
const publicUser = ({ MatKhau: _password, tokenVersion: _version, __v: _v, ...user }) => user;

const userNotFound = () => ApiError.notFound('Người dùng không tồn tại.');
const emailTaken = () => ApiError.conflict('Email đã được sử dụng.', { code: 'DUPLICATE_EMAIL' });

const isAdmin = (actor) => actor?.VaiTro === 'admin';
const isSelf = (actor, userId) => String(actor?._id) === String(userId);

/**
 * Tài khoản và hồ sơ người dùng (ngoài các luồng xác thực ở
 * `user-auth.service.js`): đăng ký, xem/sửa hồ sơ, ảnh đại diện và phần quản trị.
 */
export const createUserService = ({
  repository = userRepository,
  passwordHasher = { hash: (plain) => bcrypt.hash(plain, BCRYPT_ROUNDS) },
  now = getVietnamTime,
} = {}) => {
  const found = (user) => {
    if (!user) throw userNotFound();
    return publicUser(user);
  };

  const requireFreeEmail = async (email, excludeId) => {
    if (email && (await repository.emailTaken({ email, excludeId }))) throw emailTaken();
  };

  /** Người dùng tự xem/sửa hồ sơ của mình; quản trị viên xem/sửa được mọi hồ sơ. */
  const requireSelfOrAdmin = (actor, userId, action) => {
    if (!isSelf(actor, userId) && !isAdmin(actor)) throw ApiError.forbidden(`Bạn không có quyền ${action} hồ sơ này.`);
  };

  const update = async (userId, changes) => {
    await requireFreeEmail(changes.email, userId);
    return found(await repository.updateById({ id: userId, set: toModelFields(changes) }));
  };

  return {
    async register({ username, hoTen, email, password, trinhDo = 'N5' }) {
      if (await repository.usernameTaken(username)) {
        throw ApiError.conflict('Tên đăng nhập đã tồn tại.', { code: 'DUPLICATE_USERNAME' });
      }
      await requireFreeEmail(email);
      const at = now();
      return publicUser(
        await repository.create({
          TenDangNhap: username,
          HoTen: hoTen,
          Email: email,
          MatKhau: await passwordHasher.hash(password),
          TrinhDo: trinhDo,
          VaiTro: 'user',
          NgayTao: at,
          LanDangNhapCuoi: at,
        }),
      );
    },

    async profile({ actor, userId }) {
      requireSelfOrAdmin(actor, userId, 'xem');
      return found(await repository.findPublicById(userId));
    },

    async updateProfile({ actor, userId, changes }) {
      requireSelfOrAdmin(actor, userId, 'sửa');
      return update(userId, changes);
    },

    /** Ảnh đại diện chỉ đổi được của chính mình. */
    async setAvatar({ actor, userId, avatar }) {
      if (!isSelf(actor, userId)) throw ApiError.forbidden('Không có quyền cập nhật ảnh đại diện của người dùng khác.');
      return found(await repository.updateById({ id: userId, set: { AnhDaiDien: avatar } }));
    },

    /** Từ khoá khớp nguyên văn trong họ tên, email hoặc tên đăng nhập. */
    async adminList({ page, limit, search, role, status, trinhDo }) {
      const pattern = search && { $regex: escapeRegExp(search), $options: 'i' };
      const filter = withoutUndefined({
        VaiTro: role,
        TrangThai: status,
        TrinhDo: trinhDo,
        $or: pattern ? [{ HoTen: pattern }, { Email: pattern }, { TenDangNhap: pattern }] : undefined,
      });
      const [items, total] = await Promise.all([
        repository.findPage({ filter, skip: toSkip({ page, limit }), limit }),
        repository.count(filter),
      ]);
      return { items: items.map(publicUser), total, page, limit };
    },

    adminUpdate({ userId, changes }) {
      return update(userId, changes);
    },

    /** Quản trị viên không tự xoá tài khoản đang dùng: tránh tự khoá mình khỏi hệ thống. */
    async adminRemove({ actor, userId }) {
      if (isSelf(actor, userId)) throw ApiError.badRequest('Bạn không thể tự xóa tài khoản của mình.');
      found(await repository.deleteById(userId));
    },

    async adminStats() {
      const { recentUsers, activeUsers, ...counts } = await repository.stats();
      return { ...counts, recentUsers: recentUsers.map(publicUser), activeUsers: activeUsers.map(publicUser) };
    },
  };
};

export const userService = createUserService();
