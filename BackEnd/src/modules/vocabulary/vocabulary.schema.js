import { z } from 'zod';

import { paginationQuery } from '../../shared/http/pagination.js';

const objectId = z
  .string()
  .regex(/^[0-9a-fA-F]{24}$/, 'Định danh không hợp lệ.');

const level = z.enum(['N5', 'N4', 'N3', 'N2', 'N1']);

/** Query rỗng (`?level=`) được coi như không truyền. */
const optional = (schema) =>
  z.preprocess(
    (value) => (value === '' || value === null ? undefined : value),
    schema.optional(),
  );

const example = z.object({
  sentence: z.string().optional(),
  meaning: z.string().optional(),
  audio_url: z.string().optional(),
});

export const listQuery = paginationQuery.extend({
  level: optional(level),
  studyStatus: optional(z.enum(['learned', 'unlearned'])),
  sortBy: optional(z.enum(['alphabet', 'difficulty', 'newest'])),
});

export const searchQuery = z.object({
  keyword: z.string().trim().min(1, 'Vui lòng nhập từ khóa tìm kiếm.'),
  level: optional(level),
});

export const situationSearchQuery = z.object({
  q: z.string().trim().min(1, 'Vui lòng nhập tên tình huống muốn tìm.'),
});

export const randomPracticeQuery = z.object({
  limit: z.coerce.number().int().min(1).max(100).default(10),
  level: optional(level),
});

export const exportQuery = z.object({
  level: optional(level),
  lesson: optional(objectId),
});

export const idParams = z.object({ id: objectId });

export const lessonIdParams = z.object({ lessonId: objectId });

export const levelParams = z.object({ levelEnum: level });

export const learnBody = z.object({
  lessonId: objectId,
});

export const createBody = z.object({
  lesson: objectId,
  word: z.string().trim().min(1),
  hiragana: z.string().trim().min(1),
  meaning: z.string().trim().min(1),
  level,
  usage_context: z.string().trim().nullish(),
  audio_url: z.string().nullish(),
  image_url: z.string().nullish(),
  examples: z.array(example).default([]),
  related_kanjis: z.array(objectId).default([]),
});

/**
 * Update chỉ ghi đè field được gửi lên, nên không dùng `.default()` ở đây:
 * default sẽ biến một update một field thành ghi đè cả `examples`.
 */
export const updateBody = z.object({
  lesson: objectId.optional(),
  word: z.string().trim().min(1).optional(),
  hiragana: z.string().trim().min(1).optional(),
  meaning: z.string().trim().min(1).optional(),
  level: level.optional(),
  usage_context: z.string().trim().nullish(),
  audio_url: z.string().nullish(),
  image_url: z.string().nullish(),
  examples: z.array(example).optional(),
  related_kanjis: z.array(objectId).optional(),
});

export const deleteManyBody = z.object({
  ids: z.array(objectId).min(1, 'Danh sách ID không hợp lệ.'),
});

export const uploadBody = z.object({
  lesson: objectId,
  level,
});
