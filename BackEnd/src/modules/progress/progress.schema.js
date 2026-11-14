import { z } from 'zod';

import { optionalQuery } from '../../shared/http/schemas.js';

/** Kỳ của biểu đồ học tập — đúng ba lựa chọn màn dashboard đang gửi. */
export const timelineQuery = z.object({
  period: z.enum(['week', 'month', 'year']).default('week'),
});

/** Bỏ trống `year` thì service lấy năm hiện tại theo giờ Việt Nam. */
export const heatmapQuery = z.object({
  year: optionalQuery(z.coerce.number().int().min(2000).max(2100)),
});

export const analyticsQuery = z.object({
  period: z.enum(['7d', '30d', '90d']).default('7d'),
});
