import nodemailer from 'nodemailer';

import env from '../../config/env.js';

let sharedTransport = null;

/** Transport thật chỉ được dựng khi cần gửi thư, để import module không cần SMTP. */
const defaultTransport = () => {
  if (!sharedTransport) {
    sharedTransport = nodemailer.createTransport({
      service: 'gmail',
      auth: { user: env.emailUser, pass: env.emailPassword },
    });
  }

  return sharedTransport;
};

const resetEmailHtml = ({ fullName, resetLink }) => `
        <h2>Yêu cầu khôi phục mật khẩu</h2>
        <p>Xin chào ${fullName ?? ''},</p>
        <p>Để đặt lại mật khẩu, vui lòng click vào link bên dưới:</p>
        <a href="${resetLink}" style="padding: 10px 15px; background-color: #007bff; color: white; text-decoration: none; border-radius: 5px;">Đặt lại mật khẩu</a>
        <p>Link này sẽ hết hạn sau 1 giờ.</p>
        <p>Nếu bạn không yêu cầu đặt lại mật khẩu, vui lòng bỏ qua email này.</p>
      `;

/**
 * Gửi thư khôi phục mật khẩu.
 *
 * Nhận `transport` qua tham số để test dùng transport giả; không test nào được
 * chạm SMTP thật. `to` luôn do service truyền vào từ dữ liệu database, mailer
 * không tự đọc địa chỉ từ request.
 */
export const createPasswordResetMailer = ({
  transport,
  emailUser = env.emailUser,
  emailPassword = env.emailPassword,
} = {}) => ({
  isConfigured: () => Boolean(emailUser && emailPassword),

  async sendPasswordReset({ to, fullName, resetLink }) {
    await (transport ?? defaultTransport()).sendMail({
      from: emailUser,
      to,
      subject: 'Yêu cầu đặt lại mật khẩu',
      html: resetEmailHtml({ fullName, resetLink }),
    });
  },
});

export const passwordResetMailer = createPasswordResetMailer();

export default passwordResetMailer;
