import 'vocabulary.dart';

/// Một bộ học khoảng 20 từ, do backend chia sẵn.
///
/// N5–N4 chia theo chủ đề ("Ăn uống"), N3–N1 chia theo từ loại và độ khó
/// ("Cơ bản" · "Động từ"). Bộ không lưu trong DB mà được tính từ nhãn của
/// từ, nên [id] là mã đọc được như `N5.food.1`, không phải ObjectId.
class VocabularySet {
  const VocabularySet({
    required this.id,
    required this.level,
    required this.title,
    required this.part,
    required this.partCount,
    required this.wordCount,
    required this.learnedCount,
    this.section,
  });

  factory VocabularySet.fromJson(Map<String, dynamic> json) {
    return VocabularySet(
      id: json['id'] as String,
      level: json['level'] as String? ?? '',
      title: json['title'] as String? ?? '',
      section: json['section'] as String?,
      part: json['part'] as int? ?? 1,
      partCount: json['partCount'] as int? ?? 1,
      wordCount: json['wordCount'] as int? ?? 0,
      learnedCount: json['learnedCount'] as int? ?? 0,
    );
  }

  final String id;
  final String level;

  /// Chủ đề (N5–N4) hoặc từ loại (N3–N1).
  final String title;

  /// Mức độ khó ở N3–N1 ("Cơ bản", ...); `null` ở cấp chia theo chủ đề.
  final String? section;

  final int part;
  final int partCount;
  final int wordCount;
  final int learnedCount;

  /// "Ăn uống" hoặc "Ăn uống · Phần 2/4" khi chủ đề được chia nhiều bộ.
  String get displayTitle =>
      partCount > 1 ? '$title · Phần $part/$partCount' : title;

  double get progress => wordCount == 0 ? 0 : learnedCount / wordCount;

  bool get isCompleted => wordCount > 0 && learnedCount >= wordCount;
}

/// Một bộ kèm danh sách từ, theo thứ tự học.
class VocabularySetDetail {
  const VocabularySetDetail({required this.set, required this.words});

  factory VocabularySetDetail.fromJson(Map<String, dynamic> json) {
    return VocabularySetDetail(
      set: VocabularySet.fromJson(json),
      words: (json['words'] as List? ?? const [])
          .map((item) => Vocabulary.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }

  final VocabularySet set;
  final List<Vocabulary> words;
}
