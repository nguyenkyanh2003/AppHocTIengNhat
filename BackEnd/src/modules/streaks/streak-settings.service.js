import { ApiError } from '../../shared/http/api-error.js';
import { dayKey as defaultDayKey } from './streak-rules.js';
import { isDailyGoal, isReminderTime, planGoalChange, settingsView } from './streak-settings.js';
import { streakSettingsRepository } from './streak-settings.repository.js';

/**
 * Đọc và lưu cài đặt mục tiêu ngày, nhắc học (spec §5.1, §5.3).
 *
 * Đọc không bao giờ tạo document: người chưa lưu gì nhận mặc định. Lưu là
 * đọc – tính – ghi có điều kiện trên `revision`; thua thì đọc lại, vì mục tiêu
 * mới được tính **từ** mục tiêu đang có hiệu lực, không ghi đè mù được.
 */

/** Thua CAS quá chừng này lần thì trả 409 thay vì giữ request mãi. */
const MAX_ATTEMPTS = 5;

/** Chặn lần hai sau lớp validate: service này còn được gọi từ script và test. */
const assertChanges = (changes) => {
  const keys = Object.keys(changes ?? {});
  const valid =
    keys.length > 0 &&
    (changes.daily_goal_xp === undefined || isDailyGoal(changes.daily_goal_xp)) &&
    (changes.reminder_enabled === undefined || typeof changes.reminder_enabled === 'boolean') &&
    (changes.reminder_time === undefined || isReminderTime(changes.reminder_time));
  if (!valid) {
    throw ApiError.badRequest('Cài đặt không hợp lệ.', { code: 'INVALID_STREAK_SETTINGS' });
  }
};

export const createStreakSettingsService = ({
  repository = streakSettingsRepository,
  dayKey = defaultDayKey,
  clock = () => new Date(),
} = {}) => ({
  async get(userId) {
    return settingsView(await repository.findByUser({ userId }), dayKey(clock()));
  },

  async update(userId, changes) {
    assertChanges(changes);

    for (let attempt = 1; attempt <= MAX_ATTEMPTS; attempt += 1) {
      // Tính ngày ở mỗi vòng: một lần thử lại rơi đúng lúc qua nửa đêm phải
      // lấy mục tiêu của ngày mới làm mốc.
      const todayKey = dayKey(clock());
      const current = await repository.findByUser({ userId });

      const patch = {};
      if (changes.daily_goal_xp !== undefined) {
        Object.assign(patch, planGoalChange(current, changes.daily_goal_xp, todayKey));
      }
      if (changes.reminder_enabled !== undefined) patch.reminder_enabled = changes.reminder_enabled;
      if (changes.reminder_time !== undefined) patch.reminder_time = changes.reminder_time;

      const saved = current
        ? await repository.cas({ userId, expectedRevision: current.revision ?? 0, patch })
        : await repository.create({ userId, fields: patch });
      if (saved) return settingsView(saved, todayKey);
    }

    throw ApiError.conflict('Cài đặt vừa được thay đổi ở nơi khác. Vui lòng thử lại.', {
      code: 'STREAK_SETTINGS_CONFLICT',
    });
  },
});

export const streakSettingsService = createStreakSettingsService();

export default streakSettingsService;
