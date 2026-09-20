import { z } from 'zod';

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
