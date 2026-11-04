import { z } from 'zod';

/** Query rỗng (`?year=`) được coi như không truyền. */
const optional = (schema) =>
  z.preprocess(
    (value) => (value === '' || value === null ? undefined : value),
    schema.optional(),
  );

/** Kỳ của biểu đồ học tập — đúng ba lựa chọn màn dashboard đang gửi. */
export const timelineQuery = z.object({
  period: z.enum(['week', 'month', 'year']).default('week'),
});

/** Bỏ trống `year` thì service lấy năm hiện tại theo giờ Việt Nam. */
export const heatmapQuery = z.object({
  year: optional(z.coerce.number().int().min(2000).max(2100)),
});

export const analyticsQuery = z.object({
  period: z.enum(['7d', '30d', '90d']).default('7d'),
});
