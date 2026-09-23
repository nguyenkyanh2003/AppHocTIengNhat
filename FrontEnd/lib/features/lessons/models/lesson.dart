import 'dialogue_turn.dart';
import 'lesson_video.dart';

class Lesson {
  final String id;
  final String title;
  final String level;
  final int order;
  final String? description;
  final String? contentHtml;

  /// Tình huống thực tế của bài (`supermarket`, `train`...); `null` với bài
  /// ngữ pháp thuần.
  final String? situation;

  /// Hội thoại của bài tình huống; rỗng với bài chỉ có `contentHtml`.
  final List<DialogueTurn> dialogue;

  /// Mục tiêu "sau bài này làm được gì".
  final List<String> canDoGoals;

  /// Video của bài kèm lời thoại; rỗng với bài chưa có video.
  final List<LessonVideo> videos;

  final List<String> vocabularies;
  final List<String> grammars;
  final List<String> kanjis;
  final DateTime createdAt;
  final DateTime updatedAt;

  Lesson({
    required this.id,
    required this.title,
    required this.level,
    this.order = 1,
    this.description,
    this.contentHtml,
    this.situation,
    this.dialogue = const [],
    this.canDoGoals = const [],
    this.videos = const [],
    this.vocabularies = const [],
    this.grammars = const [],
    this.kanjis = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  /// Bài có nội dung dạng hội thoại tình huống hay không.
  bool get isSituational => dialogue.isNotEmpty;

  factory Lesson.fromJson(Map<String, dynamic> json) {
    // Helper function để extract ID từ item (có thể là String hoặc Map)
    List<String> extractIds(dynamic items) {
      if (items == null) return [];
      if (items is List) {
        return items
            .map((item) {
              if (item is String) return item;
              if (item is Map) return item['_id']?.toString() ?? '';
              return '';
            })
            .where((id) => id.isNotEmpty)
            .toList();
      }
      return [];
    }

    return Lesson(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      level: json['level'] ?? 'N5',
      order: json['order'] ?? 1,
      description: json['description'],
      contentHtml: json['content_html'],
      situation: json['situation']?.toString(),
      dialogue: DialogueTurn.listFromJson(json['dialogue']),
      videos: LessonVideo.listFromJson(json['videos']),
      canDoGoals: (json['can_do_goals'] is List)
          ? (json['can_do_goals'] as List)
              .map((goal) => goal.toString())
              .where((goal) => goal.isNotEmpty)
              .toList()
          : const [],
      vocabularies: extractIds(json['vocabularies']),
      grammars: extractIds(json['grammars']),
      kanjis: extractIds(json['kanjis']),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'level': level,
      'order': order,
      'description': description,
      'content_html': contentHtml,
      'situation': situation,
      'dialogue': dialogue.map((turn) => turn.toJson()).toList(),
      'can_do_goals': canDoGoals,
      'vocabularies': vocabularies,
      'grammars': grammars,
      'kanjis': kanjis,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  String getLevelColor() {
    switch (level) {
      case 'N1':
        return '#D32F2F'; // Red
      case 'N2':
        return '#F57C00'; // Orange
      case 'N3':
        return '#FBC02D'; // Yellow
      case 'N4':
        return '#388E3C'; // Green
      case 'N5':
        return '#1976D2'; // Blue
      default:
        return '#757575'; // Grey
    }
  }

  String getLevelName() {
    switch (level) {
      case 'N1':
        return 'N1 - Cao cấp';
      case 'N2':
        return 'N2 - Trung cấp nâng cao';
      case 'N3':
        return 'N3 - Trung cấp';
      case 'N4':
        return 'N4 - Sơ cấp nâng cao';
      case 'N5':
        return 'N5 - Sơ cấp';
      default:
        return level;
    }
  }

  Lesson copyWith({
    String? id,
    String? title,
    String? level,
    int? order,
    String? description,
    String? contentHtml,
    String? situation,
    List<DialogueTurn>? dialogue,
    List<String>? canDoGoals,
    List<String>? vocabularies,
    List<String>? grammars,
    List<String>? kanjis,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Lesson(
      id: id ?? this.id,
      title: title ?? this.title,
      level: level ?? this.level,
      order: order ?? this.order,
      description: description ?? this.description,
      contentHtml: contentHtml ?? this.contentHtml,
      situation: situation ?? this.situation,
      dialogue: dialogue ?? this.dialogue,
      canDoGoals: canDoGoals ?? this.canDoGoals,
      vocabularies: vocabularies ?? this.vocabularies,
      grammars: grammars ?? this.grammars,
      kanjis: kanjis ?? this.kanjis,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class LessonDetail {
  final Lesson lesson;
  final List<Map<String, dynamic>> vocabularies;
  final List<Map<String, dynamic>> kanjis;
  final List<Map<String, dynamic>> grammars;

  LessonDetail({
    required this.lesson,
    required this.vocabularies,
    required this.kanjis,
    required this.grammars,
  });

  factory LessonDetail.fromJson(Map<String, dynamic> json) {
    // Helper function để convert list an toàn
    List<Map<String, dynamic>> safeListConvert(dynamic data) {
      if (data == null) return [];
      if (data is! List) return [];
      return data
          .where((item) => item != null && item is Map)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    }

    return LessonDetail(
      lesson: Lesson.fromJson(json),
      // API trả về 'tuvungs' cho từ vựng đã populate
      // Hoặc có thể là 'vocabularies' nếu là full objects
      vocabularies: safeListConvert(json['tuvungs']).isNotEmpty
          ? safeListConvert(json['tuvungs'])
          : safeListConvert(json['vocabularies']),
      // Tương tự cho kanjis và grammars
      kanjis: safeListConvert(json['kanjis']),
      grammars: safeListConvert(json['nguphaps']).isNotEmpty
          ? safeListConvert(json['nguphaps'])
          : safeListConvert(json['grammars']),
    );
  }
}
