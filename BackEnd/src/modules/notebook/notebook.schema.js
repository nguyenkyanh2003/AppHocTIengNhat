import { z } from 'zod';

import { paginationQuery } from '../../shared/http/pagination.js';
import { objectId, optionalQuery } from '../../shared/http/schemas.js';

/** Khớp enum `type` trong `model/NoteBook.js`. */
export const NOTE_TYPES = ['general', 'vocabulary', 'grammar', 'kanji', 'lesson'];

const noteType = z.enum(NOTE_TYPES);
const title = z.string().trim().min(1, 'Vui lòng nhập tiêu đề.').max(200);

/** Nội dung giữ nguyên khoảng trắng người dùng gõ (thụt đầu dòng), chỉ cấm bỏ trống. */
const content = z
  .string()
  .max(20000)
  .refine((value) => value.trim() !== '', 'Vui lòng nhập nội dung.');

/** Thẻ trùng nhau sau khi cắt khoảng trắng chỉ giữ một. */
const tags = z
  .array(z.string().trim().min(1).max(50))
  .max(20, 'Tối đa 20 thẻ.')
  .transform((values) => [...new Set(values)]);

export const listQuery = paginationQuery.extend({
  type: optionalQuery(noteType),
  search: optionalQuery(z.string().trim().min(1).max(100)),
});

export const idParams = z.object({ id: objectId });

/** Chủ ghi chú do server đặt; trường lạ trong body (kể cả `user_id`) bị bỏ. */
export const createBody = z.object({
  title,
  content,
  type: noteType.default('general'),
  tags: tags.default([]),
});

/** Sửa chỉ ghi trường được gửi, nên không có `.default()` ở đây. */
export const updateBody = z
  .object({
    title: title.optional(),
    content: content.optional(),
    type: noteType.optional(),
    tags: tags.optional(),
  })
  .refine((changes) => Object.keys(changes).length > 0, 'Không có gì để cập nhật.');
