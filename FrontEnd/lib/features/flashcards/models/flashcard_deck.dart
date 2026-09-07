import '../../../core/network/api_client.dart';

class FlashcardCard {
  final String? id;
  final String front;
  final String back;
  final String? frontSubtext;
  final String? backSubtext;
  final String? imageUrl;
  final String? audioUrl;
  final int order;
  final DateTime? createdAt;

  FlashcardCard({
    this.id,
    required this.front,
    required this.back,
    this.frontSubtext,
    this.backSubtext,
    this.imageUrl,
    this.audioUrl,
    this.order = 0,
    this.createdAt,
  });

  factory FlashcardCard.fromJson(Map<String, dynamic> json) {
    return FlashcardCard(
      id: json['_id'],
      front: json['front'] ?? '',
      back: json['back'] ?? '',
      frontSubtext: json['front_subtext'],
      backSubtext: json['back_subtext'],
      imageUrl: ApiClient.resolveAssetUrl(json['image_url']),
      audioUrl: ApiClient.resolveAssetUrl(json['audio_url']),
      order: json['order'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'front': front,
      'back': back,
      'front_subtext': frontSubtext,
      'back_subtext': backSubtext,
      'image_url': imageUrl,
      'audio_url': audioUrl,
      'order': order,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  FlashcardCard copyWith({
    String? id,
    String? front,
    String? back,
    String? frontSubtext,
    String? backSubtext,
    String? imageUrl,
    String? audioUrl,
    int? order,
    DateTime? createdAt,
  }) {
    return FlashcardCard(
      id: id ?? this.id,
      front: front ?? this.front,
      back: back ?? this.back,
      frontSubtext: frontSubtext ?? this.frontSubtext,
      backSubtext: backSubtext ?? this.backSubtext,
      imageUrl: imageUrl ?? this.imageUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class FlashcardDeck {
  final String id;
  final String title;
  final String? description;
  final String userId;
  final String? userName;
  final String? userAvatar;
  final List<FlashcardCard> cards;
  final bool isPublic;
  final List<String> tags;
  final String category;
  final String? level;
  final int totalCards;
  final int studyCount;
  final int favoriteCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  FlashcardDeck({
    required this.id,
    required this.title,
    this.description,
    required this.userId,
    this.userName,
    this.userAvatar,
    this.cards = const [],
    this.isPublic = false,
    this.tags = const [],
    this.category = 'custom',
    this.level,
    this.totalCards = 0,
    this.studyCount = 0,
    this.favoriteCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory FlashcardDeck.fromJson(Map<String, dynamic> json) {
    List<FlashcardCard> cardsList = [];
    if (json['cards'] != null) {
      cardsList = (json['cards'] as List)
          .map((card) => FlashcardCard.fromJson(card))
          .toList();
    }

    String? userName;
    String? userAvatar;
    String userId;

    if (json['user'] is Map) {
      final user = json['user'] as Map<String, dynamic>;
      userId = user['_id'] ?? '';
      userName = user['HoTen'] ?? user['TenDangNhap'] ?? user['username'];
      userAvatar = ApiClient.resolveAssetUrl(
        user['AnhDaiDien'] ?? user['avatar'],
      );
    } else {
      userId = json['user'] ?? '';
    }

    return FlashcardDeck(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      userId: userId,
      userName: userName,
      userAvatar: userAvatar,
      cards: cardsList,
      isPublic: json['is_public'] ?? false,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
              [],
      category: json['category'] ?? 'custom',
      level: json['level'],
      totalCards: json['total_cards'] ?? 0,
      studyCount: json['study_count'] ?? 0,
      favoriteCount: json['favorite_count'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'description': description,
      'user': userId,
      'cards': cards.map((card) => card.toJson()).toList(),
      'is_public': isPublic,
      'tags': tags,
      'category': category,
      'level': level,
      'total_cards': totalCards,
      'study_count': studyCount,
      'favorite_count': favoriteCount,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  FlashcardDeck copyWith({
    String? id,
    String? title,
    String? description,
    String? userId,
    String? userName,
    String? userAvatar,
    List<FlashcardCard>? cards,
    bool? isPublic,
    List<String>? tags,
    String? category,
    String? level,
    int? totalCards,
    int? studyCount,
    int? favoriteCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FlashcardDeck(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      cards: cards ?? this.cards,
      isPublic: isPublic ?? this.isPublic,
      tags: tags ?? this.tags,
      category: category ?? this.category,
      level: level ?? this.level,
      totalCards: totalCards ?? this.totalCards,
      studyCount: studyCount ?? this.studyCount,
      favoriteCount: favoriteCount ?? this.favoriteCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
