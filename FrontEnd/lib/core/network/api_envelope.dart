import 'api_client.dart';

/// Đọc response contract dùng chung của backend:
///
/// ```text
/// một tài nguyên       { data }
/// danh sách            { data, total }
/// danh sách phân trang { data, page, limit, total, totalPages }
/// ```
///
/// Service của feature bóc `data` qua các hàm ở đây thay vì tự viết
/// `response['data']`: response sai hình dạng thành [ServerException] ngay tại
/// chỗ đọc, không lặng lẽ thành danh sách rỗng hay lỗi ép kiểu ở màn hình.

/// JSON nguyên bản, giữ đúng như server trả. Chỉ dùng khi chính JSON là sản
/// phẩm (xuất dữ liệu ra tệp); dữ liệu để hiển thị luôn đi qua model.
typedef JsonObject = Map<String, dynamic>;

/// Nội dung của `data`. Ném [ServerException] nếu response không có khoá `data`.
Object? dataOf(Object? response) {
  if (response is Map && response.containsKey('data')) return response['data'];
  throw ServerException('Máy chủ trả về dữ liệu không đúng định dạng.');
}

/// Một tài nguyên trong `data`.
T objectOf<T>(Object? response, T Function(Map<String, dynamic> json) fromJson) {
  final data = dataOf(response);
  if (data is Map) return fromJson(Map<String, dynamic>.from(data));
  throw ServerException('Máy chủ trả về dữ liệu không đúng định dạng.');
}

/// Danh sách tài nguyên trong `data`.
List<T> listOf<T>(Object? response, T Function(Map<String, dynamic> json) fromJson) {
  final data = dataOf(response);
  if (data is List) {
    return [for (final item in data) fromJson(Map<String, dynamic>.from(item as Map))];
  }
  throw ServerException('Máy chủ trả về dữ liệu không đúng định dạng.');
}

/// Một trang của danh sách phân trang.
class Paged<T> {
  const Paged({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory Paged.fromJson(Object? response, T Function(Map<String, dynamic> json) fromJson) {
    final items = listOf(response, fromJson);
    final json = response as Map;
    return Paged(
      items: items,
      page: json['page'] as int? ?? 1,
      limit: json['limit'] as int? ?? items.length,
      total: json['total'] as int? ?? items.length,
      totalPages: json['totalPages'] as int? ?? 1,
    );
  }

  final List<T> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  bool get hasMore => page < totalPages;
}
