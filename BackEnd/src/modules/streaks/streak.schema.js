import { z } from 'zod';

import { isDayKey } from './streak-rules.js';

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
