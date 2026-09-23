import '../../srs/models/srs_progress.dart';

class Vocabulary {
  final String id;
  final String word; // Kanji: 学生
  final String hiragana; // Kana: がくせい
  final String meaning; // Nghĩa: Học sinh
  final String? hanviet; // Âm Hán-Việt: HỌC SINH
  final String? level; // N5, N4, N3, N2, N1
  final String? usageContext; // Tình huống sử dụng
  final String? audioUrl;
  final String? imageUrl;
  final String? lessonId;
  final List<VocabExample> examples;
  final List<String> relatedKanjis;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isLearned; // User đã học chưa
  final DateTime? learnedAt; // Thời điểm đánh dấu đã học
  final int? reviewBox; // SRS box level (1-5)

  /// Chỉ có ở API chi tiết: từng chữ Hán của từ kèm âm Hán-Việt và nghĩa.
  final List<KanjiPart> kanjiBreakdown;

  /// Chỉ có ở API chi tiết: từ có chung chữ Hán hoặc cùng chủ đề.
  final List<Vocabulary> relatedWords;

  /// Chỉ có ở API chi tiết: lịch ôn của người dùng, `null` khi chưa học.
  /// Là nguồn `expected_next_review` khi đặt lại lịch ngay tại màn chi tiết.
  final SrsProgress? srsProgress;

  Vocabulary({
    required this.id,
    required this.word,
    required this.hiragana,
    required this.meaning,
    this.hanviet,
    this.level,
    this.usageContext,
    this.audioUrl,
    this.imageUrl,
    this.lessonId,
    this.examples = const [],
    this.relatedKanjis = const [],
    this.createdAt,
    this.updatedAt,
    this.isLearned = false,
    this.learnedAt,
    this.reviewBox,
    this.kanjiBreakdown = const [],
    this.relatedWords = const [],
    this.srsProgress,
  });

  factory Vocabulary.fromJson(Map<String, dynamic> json) {
    return Vocabulary(
      id: json['_id'] ?? '',
      word: json['word'] ?? '',
      hiragana: json['hiragana'] ?? '',
      meaning: json['meaning'] ?? '',
      hanviet: json['hanviet'],
      level: json['level'],
      usageContext: json['usage_context'],
      audioUrl: json['audio_url'],
      imageUrl: json['image_url'],
      lessonId: json['lesson'] is Map ? json['lesson']['_id'] : json['lesson'],
      examples: (json['examples'] as List<dynamic>?)
              ?.map((e) => VocabExample.fromJson(e))
              .toList() ??
          [],
      relatedKanjis: (json['related_kanjis'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      isLearned: json['isLearned'] ?? false,
      learnedAt:
          json['learnedAt'] != null ? DateTime.parse(json['learnedAt']) : null,
      reviewBox: json['reviewBox'],
      kanjiBreakdown: (json['kanjiBreakdown'] as List<dynamic>?)
              ?.map((e) => KanjiPart.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          const [],
      relatedWords: (json['relatedWords'] as List<dynamic>?)
              ?.map((e) => Vocabulary.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          const [],
      srsProgress: json['srs_progress'] is Map
          ? SrsProgress.fromJson(Map<String, dynamic>.from(json['srs_progress']))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'word': word,
      'hiragana': hiragana,
      'meaning': meaning,
      'hanviet': hanviet,
      'level': level,
      'usage_context': usageContext,
      'audio_url': audioUrl,
      'image_url': imageUrl,
      'lesson': lessonId,
      'examples': examples.map((e) => e.toJson()).toList(),
      'related_kanjis': relatedKanjis,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Vocabulary copyWith({
    String? id,
    String? word,
    String? hiragana,
    String? meaning,
    String? hanviet,
    String? level,
    String? usageContext,
    String? audioUrl,
    String? imageUrl,
    String? lessonId,
    List<VocabExample>? examples,
    List<String>? relatedKanjis,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isLearned,
    DateTime? learnedAt,
    int? reviewBox,
  }) {
    return Vocabulary(
      id: id ?? this.id,
      word: word ?? this.word,
      hiragana: hiragana ?? this.hiragana,
      meaning: meaning ?? this.meaning,
      hanviet: hanviet ?? this.hanviet,
      level: level ?? this.level,
      usageContext: usageContext ?? this.usageContext,
      audioUrl: audioUrl ?? this.audioUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      lessonId: lessonId ?? this.lessonId,
      examples: examples ?? this.examples,
      relatedKanjis: relatedKanjis ?? this.relatedKanjis,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isLearned: isLearned ?? this.isLearned,
      learnedAt: learnedAt ?? this.learnedAt,
      reviewBox: reviewBox ?? this.reviewBox,
      kanjiBreakdown: kanjiBreakdown,
      relatedWords: relatedWords,
      srsProgress: srsProgress,
    );
  }
}

class VocabExample {
  final String sentence; // 私は学生です
  final String meaning; // Tôi là học sinh
  final String? audioUrl;

  VocabExample({
    required this.sentence,
    required this.meaning,
    this.audioUrl,
  });

  factory VocabExample.fromJson(Map<String, dynamic> json) {
    return VocabExample(
      sentence: json['sentence'] ?? '',
      meaning: json['meaning'] ?? '',
      audioUrl: json['audio_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sentence': sentence,
      'meaning': meaning,
      'audio_url': audioUrl,
    };
  }
}

/// Một chữ Hán trong từ, dùng cho phần "Phân tích chữ Hán".
class KanjiPart {
  const KanjiPart({
    required this.character,
    this.hanviet,
    this.meaning,
    this.kanjiId,
  });

  factory KanjiPart.fromJson(Map<String, dynamic> json) => KanjiPart(
        character: json['character'] as String? ?? '',
        hanviet: json['hanviet'] as String?,
        meaning: json['meaning'] as String?,
        kanjiId: json['kanjiId'] as String?,
      );

  final String character;

  /// Âm Hán-Việt; `null` khi không ghép được từ dữ liệu.
  final String? hanviet;

  /// Nghĩa riêng của chữ; chỉ có khi chữ đã có trong mục Kanji.
  final String? meaning;

  /// Id trong mục Kanji để mở trang chi tiết chữ; `null` nếu chưa có.
  final String? kanjiId;
}
