import { z } from 'zod';

import { paginationQuery } from '../../shared/http/pagination.js';
import { jlptLevel, objectId, optionalQuery } from '../../shared/http/schemas.js';

const required = (label) => z.string().trim().min(1, `Vui lòng nhập ${label}.`);
const text = z.string().trim();

const example = z.object({
  sentence: required('câu ví dụ'),
  meaning: required('nghĩa câu ví dụ'),
  audio_url: text.optional(),
});

/** Ô bài học bỏ trống nghĩa là không gắn bài nào. */
const lessonRef = z.preprocess((value) => (value === '' ? null : value), objectId.nullable());

/** Giới hạn khớp model `Grammar`: tối đa 10 ví dụ, độ khó 1–5. */
const examples = z.array(example).max(10, 'Tối đa 10 ví dụ.');
const difficulty = z.number().int().min(1).max(5);

export const listQuery = paginationQuery.extend({
  level: optionalQuery(jlptLevel),
  search: optionalQuery(text.min(1)),
  sortBy: optionalQuery(z.enum(['title', 'popular', 'newest'])),
});

export const idParams = z.object({ id: objectId });

/** Tên trường giữ như form quản trị và file CSV đang gửi (`lessonID`, `relatedGrammar`). */
export const createBody = z.object({
  title: required('tiêu đề'),
  structure: required('cấu trúc'),
  meaning: required('ý nghĩa'),
  level: jlptLevel,
  usage: text.optional(),
  notes: text.optional(),
  examples: examples.default([]),
  difficulty: difficulty.default(3),
  lessonID: lessonRef.optional(),
  relatedGrammar: z.array(objectId).default([]),
});

/** Sửa chỉ ghi trường được gửi, nên không có `.default()` ở đây. */
export const updateBody = z
  .object({
    title: required('tiêu đề').optional(),
    structure: required('cấu trúc').optional(),
    meaning: required('ý nghĩa').optional(),
    level: jlptLevel.optional(),
    usage: text.optional(),
    notes: text.optional(),
    examples: examples.optional(),
    difficulty: difficulty.optional(),
    lessonID: lessonRef.optional(),
    relatedGrammar: z.array(objectId).optional(),
  })
  .refine((changes) => Object.keys(changes).length > 0, 'Không có gì để cập nhật.');
