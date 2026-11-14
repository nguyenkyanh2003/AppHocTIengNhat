import { z } from 'zod';

import { paginationQuery } from '../../shared/http/pagination.js';
import { objectId, optionalQuery } from '../../shared/http/schemas.js';

/** Khớp enum trong `model/Transaction.js`. */
export const TRANSACTION_TYPES = ['SUBSCRIPTION', 'DEPOSIT', 'SPEND', 'REWARD'];
export const TRANSACTION_STATUSES = ['pending', 'processing', 'completed', 'failed', 'cancelled', 'refunded'];
export const CURRENCIES = ['VND', 'GOLD', 'GEM'];
export const PAYMENT_METHODS = ['BANK', 'MOMO', 'VNPAY', 'CARD', 'NONE'];

const status = z.enum(TRANSACTION_STATUSES);
const type = z.enum(TRANSACTION_TYPES);

export const idParams = z.object({ id: objectId });

/** Người dùng và trạng thái do server đặt; trường lạ trong body bị bỏ. */
export const createBody = z.object({
  type,
  amount: z.number().positive('Số tiền phải lớn hơn 0.'),
  currency: z.enum(CURRENCIES).default('VND'),
  description: z.string().trim().max(500).optional(),
  payment_method: z.enum(PAYMENT_METHODS).default('NONE'),
  payment_ref_id: z.string().trim().min(1).max(100).optional(),
  package_id: z.string().trim().min(1).max(50).optional(),
  metadata: z.record(z.string(), z.unknown()).optional(),
});

export const adminQuery = paginationQuery
  .extend({
    status: optionalQuery(status),
    type: optionalQuery(type),
    userId: optionalQuery(objectId),
    startDate: optionalQuery(z.coerce.date()),
    endDate: optionalQuery(z.coerce.date()),
  })
  .refine(({ startDate, endDate }) => !startDate || !endDate || startDate <= endDate, {
    message: 'Ngày bắt đầu phải trước ngày kết thúc.',
    path: ['endDate'],
  });

/** Ghi chú bỏ trống nghĩa là chỉ đổi trạng thái, giữ ghi chú cũ. */
export const statusBody = z.object({
  status,
  notes: z
    .string()
    .trim()
    .max(1000)
    .optional()
    .transform((value) => value || undefined),
});
