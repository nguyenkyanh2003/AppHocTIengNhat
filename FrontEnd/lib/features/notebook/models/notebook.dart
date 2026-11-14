import '../../../core/network/api_envelope.dart';

/// Loại ghi chú; [name] là giá trị server lưu (enum `type` của model `Notebook`).
enum NoteType {
  general('Chung'),
  vocabulary('Từ vựng'),
  grammar('Ngữ pháp'),
  kanji('Kanji'),
  lesson('Bài học');

  const NoteType(this.label);

  final String label;

  /// Giá trị lạ (dữ liệu cũ) đọc thành ghi chú chung thay vì làm hỏng cả danh sách.
  static NoteType fromName(Object? name) => values.firstWhere((type) => type.name == name, orElse: () => general);
}

/// Một ghi chú trong sổ tay của người đang đăng nhập.
class Notebook {
  const Notebook({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String content;
  final NoteType type;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Notebook.fromJson(JsonObject json) {
    final createdAt = _dateOf(json['createdAt']) ?? DateTime.now();
    return Notebook(
      id: json['_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      type: NoteType.fromName(json['type']),
      tags: [for (final tag in json['tags'] as List? ?? const []) '$tag'],
      createdAt: createdAt,
      updatedAt: _dateOf(json['updatedAt']) ?? createdAt,
    );
  }

  static DateTime? _dateOf(Object? value) => value is String ? DateTime.tryParse(value) : null;
}

/// Nội dung người dùng nhập ở form; tạo mới và sửa gửi cùng một hình dạng.
class NotebookDraft {
  const NotebookDraft({required this.title, required this.content, this.type = NoteType.general, this.tags = const []});

  final String title;
  final String content;
  final NoteType type;
  final List<String> tags;

  JsonObject toJson() => {'title': title, 'content': content, 'type': type.name, 'tags': tags};
}
