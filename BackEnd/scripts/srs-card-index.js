/**
 * Khoá định danh một thẻ ôn: (user, loại, nội dung) — spec Kanji SRS §2 (#6).
 *
 * Khoá cũ `(user, item_id)` không biết loại thẻ. Nó chặt hơn khoá mới, nên dữ
 * liệu đang hợp lệ với khoá cũ không thể trùng theo khoá mới: chuyển index chỉ
 * cần đúng thứ tự — tạo khoá mới trước, xoá khoá cũ sau, để không có lúc nào
 * collection thiếu ràng buộc unique.
 */
export const SRS_COLLECTION = 'srsprogresses';

export const CARD_KEY = Object.freeze({
  name: 'srs_card_key',
  key: Object.freeze({ user: 1, item_type: 1, item_id: 1 }),
});

export const LEGACY_KEY = Object.freeze({ user: 1, item_id: 1 });

/** So cả **thứ tự** trường: `(user, item_id, item_type)` là một index khác. */
const sameKey = (a, b) => JSON.stringify(Object.entries(a)) === JSON.stringify(Object.entries(b));

/** Việc cần làm với index của thẻ ôn, tính từ danh sách index đang có trong DB. */
export const planCardIndex = (indexes) => ({
  create: !indexes.some((index) => index.unique === true && sameKey(index.key, CARD_KEY.key)),
  drop: indexes.filter((index) => sameKey(index.key, LEGACY_KEY)).map((index) => index.name),
});
