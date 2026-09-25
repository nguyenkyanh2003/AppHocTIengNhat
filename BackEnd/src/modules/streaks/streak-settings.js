import {
  DAILY_GOAL_OPTIONS,
  DEFAULT_DAILY_GOAL,
  DEFAULT_REMINDER_TIME,
  REMINDER_WINDOW,
} from './streak-policy.js';
import { addDays } from './streak-rules.js';

/**
 * Luật cài đặt mục tiêu ngày và nhắc học, viết dạng hàm thuần (spec §5.1, §5.3).
 *
 * "Hôm nay" luôn được truyền vào dưới dạng khoá ngày Việt Nam, không đọc đồng
 * hồ ở đây — cùng lý do với `streak-rules.js`: ranh giới nửa đêm chỉ được tính
 * ở một chỗ.
 *
 * Mục tiêu được lưu thành ba trường: `daily_goal_xp` (lựa chọn mới nhất),
 * `previous_goal_xp` và `goal_effective_from`. Trước ngày hiệu lực, mục tiêu
 * đang tính là `previous_goal_xp`; từ ngày đó trở đi là `daily_goal_xp`.
 */

const TIME_PATTERN = /^([01]\d|2[0-3]):[0-5]\d$/;

export const isDailyGoal = (value) => DAILY_GOAL_OPTIONS.includes(value);

/** `HH:MM` 24 giờ, nằm trong khung nhắc cho phép (tính cả hai đầu). */
export const isReminderTime = (value) =>
  typeof value === 'string' &&
  TIME_PATTERN.test(value) &&
  value >= REMINDER_WINDOW.start &&
  value <= REMINDER_WINDOW.end;

/** Khoá `YYYY-MM-DD` so sánh được theo thứ tự chữ, nên `<` là "trước ngày". */
const isPending = (settings, todayKey) =>
  Boolean(settings?.goal_effective_from) && todayKey < settings.goal_effective_from;

/** Mục tiêu XP đang tính cho ngày `todayKey`. */
export const effectiveGoal = (settings, todayKey) => {
  if (!settings) return DEFAULT_DAILY_GOAL;
  if (isPending(settings, todayKey)) return settings.previous_goal_xp ?? DEFAULT_DAILY_GOAL;
  return settings.daily_goal_xp ?? DEFAULT_DAILY_GOAL;
};

/**
 * Các trường cần ghi khi người dùng chọn mục tiêu `goal` vào ngày `todayKey`.
 *
 * Mốc so sánh luôn là mục tiêu **đang tính hôm nay**, không phải lựa chọn chờ
 * trước đó: đổi 20 → 30 rồi → 50 trong cùng ngày thì hôm nay vẫn là 20, mai là
 * 50. Chọn lại đúng mục tiêu hôm nay thì huỷ thay đổi đang chờ.
 */
export const planGoalChange = (settings, goal, todayKey) => {
  const today = effectiveGoal(settings, todayKey);
  if (goal === today) {
    return { daily_goal_xp: goal, previous_goal_xp: null, goal_effective_from: null };
  }
  return { daily_goal_xp: goal, previous_goal_xp: today, goal_effective_from: addDays(todayKey, 1) };
};

/** Dạng trả cho client; chưa có cài đặt thì là mặc định. */
export const settingsView = (settings, todayKey) => {
  const goal = effectiveGoal(settings, todayKey);
  const pending = isPending(settings, todayKey) && settings.daily_goal_xp !== goal;

  return {
    daily_goal_xp: goal,
    next_daily_goal_xp: pending ? settings.daily_goal_xp : null,
    next_goal_from: pending ? settings.goal_effective_from : null,
    goal_options: [...DAILY_GOAL_OPTIONS],
    reminder_enabled: settings?.reminder_enabled ?? false,
    reminder_time: settings?.reminder_time ?? DEFAULT_REMINDER_TIME,
    reminder_window: { ...REMINDER_WINDOW },
    revision: settings?.revision ?? 0,
  };
};
