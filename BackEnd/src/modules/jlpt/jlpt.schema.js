import { z } from 'zod';

import { paginationQuery } from '../../shared/http/pagination.js';
import { jlptLevel, objectId, optionalQuery } from '../../shared/http/schemas.js';

export const PRACTICE_TYPES = ['moji_goi', 'bunpou', 'dokkai', 'choukai'];

export const idParams = z.object({ id: objectId });

export const listQuery = paginationQuery.extend({
  level: optionalQuery(jlptLevel),
  year: optionalQuery(z.coerce.number().int().min(1990).max(2100)),
  month: optionalQuery(z.coerce.number().int().min(1).max(12)),
});

export const practiceQuery = z.object({
  type: z.enum(PRACTICE_TYPES).default('moji_goi'),
  level: optionalQuery(jlptLevel),
  limit: z.coerce.number().int().min(1).max(50).default(10),
});

/**
 * Bài nộp của một lượt thi. `attempt_id` bắt buộc: không có nó thì không phân
 * biệt được "gửi lại" (mất mạng) với "thi lại".
 *
 * `question_key` là vị trí câu trong đề (`moji_goi_0`, `dokkai_1_2`...),
 * `selected` là chỉ số lựa chọn 0–3.
 */
export const submitBody = z.object({
  attempt_id: z.uuid('Lượt thi phải có định danh dạng UUID.'),
  answers: z
    .array(z.object({ question_key: z.string().min(1).max(40), selected: z.number().int().min(0).max(3) }))
    .min(1, 'Bài làm không được rỗng.'),
  time_spent: z.number().int().min(0).optional(),
});
