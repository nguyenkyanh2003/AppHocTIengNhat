import { z } from 'zod';

import { paginationQuery } from '../../shared/http/pagination.js';
import { objectId, optionalQuery } from '../../shared/http/schemas.js';

/** Khớp enum trong `model/Report.js`. */
export const REPORT_TYPES = ['bug', 'suggestion', 'content', 'other'];
export const REPORT_PRIORITIES = ['low', 'medium', 'high', 'urgent'];
export const REPORT_STATUSES = ['pending', 'in_progress', 'resolved', 'rejected'];

const status = z.enum(REPORT_STATUSES);

export const idParams = z.object({ id: objectId });

/** Trạng thái, phản hồi và thời điểm xử lý do server đặt; trường lạ trong body bị bỏ. */
export const createBody = z.object({
  type: z.enum(REPORT_TYPES),
  title: z.string().trim().min(1, 'Vui lòng nhập tiêu đề.').max(200),
  description: z.string().trim().min(1, 'Vui lòng nhập mô tả.').max(5000),
  priority: z.enum(REPORT_PRIORITIES).default('medium'),
  related_id: objectId.nullish(),
  related_type: z.string().trim().max(50).nullish(),
});

export const mineQuery = paginationQuery.extend({ status: optionalQuery(status) });

export const adminQuery = paginationQuery.extend({
  status: optionalQuery(status),
  type: optionalQuery(z.enum(REPORT_TYPES)),
  priority: optionalQuery(z.enum(REPORT_PRIORITIES)),
  user_id: optionalQuery(objectId),
});

/** Phản hồi bỏ trống nghĩa là chỉ đổi trạng thái, giữ phản hồi cũ. */
export const statusBody = z.object({
  status,
  admin_response: z
    .string()
    .trim()
    .max(5000)
    .optional()
    .transform((value) => value || undefined),
});
