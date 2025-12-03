class Vocabulary {
  final String id;
  final String word;          // Kanji: 学生
  final String hiragana;      // Kana: がくせい
  final String meaning;       // Nghĩa: Học sinh
  final String? level;        // N5, N4, N3, N2, N1
  final String? usageContext; // Tình huống sử dụng
  final String? audioUrl;
  final String? imageUrl;
  final String? lessonId;
  final List<VocabExample> examples;
  final List<String> relatedKanjis;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Vocabulary({
    required this.id,
    required this.word,
    required this.hiragana,
    required this.meaning,
    this.level,
    this.usageContext,
    this.audioUrl,
    this.imageUrl,
    this.lessonId,
    this.examples = const [],
    this.relatedKanjis = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory Vocabulary.fromJson(Map<String, dynamic> json) {
    return Vocabulary(
      id: json['_id'] ?? '',
      word: json['word'] ?? '',
      hiragana: json['hiragana'] ?? '',
      meaning: json['meaning'] ?? '',
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
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'word': word,
      'hiragana': hiragana,
      'meaning': meaning,
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
    String? level,
    String? usageContext,
    String? audioUrl,
    String? imageUrl,
    String? lessonId,
    List<VocabExample>? examples,
    List<String>? relatedKanjis,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Vocabulary(
      id: id ?? this.id,
      word: word ?? this.word,
      hiragana: hiragana ?? this.hiragana,
      meaning: meaning ?? this.meaning,
      level: level ?? this.level,
      usageContext: usageContext ?? this.usageContext,
      audioUrl: audioUrl ?? this.audioUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      lessonId: lessonId ?? this.lessonId,
      examples: examples ?? this.examples,
      relatedKanjis: relatedKanjis ?? this.relatedKanjis,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class VocabExample {
  final String sentence;  // 私は学生です
  final String meaning;   // Tôi là học sinh
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
