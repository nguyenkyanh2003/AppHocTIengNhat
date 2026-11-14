import assert from 'node:assert/strict';
import test from 'node:test';

import express from 'express';
import request from 'supertest';

import { errorHandler } from '../src/middleware/error.middleware.js';
import { createSettingsRoutes } from '../src/modules/settings/settings.routes.js';

const SETTINGS = { notificationsEnabled: true, soundEnabled: false, vibrateEnabled: true, language: 'vi', theme: 'auto' };

const buildApp = (service) => {
  const app = express();
  app.use(express.json());
  app.use('/api/settings', createSettingsRoutes({
    service,
    authenticate: (req, _res, next) => { req.user = { _id: 'user-1' }; next(); },
  }));
  app.use(errorHandler);
  return app;
};

const recording = (methods) => {
  const calls = [];
  const service = Object.fromEntries(Object.entries(methods).map(([name, result]) => [name, async (args) => {
    calls.push([name, args]);
    return result;
  }]));
  return { calls, service };
};

test('GET / trả cài đặt của chính người đang đăng nhập trong `data`', async () => {
  const { calls, service } = recording({ get: SETTINGS });

  const response = await request(buildApp(service)).get('/api/settings');

  assert.equal(response.status, 200);
  assert.deepEqual(response.body, { data: SETTINGS });
  assert.deepEqual(calls, [['get', 'user-1']]);
});

test('POST / lưu đủ năm cài đặt', async () => {
  const { calls, service } = recording({ save: SETTINGS });

  const response = await request(buildApp(service)).post('/api/settings').send(SETTINGS);

  assert.deepEqual(response.body, { data: SETTINGS, message: 'Cài đặt đã được cập nhật.' });
  assert.deepEqual(calls, [['save', { userId: 'user-1', settings: SETTINGS }]]);
});

test('POST / thiếu trường hoặc giá trị lạ là 400, không lặng lẽ đặt lại về mặc định', async () => {
  const { calls, service } = recording({ save: SETTINGS });
  const app = buildApp(service);

  for (const body of [
    { ...SETTINGS, theme: undefined },
    { ...SETTINGS, language: 'fr' },
    { ...SETTINGS, theme: 'system' },
    { ...SETTINGS, soundEnabled: 'yes' },
    {},
  ]) {
    assert.equal((await request(app).post('/api/settings').send(body)).status, 400, JSON.stringify(body));
  }
  assert.deepEqual(calls, []);
});
