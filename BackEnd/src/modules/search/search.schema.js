import { z } from 'zod';

export const LIMIT_PER_TYPE_DEFAULT = 5;
export const LIMIT_PER_TYPE_MAX = 10;
export const KEYWORD_MAX = 100;

export const searchQuery = z.object({
  q: z
    .string()
    .trim()
    .min(1, 'Vui lòng nhập từ khóa tìm kiếm.')
    .max(KEYWORD_MAX, `Từ khóa tối đa ${KEYWORD_MAX} ký tự.`),
  limit_per_type: z.coerce
    .number()
    .int()
    .min(1)
    .max(LIMIT_PER_TYPE_MAX)
    .default(LIMIT_PER_TYPE_DEFAULT),
});
