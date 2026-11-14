import '../../../core/network/api_envelope.dart';
import '../../srs/models/srs_progress.dart';

class Kanji {
  final String id;
  final String character; // Chữ Hán: 学
  final String? hanviet; // Hán Việt: Học
  final List<String> onyomi; // Âm Hán: がく、ガク
  final List<String> kunyomi; // Âm Kun: まな(ぶ)
  final String? meaning; // Nghĩa: Học
  final String? level; // N5, N4, N3, N2, N1
  final String? strokeOrderSvg; // SVG vẽ nét
  final List<KanjiExample> examples;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Thẻ ôn của người đang xem; chỉ chi tiết Kanji mới trả, danh sách thì `null`.
  final SrsProgress? srsProgress;

  const Kanji({
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
    this.srsProgress,
  });

  bool get isInReview => srsProgress != null;

  factory Kanji.fromJson(JsonObject json) {
    final progress = json['srs_progress'];
    return Kanji(
      id: json['_id'] as String? ?? '',
      character: json['character'] as String? ?? '',
      hanviet: json['hanviet'] as String?,
      onyomi: _strings(json['onyomi']),
      kunyomi: _strings(json['kunyomi']),
      meaning: json['meaning'] as String?,
      level: json['level'] as String?,
      strokeOrderSvg: json['stroke_order_svg'] as String?,
      examples: [
        for (final example in json['examples'] as List? ?? const [])
          if (example is Map) KanjiExample.fromJson(Map<String, dynamic>.from(example)),
      ],
      createdAt: _dateOf(json['createdAt']),
      updatedAt: _dateOf(json['updatedAt']),
      srsProgress: progress is Map ? SrsProgress.fromJson(Map<String, dynamic>.from(progress)) : null,
    );
  }

  /// Bản sao với thẻ ôn mới — `null` nghĩa là vừa gỡ khỏi lịch ôn.
  Kanji withSrsProgress(SrsProgress? progress) => Kanji(
        id: id,
        character: character,
        hanviet: hanviet,
        onyomi: onyomi,
        kunyomi: kunyomi,
        meaning: meaning,
        level: level,
        strokeOrderSvg: strokeOrderSvg,
        examples: examples,
        createdAt: createdAt,
        updatedAt: updatedAt,
        srsProgress: progress,
      );

  static List<String> _strings(Object? value) => [for (final item in value as List? ?? const []) '$item'];

  static DateTime? _dateOf(Object? value) => value is String ? DateTime.tryParse(value) : null;
}

class KanjiExample {
  final String word; // 学生
  final String hiragana; // がくせい
  final String meaning; // Học sinh

  const KanjiExample({
    required this.word,
    required this.hiragana,
    required this.meaning,
  });

  factory KanjiExample.fromJson(JsonObject json) => KanjiExample(
        word: json['word'] as String? ?? '',
        hiragana: json['hiragana'] as String? ?? '',
        meaning: json['meaning'] as String? ?? '',
      );
}
