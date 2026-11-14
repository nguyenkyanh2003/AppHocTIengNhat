import User from '../../../model/User.js';

/**
 * Cài đặt nằm trong document người dùng (`User.settings`). `null` khi tài khoản
 * không còn.
 */
export const createSettingsRepository = ({ User: model }) => ({
  async findSettings(userId) {
    const user = await model.findById(userId).select('settings').lean();
    return user ? (user.settings ?? {}) : null;
  },

  async saveSettings({ userId, settings }) {
    const set = Object.fromEntries(Object.entries(settings).map(([key, value]) => [`settings.${key}`, value]));
    const user = await model
      .findByIdAndUpdate(userId, { $set: set }, { new: true, runValidators: true })
      .select('settings')
      .lean();
    return user ? user.settings : null;
  },
});

export const settingsRepository = createSettingsRepository({ User });
