import assert from 'node:assert/strict';
import test from 'node:test';
import request from 'supertest';

import app from '../src/app.js';

test('root API metadata remains available', async () => {
  const response = await request(app).get('/');

  assert.equal(response.status, 200);
  assert.equal(response.body.version, '1.0.0');
  assert.equal(response.body.message, 'API App Học Tiếng Nhật');
});

test('unknown API path keeps the existing 404 contract', async () => {
  const response = await request(app).get('/definitely-missing');

  assert.equal(response.status, 404);
  assert.deepEqual(response.body, { message: 'API không tồn tại' });
});


test('cac duong tu cap thuong da bien mat khoi app that', async () => {
  // Không phải chỉ gỡ khỏi router rời: kiểm trên chính app đã lắp đủ route.
  for (const [method, path] of [
    ['post', '/api/streak/add-xp'],
    ['post', '/api/streak/test/reset-yesterday'],
    ['get', '/api/streak/test/debug'],
    ['post', '/api/achievement/update-progress'],
  ]) {
    const response = await request(app)[method](path).send({});
    assert.equal(response.status, 404, `${method.toUpperCase()} ${path} phải 404`);
    assert.deepEqual(response.body, { message: 'API không tồn tại' });
  }
});

/**
 * Route không màn hình nào gọi, đã gỡ ở đợt 0 (spec one-style §6.1).
 *
 * Mỗi path được chọn sao cho **không** khớp route tham số nào còn lại, nên phải
 * ra đúng 404 của notFoundHandler — không tới middleware auth hay handler nào.
 */
const REMOVED_ROUTES = [
  // chat
  ['post', '/api/group-chat/507f1f77bcf86cd799439011'],
  ['get', '/api/group-chat/507f1f77bcf86cd799439011'],
  // jlpt
  ['get', '/api/jlpt/admin/all'],
  ['get', '/api/jlpt/history/me'],
  ['post', '/api/jlpt/submit/507f1f77bcf86cd799439011'],
];

test('route không còn consumer đã bị gỡ khỏi app thật', async () => {
  for (const [method, path] of REMOVED_ROUTES) {
    const response = await request(app)[method](path).send({});
    assert.equal(response.status, 404, `${method.toUpperCase()} ${path} phải 404`);
    assert.deepEqual(response.body, { message: 'API không tồn tại' });
  }
});
