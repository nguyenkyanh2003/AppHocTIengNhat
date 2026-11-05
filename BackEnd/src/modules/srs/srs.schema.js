import { z } from 'zod';

import { ITEM_TYPES } from './srs-scheduling.js';

/**
 * Schema của sáu route SRS (spec SRS §3.3–3.4, §6; spec Kanji SRS §2).
 *
 * `item_type` nhận đúng `Vocabulary` hoặc `Kanji`; `Grammar` hay sai chữ hoa
 * đều bị từ chối. Đọc danh sách (đến hạn, đếm, thống kê) bỏ trống loại là mọi
 * loại; thao tác trên một thẻ bỏ trống vẫn là `Vocabulary` để client cũ chạy
 * tiếp. Mọi object đều `strict`: tham số lạ là 400, không bị lờ đi.
 */

/** Trần số thẻ loại trừ trong một phiên ôn — giới hạn chọn cho mốc 1 (spec §3.4). */
export const MAX_EXCLUDED_CARDS = 200;

const objectId = z.string().regex(/^[a-f0-9]{24}$/i, 'ID không hợp lệ.');

/** Loại của **một** thẻ. */
const itemType = z.enum(ITEM_TYPES).default('Vocabulary');

/** Bộ lọc danh sách: không truyền thì không lọc. */
const itemTypeFilter = z.enum(ITEM_TYPES).optional();

/**
 * Giá trị `next_review` nguyên vẹn của thẻ đang thấy, không phải giờ client
 * tự tính. Nó là điều kiện so khớp lịch để một request cũ gửi lại muộn không
 * áp vào kỳ ôn mới (spec §3.3).
 */
const expectedNextReview = z.iso.datetime().transform((value) => new Date(value));

const excludedCardIds = z
  .string()
  .transform((value) => [...new Set(value.split(',').map((id) => id.trim()).filter(Boolean))])
  .pipe(z.array(objectId).max(MAX_EXCLUDED_CARDS));

export const itemTypeQuery = z.strictObject({ item_type: itemTypeFilter });

/** Query của lệnh xoá một thẻ. */
export const cardTypeQuery = z.strictObject({ item_type: itemType });

export const dueQuery = z.strictObject({
  item_type: itemTypeFilter,
  limit: z.coerce.number().int().min(1).max(100).default(20),
  exclude_card_ids: excludedCardIds.optional(),
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
