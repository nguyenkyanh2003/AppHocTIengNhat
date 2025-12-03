class LessonProgress {
  final String id;
  final String userId;
  final String lessonId;
  final int completedVocabularies;
  final int totalVocabularies;
  final int completedGrammars;
  final int totalGrammars;
  final int completedKanjis;
  final int totalKanjis;
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime lastStudiedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  LessonProgress({
    required this.id,
    required this.userId,
    required this.lessonId,
    this.completedVocabularies = 0,
    this.totalVocabularies = 0,
    this.completedGrammars = 0,
    this.totalGrammars = 0,
    this.completedKanjis = 0,
    this.totalKanjis = 0,
    this.isCompleted = false,
    this.completedAt,
    required this.lastStudiedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LessonProgress.fromJson(Map<String, dynamic> json) {
    return LessonProgress(
      id: json['_id'] ?? '',
      userId: json['user_id'] ?? json['user'] ?? '',
      lessonId: json['lesson_id'] ?? json['lesson'] ?? '',
      completedVocabularies: json['completed_vocabularies'] ?? 0,
      totalVocabularies: json['total_vocabularies'] ?? 0,
      completedGrammars: json['completed_grammars'] ?? 0,
      totalGrammars: json['total_grammars'] ?? 0,
      completedKanjis: json['completed_kanjis'] ?? 0,
      totalKanjis: json['total_kanjis'] ?? 0,
      isCompleted: json['is_completed'] ?? false,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      lastStudiedAt: json['last_studied_at'] != null
          ? DateTime.parse(json['last_studied_at'])
          : DateTime.now(),
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
      'user_id': userId,
      'lesson_id': lessonId,
      'completed_vocabularies': completedVocabularies,
      'total_vocabularies': totalVocabularies,
      'completed_grammars': completedGrammars,
      'total_grammars': totalGrammars,
      'completed_kanjis': completedKanjis,
      'total_kanjis': totalKanjis,
      'is_completed': isCompleted,
      'completed_at': completedAt?.toIso8601String(),
      'last_studied_at': lastStudiedAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Tính phần trăm hoàn thành tổng thể
  double get overallProgress {
    final total = totalVocabularies + totalGrammars + totalKanjis;
    if (total == 0) return 0.0;
    final completed = completedVocabularies + completedGrammars + completedKanjis;
    return (completed / total).clamp(0.0, 1.0);
  }

  // Tính phần trăm từ vựng
  double get vocabularyProgress {
    if (totalVocabularies == 0) return 0.0;
    return (completedVocabularies / totalVocabularies).clamp(0.0, 1.0);
  }

  // Tính phần trăm ngữ pháp
  double get grammarProgress {
    if (totalGrammars == 0) return 0.0;
    return (completedGrammars / totalGrammars).clamp(0.0, 1.0);
  }

  // Tính phần trăm kanji
  double get kanjiProgress {
    if (totalKanjis == 0) return 0.0;
    return (completedKanjis / totalKanjis).clamp(0.0, 1.0);
  }

  // Copy với thay đổi
  LessonProgress copyWith({
    String? id,
    String? userId,
    String? lessonId,
    int? completedVocabularies,
    int? totalVocabularies,
    int? completedGrammars,
    int? totalGrammars,
    int? completedKanjis,
    int? totalKanjis,
    bool? isCompleted,
    DateTime? completedAt,
    DateTime? lastStudiedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LessonProgress(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      lessonId: lessonId ?? this.lessonId,
      completedVocabularies: completedVocabularies ?? this.completedVocabularies,
      totalVocabularies: totalVocabularies ?? this.totalVocabularies,
      completedGrammars: completedGrammars ?? this.completedGrammars,
      totalGrammars: totalGrammars ?? this.totalGrammars,
      completedKanjis: completedKanjis ?? this.completedKanjis,
      totalKanjis: totalKanjis ?? this.totalKanjis,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      lastStudiedAt: lastStudiedAt ?? this.lastStudiedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
