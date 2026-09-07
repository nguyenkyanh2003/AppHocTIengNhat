/**
 * Response contract dùng chung.
 *
 *   một tài nguyên      -> { data }
 *   danh sách           -> { data, total }
 *   danh sách phân trang -> { data, page, limit, total, totalPages }
 *
 * Danh sách rỗng luôn là 200 với mảng rỗng; 404 chỉ dành cho một tài nguyên
 * được định danh cụ thể mà không tồn tại.
 */
export const ok = (res, data, extra = {}) => res.json({ data, ...extra });

export const created = (res, data, extra = {}) =>
  res.status(201).json({ data, ...extra });

export const list = (res, items, extra = {}) =>
  res.json({ data: items, total: items.length, ...extra });

export const paginated = (res, { items, page, limit, total }) =>
  res.json({
    data: items,
    page,
    limit,
    total,
    totalPages: total === 0 ? 0 : Math.ceil(total / limit),
  });
