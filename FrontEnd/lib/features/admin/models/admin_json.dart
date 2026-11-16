// Đọc các mảnh JSON lặp lại ở nhiều API thống kê của quản trị.

/// Số lượng của nhóm [id] trong kết quả `$group` của MongoDB
/// (`[{ _id, count }]`). Không có nhóm đó là 0.
int groupCount(Object? rows, String id) {
  if (rows is! List) return 0;
  for (final row in rows) {
    if (row is Map && row['_id'] == id) return (row['count'] as num?)?.toInt() ?? 0;
  }
  return 0;
}

/// Ngày server trả (ISO hoặc `YYYY-MM-DD HH:mm:ss` giờ Việt Nam) theo giờ máy.
DateTime? adminDateOf(Object? value) => value == null ? null : DateTime.tryParse('$value')?.toLocal();
