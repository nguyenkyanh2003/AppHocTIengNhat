/// Quy định mật khẩu dùng chung cho đăng ký, đặt lại và đổi mật khẩu.
///
/// Phải khớp `PASSWORD_MIN_LENGTH` trong `BackEnd/src/modules/users/user.schema.js`,
/// nếu không form báo hợp lệ rồi server vẫn trả 400. Đăng nhập **không** kiểm
/// độ dài: tài khoản cũ đặt mật khẩu ngắn hơn vẫn phải đăng nhập được.
abstract final class PasswordPolicy {
  static const int minLength = 8;
}
