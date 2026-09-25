import { z } from 'zod';

import { DAILY_GOAL_OPTIONS, REMINDER_WINDOW } from './streak-policy.js';
import { isDayKey } from './streak-rules.js';
import { isReminderTime } from './streak-settings.js';

/** Trang lịch sử/lịch: mặc định như phân trang chung, tối đa 100 (spec §4.2, §4.3). */
const pageLimit = (fallback) => z.coerce.number().int().min(1).max(100).default(fallback);

const dayKeyParam = z
  .string()
  .refine(isDayKey, 'Ngày phải có dạng YYYY-MM-DD và tồn tại trên lịch.');

/**
 * Không có `mode` là đường tương thích cũ trả **cả mảng**; `mode=page` là
 * chế độ phân trang bằng cursor. `limit`/`cursor` chỉ có nghĩa ở chế độ trang.
 */
export const xpHistoryQuery = z.object({
  mode: z.enum(['page']).optional(),
  limit: pageLimit(20),
  cursor: z.string().min(1).max(512).optional(),
});

/** Khoảng ngày còn thiếu đầu nào thì service tự điền; độ dài khoảng kiểm ở service. */
export const daysQuery = z.object({
  from: dayKeyParam.optional(),
  to: dayKeyParam.optional(),
  cursor: dayKeyParam.optional(),
  limit: pageLimit(100),
});

/**
 * Query của bảng xếp hạng.
 *
 * `limit` có trần để một request không kéo cả bảng user về một lần; mặc định
 * 50 là con số client hiện tại đang gửi.
 */
export const leaderboardQuery = z.object({
  period: z.enum(['all', 'week', 'month']).default('all'),
  limit: z.coerce.number().int().min(1).max(100).default(50),
});

/**
 * Thay đổi cài đặt mục tiêu ngày và nhắc học (spec §5.1, §5.3).
 *
 * `strictObject`: trường lạ bị từ chối chứ không bị lờ đi — đường này không
 * được trở thành cửa sau để client tự đặt `freezes_available` hay `revision`.
 * Cần ít nhất một thay đổi.
 */
export const settingsBody = z
  .strictObject({
    daily_goal_xp: z.union(DAILY_GOAL_OPTIONS.map((goal) => z.literal(goal))).optional(),
    reminder_enabled: z.boolean().optional(),
    reminder_time: z
      .string()
      .refine(
        isReminderTime,
        `Giờ nhắc phải có dạng HH:MM, trong khoảng ${REMINDER_WINDOW.start}–${REMINDER_WINDOW.end}.`,
      )
      .optional(),
  })
  .refine((body) => Object.keys(body).length > 0, { message: 'Cần gửi ít nhất một thay đổi.' });
