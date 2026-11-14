import { z } from 'zod';

/**
 * Schema zod dùng chung giữa các module.
 *
 * Một schema chỉ chuyển về đây khi đã xuất hiện ở module thứ hai — để cùng một
 * loại dữ liệu sai luôn nhận cùng một câu báo lỗi, dù gọi endpoint nào.
 */

/** `_id` của MongoDB: 24 ký tự hex. Câu báo khớp với lỗi `CastError` trong `error.middleware.js`. */
export const objectId = z.string().regex(/^[a-f0-9]{24}$/i, 'Định danh không hợp lệ.');

/** Cấp độ JLPT, khớp enum `level` của các model nội dung. */
export const JLPT_LEVELS = Object.freeze(['N5', 'N4', 'N3', 'N2', 'N1']);

export const jlptLevel = z.enum(JLPT_LEVELS);

/**
 * Tham số query không bắt buộc. Ô bỏ trống (`?level=`) được coi như không
 * truyền, vì form và bộ lọc phía client thường gửi chuỗi rỗng cho "tất cả".
 */
export const optionalQuery = (schema) =>
  z.preprocess((value) => (value === '' || value === null ? undefined : value), schema.optional());
