import { z } from 'zod';

import { paginationQuery } from '../../shared/http/pagination.js';
import { jlptLevel, objectId, optionalQuery } from '../../shared/http/schemas.js';

const required = (label) => z.string().trim().min(1, `Vui lòng nhập ${label}.`);
const readings = z.array(z.string().trim().min(1)).max(20);

const example = z.object({
  word: required('từ ví dụ'),
  hiragana: required('cách đọc của từ ví dụ'),
  meaning: required('nghĩa của từ ví dụ'),
});
const examples = z.array(example).max(20, 'Tối đa 20 ví dụ.');

/** Ô bài học bỏ trống khi sửa nghĩa là gỡ chữ khỏi bài. */
const lessonRef = z.preprocess((value) => (value === '' ? null : value), objectId.nullable());

export const idParams = z.object({ id: objectId });

export const listQuery = paginationQuery.extend({ level: optionalQuery(jlptLevel) });

export const searchQuery = z.object({
  keyword: z.string().trim().min(1, 'Vui lòng nhập từ khóa tìm kiếm.').max(50),
  level: optionalQuery(jlptLevel),
});

/** Tên trường giữ như form và file CSV của màn quản trị đang gửi (`lessonId`, `strokeOrderImage`). */
export const createBody = z.object({
  character: required('chữ Kanji').max(10),
  meaning: required('nghĩa'),
  level: jlptLevel,
  lessonId: objectId,
  hanviet: z.string().trim().max(50).optional(),
  onyomi: readings.default([]),
  kunyomi: readings.default([]),
  strokeOrderImage: z.string().trim().max(500).optional(),
  examples: examples.default([]),
});

/** Sửa chỉ ghi trường được gửi, nên không có `.default()` ở đây. */
export const updateBody = z
  .object({
    character: required('chữ Kanji').max(10).optional(),
    meaning: required('nghĩa').optional(),
    level: jlptLevel.optional(),
    lessonId: lessonRef.optional(),
    hanviet: z.string().trim().max(50).optional(),
    onyomi: readings.optional(),
    kunyomi: readings.optional(),
    strokeOrderImage: z.string().trim().max(500).optional(),
    examples: examples.optional(),
  })
  .refine((changes) => Object.keys(changes).length > 0, 'Không có gì để cập nhật.');
