// Kiểm EMAIL_USER / EMAIL_PASSWORD trong .env: đăng nhập Gmail rồi thoát, không gửi thư nào.
//
// Quên mật khẩu không báo lỗi SMTP cho người dùng (báo thì lộ email nào có tài
// khoản), nên chạy script này sau khi đổi app password hoặc trước buổi demo.
//
//   cd BackEnd; node scripts/check-email.js
import { passwordResetMailer } from '../src/modules/users/user-auth.mailer.js';

if (!passwordResetMailer.isConfigured()) {
  console.error('❌ Chưa có EMAIL_USER hoặc EMAIL_PASSWORD trong BackEnd/.env.');
  process.exit(1);
}

try {
  await passwordResetMailer.verify();
  console.log('✅ Gmail nhận tài khoản trong .env — thư đặt lại mật khẩu gửi được.');
} catch (error) {
  console.error(`❌ Gmail từ chối đăng nhập: ${String(error.message).split('\n')[0]}`);
  console.error('   Tạo app password mới (Tài khoản Google → Bảo mật → Xác minh 2 bước → Mật khẩu ứng dụng)');
  console.error('   rồi thay EMAIL_PASSWORD trong BackEnd/.env.');
  process.exit(1);
}
