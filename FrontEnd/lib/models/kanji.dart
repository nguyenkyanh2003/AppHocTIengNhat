class Kanji {
  final String id;
  final String character;     // Chữ Hán: 学
  final String? hanviet;      // Hán Việt: Học
  final List<String> onyomi;  // Âm Hán: がく、ガク
  final List<String> kunyomi; // Âm Kun: まな(ぶ)
  final String? meaning;      // Nghĩa: Học
  final String? level;        // N5, N4, N3, N2, N1
  final String? strokeOrderSvg; // SVG vẽ nét
  final List<KanjiExample> examples;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Kanji({
    required this.id,
    required this.character,
    this.hanviet,
    this.onyomi = const [],
    this.kunyomi = const [],
    this.meaning,
    this.level,
    this.strokeOrderSvg,
    this.examples = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory Kanji.fromJson(Map<String, dynamic> json) {
    return Kanji(
      id: json['_id'] ?? '',
      character: json['character'] ?? '',
      hanviet: json['hanviet'],
      onyomi: (json['onyomi'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      kunyomi: (json['kunyomi'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      meaning: json['meaning'],
      level: json['level'],
      strokeOrderSvg: json['stroke_order_svg'],
      examples: (json['examples'] as List<dynamic>?)
              ?.map((e) => KanjiExample.fromJson(e))
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
      'character': character,
      'hanviet': hanviet,
      'onyomi': onyomi,
      'kunyomi': kunyomi,
      'meaning': meaning,
      'level': level,
      'stroke_order_svg': strokeOrderSvg,
      'examples': examples.map((e) => e.toJson()).toList(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Kanji copyWith({
    String? id,
    String? character,
    String? hanviet,
    List<String>? onyomi,
    List<String>? kunyomi,
    String? meaning,
    String? level,
    String? strokeOrderSvg,
    List<KanjiExample>? examples,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Kanji(
      id: id ?? this.id,
      character: character ?? this.character,
      hanviet: hanviet ?? this.hanviet,
      onyomi: onyomi ?? this.onyomi,
      kunyomi: kunyomi ?? this.kunyomi,
      meaning: meaning ?? this.meaning,
      level: level ?? this.level,
      strokeOrderSvg: strokeOrderSvg ?? this.strokeOrderSvg,
      examples: examples ?? this.examples,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class KanjiExample {
  final String word;      // 学生
  final String hiragana;  // がくせい
  final String meaning;   // Học sinh

  KanjiExample({
    required this.word,
    required this.hiragana,
    required this.meaning,
  });

  factory KanjiExample.fromJson(Map<String, dynamic> json) {
    return KanjiExample(
      word: json['word'] ?? '',
      hiragana: json['hiragana'] ?? '',
      meaning: json['meaning'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'word': word,
      'hiragana': hiragana,
      'meaning': meaning,
    };
  }
}
