import { z } from 'zod';

import { paginationQuery } from '../../shared/http/pagination.js';
import { JLPT_LEVELS, jlptLevel, objectId, optionalQuery } from '../../shared/http/schemas.js';
import { SITUATIONS } from './situation-catalog.js';

export const LEVELS = JLPT_LEVELS;

const level = jlptLevel;
const situation = z.enum(SITUATIONS);

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
  level: optionalQuery(level),
  type: optionalQuery(z.string().trim().min(1)),
  situation: optionalQuery(situation),
  search: optionalQuery(z.string().trim().min(1)),
});

export const situationsQuery = z.object({
  level: optionalQuery(level),
});

export const idParams = z.object({ id: objectId });

export const capDoParams = z.object({ capDo: level });

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

export const idsBody = z.object({
  ids: z
    .array(objectId)
    .min(1, 'Danh sách ID phải có từ 1 đến 100 phần tử.')
    .max(100, 'Danh sách ID phải có từ 1 đến 100 phần tử.'),
});
