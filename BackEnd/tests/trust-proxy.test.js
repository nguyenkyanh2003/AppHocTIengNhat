import assert from 'node:assert/strict';
import test from 'node:test';

// Đặt trước khi import: `env.js` đọc biến môi trường một lần lúc nạp module.
process.env.TRUST_PROXY = '1';
const { default: app } = await import('../src/app.js');
const { parseTrustProxy } = await import('../src/config/env.js');

test('TRUST_PROXY đọc thành giá trị `trust proxy` của Express', () => {
  assert.equal(parseTrustProxy(undefined), false, 'bỏ trống: chạy thẳng, không tin proxy nào');
  assert.equal(parseTrustProxy(''), false);
  assert.equal(parseTrustProxy('false'), false);
  assert.equal(parseTrustProxy(' 1 '), 1, 'số proxy đứng trước server');
  assert.equal(parseTrustProxy('loopback'), 'loopback');
  assert.equal(parseTrustProxy('10.0.0.0/8, 172.16.0.1'), '10.0.0.0/8,172.16.0.1');
  assert.equal(parseTrustProxy('true'), null, 'tin mọi proxy: từ chối');
  assert.equal(parseTrustProxy('nginx'), null, 'Express không hiểu thì không đưa cho Express');
  assert.equal(parseTrustProxy('10.0.0.0/8/1'), null);
});

test('app lấy địa chỉ người dùng theo TRUST_PROXY trong .env', () => {
  assert.equal(app.get('trust proxy'), 1);
});

test('TRUST_PROXY=true bị từ chối lúc khởi động: ai cũng gửi được X-Forwarded-For giả', async () => {
  process.env.TRUST_PROXY = 'true';
  const { default: env, validateEnvironment } = await import('../src/config/env.js?trust-proxy-true');

  assert.equal(env.trustProxy, false, 'app vẫn nạp được, chạy như không có proxy');
  assert.throws(validateEnvironment, /TRUST_PROXY=true/);
});

test('TRUST_PROXY sai định dạng: dừng với lời giải thích thay vì lỗi của Express', async () => {
  process.env.TRUST_PROXY = 'nginx';
  const { validateEnvironment } = await import('../src/config/env.js?trust-proxy-invalid');

  assert.throws(validateEnvironment, /TRUST_PROXY không hợp lệ: "nginx"/);
});
