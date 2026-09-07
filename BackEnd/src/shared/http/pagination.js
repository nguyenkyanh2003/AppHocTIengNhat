import { z } from 'zod';

/** Quy ước phân trang dùng chung: page >= 1, limit mặc định 20, tối đa 100. */
export const PAGE_DEFAULT = 1;
export const LIMIT_DEFAULT = 20;
export const LIMIT_MAX = 100;

export const paginationQuery = z.object({
  page: z.coerce.number().int().min(1).default(PAGE_DEFAULT),
  limit: z.coerce.number().int().min(1).max(LIMIT_MAX).default(LIMIT_DEFAULT),
});

export const toSkip = ({ page, limit }) => (page - 1) * limit;
