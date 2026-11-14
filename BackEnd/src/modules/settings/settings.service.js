import { ApiError } from '../../shared/http/api-error.js';
import { settingsRepository } from './settings.repository.js';

/** Mặc định của `User.settings`; tài khoản cũ chưa lưu lần nào chưa có trường nào. */
const DEFAULTS = Object.freeze({
  notificationsEnabled: true,
  soundEnabled: true,
  vibrateEnabled: true,
  language: 'vi',
  theme: 'light',
});

const withDefaults = (settings) =>
  Object.fromEntries(Object.entries(DEFAULTS).map(([key, value]) => [key, settings[key] ?? value]));

const userNotFound = () => ApiError.notFound('Người dùng không tìm thấy.');

export const createSettingsService = ({ repository }) => ({
  async get(userId) {
    const settings = await repository.findSettings(userId);
    if (!settings) throw userNotFound();
    return withDefaults(settings);
  },

  async save({ userId, settings }) {
    const saved = await repository.saveSettings({ userId, settings });
    if (!saved) throw userNotFound();
    return withDefaults(saved);
  },
});

export const settingsService = createSettingsService({ repository: settingsRepository });
