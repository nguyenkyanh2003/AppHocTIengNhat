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
