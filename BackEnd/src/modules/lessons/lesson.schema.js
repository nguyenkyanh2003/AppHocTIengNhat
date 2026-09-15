import { z } from 'zod';

import { paginationQuery } from '../../shared/http/pagination.js';
import { SITUATIONS } from './situation-catalog.js';

export const LEVELS = ['N5', 'N4', 'N3', 'N2', 'N1'];

const objectId = z
  .string()
  .regex(/^[0-9a-fA-F]{24}$/, 'Định danh không hợp lệ.');

const level = z.enum(LEVELS);
const situation = z.enum(SITUATIONS);

/** Query rỗng (`?level=`) được coi như không truyền — cùng quy ước với vocabulary.schema.js. */
const optional = (schema) =>
  z.preprocess(
    (value) => (value === '' || value === null ? undefined : value),
    schema.optional(),
  );

/**
 * `lessonInput()` cũ trong controller chấp nhận cả tên field tiếng Việt di sản
 * (`TenBaiHoc`/`CapDo`/`LoaiBaiHoc`/`NoiDung`) lẫn tên mới — giữ nguyên ở đây vì
 * có thể còn caller admin cũ gửi tên cũ, và spec yêu cầu giữ nguyên hành vi.
 */
const normalizeLessonBody = (body) => {
  if (body === null || typeof body !== 'object') return body;
  return {
    title: body.title ?? body.TenBaiHoc,
    level: body.level ?? body.CapDo,
    order: body.order,
    description: body.description ?? body.LoaiBaiHoc,
    content_html: body.content_html ?? body.NoiDung,
    type: body.type,
    situation: body.situation,
  };
};

export const listQuery = paginationQuery.extend({
  level: optional(level),
  type: optional(z.string().trim().min(1)),
  situation: optional(situation),
  search: optional(z.string().trim().min(1)),
});

export const situationsQuery = z.object({
  level: optional(level),
});

export const idParams = z.object({ id: objectId });

export const capDoParams = z.object({ capDo: level });

export const loaiBaiHocParams = z.object({
  loaiBaiHoc: z.string().trim().min(1),
});

export const createBody = z.preprocess(
  normalizeLessonBody,
  z.object({
    title: z.string().trim().min(1, 'Tên bài học là bắt buộc.'),
    level,
    order: z.coerce.number().int().min(1).default(1),
    description: z.string().trim().optional(),
    content_html: z.string().optional(),
    type: z.string().trim().optional(),
    situation: situation.optional(),
  }),
);

export const updateBody = z.preprocess(
  normalizeLessonBody,
  z.object({
    title: z.string().trim().min(1).optional(),
    level: level.optional(),
    order: z.coerce.number().int().min(1).optional(),
    description: z.string().trim().optional(),
    content_html: z.string().optional(),
    type: z.string().trim().optional(),
    situation: situation.optional(),
  }),
);

export const bulkBody = z.object({
  lessons: z
    .array(createBody)
    .min(1, 'Danh sách phải có từ 1 đến 100 bài học.')
    .max(100, 'Danh sách phải có từ 1 đến 100 bài học.'),
});

export const idsBody = z.object({
  ids: z
    .array(objectId)
    .min(1, 'Danh sách ID phải có từ 1 đến 100 phần tử.')
    .max(100, 'Danh sách ID phải có từ 1 đến 100 phần tử.'),
});
