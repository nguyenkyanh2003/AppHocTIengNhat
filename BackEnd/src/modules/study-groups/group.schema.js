import { z } from 'zod';

import { paginationQuery } from '../../shared/http/pagination.js';
import { objectId, optionalQuery } from '../../shared/http/schemas.js';

/** Khớp enum `level` trong `model/StudyGroup.js`. */
export const GROUP_LEVELS = ['N5', 'N4', 'N3', 'N2', 'N1', 'ALL'];

const fields = {
  name: z.string().trim().min(1, 'Tên nhóm không được để trống.').max(100),
  description: z.string().trim().max(500),
  level: z.enum(GROUP_LEVELS),
  is_private: z.boolean(),
  max_members: z.number().int().min(2).max(500),
};

export const listQuery = paginationQuery.extend({
  search: optionalQuery(z.string().trim().min(1).max(100)),
  level: optionalQuery(fields.level),
  is_private: optionalQuery(z.enum(['true', 'false']).transform((value) => value === 'true')),
});

export const groupParams = z.object({ groupID: objectId });

export const memberParams = z.object({ groupID: objectId, userID: objectId });

/** Người tạo, thành viên và ảnh do server đặt; trường lạ trong body bị bỏ. */
export const createBody = z.object({
  name: fields.name,
  description: fields.description.optional(),
  level: fields.level.default('ALL'),
  is_private: fields.is_private.default(false),
  max_members: fields.max_members.default(50),
});

/** Sửa chỉ ghi trường được gửi, nên không có `.default()` ở đây. */
export const updateBody = z
  .object(fields)
  .partial()
  .refine((changes) => Object.keys(changes).length > 0, 'Không có gì để cập nhật.');
