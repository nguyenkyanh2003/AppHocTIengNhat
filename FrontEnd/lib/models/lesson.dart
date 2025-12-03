class Lesson {
  final String id;
  final String title;
  final String level;
  final int order;
  final String? description;
  final String? contentHtml;
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
    this.vocabularies = const [],
    this.grammars = const [],
    this.kanjis = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      level: json['level'] ?? 'N5',
      order: json['order'] ?? 1,
      description: json['description'],
      contentHtml: json['content_html'],
      vocabularies: json['vocabularies'] != null 
          ? List<String>.from(json['vocabularies'])
          : [],
      grammars: json['grammars'] != null 
          ? List<String>.from(json['grammars'])
          : [],
      kanjis: json['kanjis'] != null 
          ? List<String>.from(json['kanjis'])
          : [],
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
    return LessonDetail(
      lesson: Lesson.fromJson(json),
      vocabularies: json['tuvungs'] != null
          ? List<Map<String, dynamic>>.from(
              (json['tuvungs'] as List).map((item) => item as Map<String, dynamic>))
          : [],
      kanjis: json['kanjis'] != null
          ? List<Map<String, dynamic>>.from(
              (json['kanjis'] as List).map((item) => item as Map<String, dynamic>))
          : [],
      grammars: json['nguphaps'] != null
          ? List<Map<String, dynamic>>.from(
              (json['nguphaps'] as List).map((item) => item as Map<String, dynamic>))
          : [],
    );
  }
}
