import { z } from 'zod';
import { jlptLevel, objectId } from '../../shared/http/schemas.js';

export const ITEM_TYPES = ['vocabulary', 'grammar', 'kanji'];

export const lessonIdParams = z.object({ lessonId: objectId });

export const levelParams = z.object({
  level: jlptLevel,
});

/**
 * `completed` phải là boolean thật.
 *
 * Bản cũ đọc `req.body.completed` theo kiểu truthy, nên chuỗi `"false"` được
 * hiểu là đã học. `item_id` được kiểm tra định dạng ở đây; việc ID có thuộc
 * đúng bài học hay không là rule nghiệp vụ và nằm ở service.
 */
export const updateBody = z.object({
  item_type: z.enum(ITEM_TYPES),
  item_id: objectId,
  completed: z.boolean(),
});
