import assert from 'node:assert/strict';
import test from 'node:test';

import { createSettingsService } from '../src/modules/settings/settings.service.js';

const SETTINGS = { notificationsEnabled: false, soundEnabled: true, vibrateEnabled: false, language: 'ja', theme: 'dark' };

const repository = ({ found, saved } = {}) => {
  const calls = [];
  return {
    calls,
    findSettings: async (userId) => {
      calls.push(['findSettings', userId]);
      return found;
    },
    saveSettings: async (args) => {
      calls.push(['saveSettings', args]);
      return saved;
    },
  };
};

test('đọc cài đặt đã lưu', async () => {
  const fake = repository({ found: SETTINGS });
  assert.deepEqual(await createSettingsService({ repository: fake }).get('u1'), SETTINGS);
  assert.deepEqual(fake.calls, [['findSettings', 'u1']]);
});

test('tài khoản chưa từng lưu cài đặt nhận giá trị mặc định của model', async () => {
  const fake = repository({ found: {} });
  assert.deepEqual(await createSettingsService({ repository: fake }).get('u1'), {
    notificationsEnabled: true,
    soundEnabled: true,
    vibrateEnabled: true,
    language: 'vi',
    theme: 'light',
  });
});

test('tài khoản không còn là 404', async () => {
  await assert.rejects(createSettingsService({ repository: repository({ found: null }) }).get('u1'), { status: 404 });
  await assert.rejects(
    createSettingsService({ repository: repository({ saved: null }) }).save({ userId: 'u1', settings: SETTINGS }),
    { status: 404 },
  );
});

test('lưu ghi đủ năm cài đặt và trả lại bản đã lưu', async () => {
  const fake = repository({ saved: SETTINGS });

  assert.deepEqual(await createSettingsService({ repository: fake }).save({ userId: 'u1', settings: SETTINGS }), SETTINGS);
  assert.deepEqual(fake.calls, [['saveSettings', { userId: 'u1', settings: SETTINGS }]]);
});
