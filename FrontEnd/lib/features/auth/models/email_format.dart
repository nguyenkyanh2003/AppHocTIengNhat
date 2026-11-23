/// Kiểm ô email của form đăng ký và quên mật khẩu trước khi gửi lên server.
///
/// Chỉ chặn lỗi gõ rõ ràng (thiếu `@`, thiếu tên miền, có dấu cách); server
/// kiểm lại bằng `z.email()` trong `BackEnd/src/modules/users/user.schema.js`.
/// Form không được chặt hơn server: chặn `lan+jp@gmail.com` hay đuôi dài như
/// `.education` thì chủ địa chỉ đó không đăng ký hay lấy lại mật khẩu được.
abstract final class EmailFormat {
  static final _pattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

  /// Validator cho `TextFormField`: `null` là hợp lệ.
  static String? validate(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Vui lòng nhập email';
    if (!_pattern.hasMatch(email)) return 'Email không hợp lệ';
    return null;
  }
}
