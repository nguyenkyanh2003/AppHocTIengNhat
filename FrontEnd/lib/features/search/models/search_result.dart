/// Nhóm nội dung của một kết quả tìm kiếm, theo thứ tự server trả về.
enum SearchResultType {
  vocabulary('vocabulary', 'Từ vựng'),
  kanji('kanji', 'Kanji'),
  lesson('lesson', 'Bài học'),
  grammar('grammar', 'Ngữ pháp'),
  news('news', 'Tin tức');

  const SearchResultType(this.key, this.label);

  /// Giá trị `type` trong response.
  final String key;
  final String label;

  static SearchResultType? fromKey(Object? key) {
    for (final type in values) {
      if (type.key == key) return type;
    }
    return null;
  }
}

/// Một kết quả của `GET /search` — cùng một dạng cho mọi nhóm, server đã chọn
/// sẵn trường nào làm tiêu đề (chữ Kanji, từ vựng, tên bài...).
class SearchResult {
  const SearchResult({
    required this.id,
    required this.type,
    required this.title,
    this.subtitle,
    this.description,
    this.imageUrl,
    this.level,
  });

  final String id;
  final SearchResultType type;
  final String title;
  final String? subtitle;
  final String? description;
  final String? imageUrl;
  final String? level;

  /// `null` khi thiếu id hoặc thuộc nhóm app chưa biết (server mới hơn app):
  /// bỏ qua thay vì hiện một dòng bấm vào không mở được gì.
  static SearchResult? tryParse(Map<String, dynamic> json) {
    final type = SearchResultType.fromKey(json['type']);
    final id = json['id'];
    if (type == null || id is! String || id.isEmpty) return null;

    return SearchResult(
      id: id,
      type: type,
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String?,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      level: json['level'] as String?,
    );
  }

  static List<SearchResult> listFromJson(dynamic data) => (data as List? ?? const [])
      .whereType<Map>()
      .map((item) => tryParse(Map<String, dynamic>.from(item)))
      .whereType<SearchResult>()
      .toList();
}
