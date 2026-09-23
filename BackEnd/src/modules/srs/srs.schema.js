import { z } from 'zod';

/**
 * Schema của sáu route SRS (spec SRS §3.3–3.4, §6).
 *
 * Mốc 1 chỉ nghiệm thu Vocabulary: `item_type` chỉ nhận đúng `Vocabulary`
 * (không truyền thì mặc định giá trị này); `Kanji`, `Grammar` hay sai chữ hoa
 * đều bị từ chối. Mọi object đều `strict`: tham số lạ là 400, không bị lờ đi.
 */

/** Trần số thẻ loại trừ trong một phiên ôn — giới hạn chọn cho mốc 1 (spec §3.4). */
export const MAX_EXCLUDED_ITEMS = 200;

const objectId = z.string().regex(/^[a-f0-9]{24}$/i, 'ID không hợp lệ.');

const itemType = z.literal('Vocabulary').default('Vocabulary');

/**
 * Giá trị `next_review` nguyên vẹn của thẻ đang thấy, không phải giờ client
 * tự tính. Nó là điều kiện so khớp lịch để một request cũ gửi lại muộn không
 * áp vào kỳ ôn mới (spec §3.3).
 */
const expectedNextReview = z.iso.datetime().transform((value) => new Date(value));

const excludedItemIds = z
  .string()
  .transform((value) => [...new Set(value.split(',').map((id) => id.trim()).filter(Boolean))])
  .pipe(z.array(objectId).max(MAX_EXCLUDED_ITEMS));

export const itemTypeQuery = z.strictObject({ item_type: itemType });

export const dueQuery = z.strictObject({
  item_type: itemType,
  limit: z.coerce.number().int().min(1).max(100).default(20),
  exclude_item_ids: excludedItemIds.optional(),
});

export const reviewBody = z.strictObject({
  item_id: objectId,
  item_type: itemType,
  is_correct: z.boolean(),
  expected_next_review: expectedNextReview,
});

export const itemParams = z.strictObject({ itemId: objectId });

export const resetBody = z.strictObject({
  item_type: itemType,
  expected_next_review: expectedNextReview,
});
