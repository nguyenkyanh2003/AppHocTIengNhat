import { z } from 'zod';

import { paginationQuery } from '../../shared/http/pagination.js';
import { jlptLevel, objectId, optionalQuery } from '../../shared/http/schemas.js';
import { SET_ID_PATTERN } from './vocabulary-sets.js';

const level = jlptLevel;

const example = z.object({
  sentence: z.string().optional(),
  meaning: z.string().optional(),
  audio_url: z.string().optional(),
});

export const listQuery = paginationQuery.extend({
  level: optionalQuery(level),
  studyStatus: optionalQuery(z.enum(['learned', 'unlearned'])),
  sortBy: optionalQuery(z.enum(['alphabet', 'difficulty', 'newest'])),
});

export const searchQuery = z.object({
  keyword: z.string().trim().min(1, 'Vui lòng nhập từ khóa tìm kiếm.'),
  level: optionalQuery(level),
});

export const idParams = z.object({ id: objectId });

export const setListQuery = z.object({ level });

export const setIdParams = z.object({
  setId: z.string().regex(SET_ID_PATTERN, 'Mã bộ từ vựng không hợp lệ.'),
});

export const lessonIdParams = z.object({ lessonId: objectId });

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
