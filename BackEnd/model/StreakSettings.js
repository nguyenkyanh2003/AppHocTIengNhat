import mongoose from 'mongoose';

/**
 * Cài đặt duy trì việc học của một người dùng: mục tiêu XP mỗi ngày và nhắc
 * học (spec streak §5.1, §5.3).
 *
 * Tách khỏi `UserStreak` vì hai thứ có nhịp ghi khác hẳn nhau: tóm tắt streak
 * bị ghi ở mọi hoạt động học trong transaction, còn cài đặt chỉ đổi khi người
 * dùng tự bấm lưu. Chung một document thì mỗi lần lưu cài đặt lại tranh
 * `revision` với các lượt ôn đang ghi.
 *
 * Hằng số bên dưới lặp lại chính sách trong `streak-policy.js` thay vì import
 * từ tầng nghiệp vụ; `tests/streak-settings.test.js` giữ hai nơi khớp nhau.
 */
export const SETTINGS_GOAL_OPTIONS = Object.freeze([10, 20, 30, 50]);
export const SETTINGS_REMINDER_WINDOW = Object.freeze({ start: '08:00', end: '21:59' });

const TIME_PATTERN = /^([01]\d|2[0-3]):[0-5]\d$/;
const DAY_PATTERN = /^(\d{4})-(\d{2})-(\d{2})$/;

const isGoal = (value) => SETTINGS_GOAL_OPTIONS.includes(value);

/** Ngày `YYYY-MM-DD` có thật trên lịch (30/2 không qua). */
const isRealDay = (value) => {
  const match = DAY_PATTERN.exec(value);
  if (!match) return false;
  const [, year, month, day] = match.map(Number);
  const date = new Date(Date.UTC(year, month - 1, day));
  return date.getUTCFullYear() === year && date.getUTCMonth() === month - 1 && date.getUTCDate() === day;
};

const StreakSettingsSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, unique: true },

    /**
     * Mức người dùng chọn **gần nhất**. Có thể chưa có hiệu lực: đổi mục tiêu
     * chỉ áp dụng từ ngày Việt Nam kế tiếp, nên trước `goal_effective_from`
     * mục tiêu đang tính vẫn là `previous_goal_xp` (spec §5.1).
     */
    daily_goal_xp: {
      type: Number,
      default: 20,
      validate: { validator: isGoal, message: 'Mục tiêu ngày chỉ được là 10, 20, 30 hoặc 50 XP.' },
    },
    previous_goal_xp: {
      type: Number,
      default: null,
      validate: {
        validator: (value) => value === null || isGoal(value),
        message: 'Mục tiêu trước đó không hợp lệ.',
      },
    },
    goal_effective_from: {
      type: String,
      default: null,
      validate: {
        validator: (value) => value === null || isRealDay(value),
        message: 'Ngày hiệu lực phải có dạng YYYY-MM-DD.',
      },
    },

    reminder_enabled: { type: Boolean, default: false },
    reminder_time: {
      type: String,
      default: '20:00',
      validate: {
        validator: (value) =>
          TIME_PATTERN.test(value) &&
          value >= SETTINGS_REMINDER_WINDOW.start &&
          value <= SETTINGS_REMINDER_WINDOW.end,
        message: 'Giờ nhắc phải trong khoảng 08:00–21:59.',
      },
    },

    /** Mỗi lần lưu tăng một; lưu có điều kiện trên nó để hai thiết bị không đè nhau. */
    revision: { type: Number, default: 0, min: 0 },
  },
  { timestamps: true },
);

export default mongoose.model('StreakSettings', StreakSettingsSchema);
