import '../../../core/network/api_envelope.dart';

/// Một thẻ trong bộ: mặt trước là từ/câu hỏi, mặt sau là nghĩa/đáp án.
class FlashcardCard {
  const FlashcardCard({
    required this.id,
    required this.front,
    required this.back,
    this.frontSubtext,
    this.backSubtext,
  });

  final String id;
  final String front;
  final String back;
  final String? frontSubtext;
  final String? backSubtext;

  factory FlashcardCard.fromJson(JsonObject json) => FlashcardCard(
        id: json['_id'] as String? ?? '',
        front: json['front'] as String? ?? '',
        back: json['back'] as String? ?? '',
        frontSubtext: _nonEmpty(json['front_subtext']),
        backSubtext: _nonEmpty(json['back_subtext']),
      );
}

/// Bộ thẻ tự tạo của người học (kiểu "set" của Quizlet).
class FlashcardDeck {
  const FlashcardDeck({
    required this.id,
    required this.title,
    this.description,
    this.cards = const [],
    this.isPublic = false,
    this.category = 'custom',
    this.level,
    this.studyCount = 0,
  });

  final String id;
  final String title;
  final String? description;
  final List<FlashcardCard> cards;
  final bool isPublic;
  final String category;
  final String? level;
  final int studyCount;

  int get cardCount => cards.length;

  factory FlashcardDeck.fromJson(JsonObject json) => FlashcardDeck(
        id: json['_id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        description: _nonEmpty(json['description']),
        cards: [
          for (final card in json['cards'] as List? ?? const [])
            if (card is Map) FlashcardCard.fromJson(Map<String, dynamic>.from(card)),
        ],
        isPublic: json['is_public'] as bool? ?? false,
        category: json['category'] as String? ?? 'custom',
        level: json['level'] as String?,
        studyCount: (json['study_count'] as num?)?.toInt() ?? 0,
      );
}

/// Bộ thẻ mới người dùng nhập ở form tạo bộ.
class FlashcardDeckDraft {
  const FlashcardDeckDraft({
    required this.title,
    this.description = '',
    this.isPublic = false,
    this.category = 'custom',
    this.level,
  });

  final String title;
  final String description;
  final bool isPublic;
  final String category;
  final String? level;

  JsonObject toJson() => {
        'title': title,
        'description': description,
        'is_public': isPublic,
        'category': category,
        if (level != null) 'level': level,
      };
}

/// Nội dung một thẻ; thêm và sửa gửi cùng hình dạng. Phụ đề `null` là không có
/// (khi sửa thì xoá phụ đề cũ).
class FlashcardCardDraft {
  const FlashcardCardDraft({required this.front, required this.back, this.frontSubtext, this.backSubtext});

  final String front;
  final String back;
  final String? frontSubtext;
  final String? backSubtext;

  JsonObject toJson() => {'front': front, 'back': back, 'front_subtext': frontSubtext, 'back_subtext': backSubtext};
}

String? _nonEmpty(Object? value) => value is String && value.isNotEmpty ? value : null;
