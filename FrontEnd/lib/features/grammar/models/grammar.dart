class Grammar {
  final String id;
  final String title;
  final String pattern;
  final String meaning;
  final String? explanation;
  final List<String> examples;
  final String level; // N5, N4, N3, N2, N1
  final String? lessonId;
  final int viewCount;
  final DateTime createdAt;
  final bool isActive;

  Grammar({
    required this.id,
    required this.title,
    required this.pattern,
    required this.meaning,
    this.explanation,
    this.examples = const [],
    required this.level,
    this.lessonId,
    this.viewCount = 0,
    required this.createdAt,
    this.isActive = true,
  });

  factory Grammar.fromJson(Map<String, dynamic> json) {
    return Grammar(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? json['tieu_de'] ?? '',
      pattern: json['pattern'] ?? json['co_cau'] ?? '',
      meaning: json['meaning'] ?? json['y_nghia'] ?? '',
      explanation: json['explanation'] ?? json['giai_thich'],
      examples: json['examples'] != null
          ? List<String>.from(json['examples'])
          : json['example'] != null
              ? [json['example']]
              : [],
      level: json['level'] ?? 'N5',
      lessonId: json['lesson_id'] ?? json['bai_hoc'],
      viewCount: json['view_count'] ?? json['luot_xem'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      isActive: json['is_active'] ?? json['hoat_dong'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'pattern': pattern,
      'meaning': meaning,
      'explanation': explanation,
      'examples': examples,
      'level': level,
      'lesson_id': lessonId,
      'view_count': viewCount,
      'createdAt': createdAt.toIso8601String(),
      'is_active': isActive,
    };
  }

  Grammar copyWith({
    String? id,
    String? title,
    String? pattern,
    String? meaning,
    String? explanation,
    List<String>? examples,
    String? level,
    String? lessonId,
    int? viewCount,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return Grammar(
      id: id ?? this.id,
      title: title ?? this.title,
      pattern: pattern ?? this.pattern,
      meaning: meaning ?? this.meaning,
      explanation: explanation ?? this.explanation,
      examples: examples ?? this.examples,
      level: level ?? this.level,
      lessonId: lessonId ?? this.lessonId,
      viewCount: viewCount ?? this.viewCount,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
