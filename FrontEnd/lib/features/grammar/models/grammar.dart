/// Cách sắp xếp danh sách ngữ pháp; `name` là giá trị `sortBy` gửi lên API.
enum GrammarSort { title, popular, newest }

class Grammar {
  const Grammar({
    required this.id,
    required this.title,
    required this.pattern,
    required this.meaning,
    required this.level,
    this.explanation,
    this.examples = const [],
    this.lessonId,
    this.viewCount = 0,
  });

  factory Grammar.fromJson(Map<String, dynamic> json) {
    return Grammar(
      id: json['_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      pattern: json['structure'] as String? ?? '',
      meaning: json['meaning'] as String? ?? '',
      level: json['level'] as String? ?? 'N5',
      explanation: json['usage'] as String?,
      examples: json['examples'] is List ? _examplesFrom(json['examples'] as List) : const [],
      lessonId: _idOf(json['lesson_id']),
      viewCount: json['view_count'] as int? ?? 0,
    );
  }

  final String id;
  final String title;

  /// Cấu trúc câu, trường `structure` của API.
  final String pattern;
  final String meaning;

  /// Cách dùng, trường `usage` của API.
  final String? explanation;
  final List<String> examples;
  final String level;
  final String? lessonId;
  final int viewCount;

  /// Bài học đến dạng id hoặc object đã populate `{ _id, title, level }`.
  static String? _idOf(Object? value) => value is Map ? value['_id'] as String? : value as String?;

  /// API trả ví dụ dạng `{ sentence, meaning }`; dữ liệu cũ có thể là chuỗi.
  static List<String> _examplesFrom(List<dynamic> raw) => raw
      .map((example) => example is Map
          ? [example['sentence'], example['meaning']]
              .whereType<String>()
              .where((part) => part.trim().isNotEmpty)
              .join('\n')
          : example.toString())
      .where((example) => example.trim().isNotEmpty)
      .toList();
}
