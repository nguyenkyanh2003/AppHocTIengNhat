import assert from 'node:assert/strict';
import test from 'node:test';

import { createPasswordResetMailer } from '../src/modules/users/user-auth.mailer.js';

const fakeTransport = () => {
  const sent = [];
  let verified = 0;
  return {
    sent,
    get verified() {
      return verified;
    },
    async sendMail(message) {
      sent.push(message);
    },
    async verify() {
      verified += 1;
      return true;
    },
  };
};

test('thư đặt lại mật khẩu gửi từ tài khoản cấu hình, kèm link và tên người nhận', async () => {
  const transport = fakeTransport();
  const mailer = createPasswordResetMailer({ transport, emailUser: 'app@example.com', emailPassword: 'x' });

  await mailer.sendPasswordReset({
    to: 'lan@example.com',
    fullName: 'Lê Lan',
    resetLink: 'http://localhost:8080/#/reset-password?token=abc',
  });

  const [message] = transport.sent;
  assert.equal(message.from, 'app@example.com');
  assert.equal(message.to, 'lan@example.com');
  assert.match(message.html, /Lê Lan/);
  assert.match(message.html, /href="http:\/\/localhost:8080\/#\/reset-password\?token=abc"/);
});

test('kiểm cấu hình SMTP chỉ đăng nhập, không gửi thư', async () => {
  const transport = fakeTransport();
  const mailer = createPasswordResetMailer({ transport, emailUser: 'app@example.com', emailPassword: 'x' });

  await mailer.verify();

  assert.equal(transport.verified, 1);
  assert.equal(transport.sent.length, 0);
});

test('thiếu tài khoản hoặc mật khẩu thì coi là chưa cấu hình', () => {
  assert.equal(createPasswordResetMailer({ emailUser: 'app@example.com', emailPassword: '' }).isConfigured(), false);
  assert.equal(createPasswordResetMailer({ emailUser: '', emailPassword: 'x' }).isConfigured(), false);
  assert.equal(createPasswordResetMailer({ emailUser: 'app@example.com', emailPassword: 'x' }).isConfigured(), true);
});
