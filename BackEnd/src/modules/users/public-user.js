/**
 * Hồ sơ người dùng trả ra ngoài, dùng chung cho đăng nhập, hồ sơ và trang quản trị.
 *
 * Bỏ mật khẩu, version phiên, khoá nội bộ của Mongoose và bốn trường thống kê đời
 * cũ (`DiemTichLuy`, `StreakHienTai`, `StreakDaiNhat`, `TongThoiGianHoc`) mà không
 * luồng nào còn ghi — trả ra thì màn hình hiện 0 mãi. XP và chuỗi ngày thật nằm ở
 * `UserStreak`.
 */
export const publicUser = (user) => {
  if (!user) return null;
  const {
    MatKhau: _password,
    tokenVersion: _version,
    __v: _v,
    DiemTichLuy: _xp,
    StreakHienTai: _streak,
    StreakDaiNhat: _longest,
    TongThoiGianHoc: _studyTime,
    ...rest
  } = user;
  return rest;
};
