import { z } from 'zod';

const objectId = z
  .string()
  .regex(/^[0-9a-fA-F]{24}$/, 'Định danh không hợp lệ.');

export const ITEM_TYPES = ['vocabulary', 'grammar', 'kanji'];

export const lessonIdParams = z.object({ lessonId: objectId });

export const levelParams = z.object({
  level: z.enum(['N5', 'N4', 'N3', 'N2', 'N1']),
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
