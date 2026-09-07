import '../../../core/network/api_client.dart';
import '../models/flashcard_deck.dart';

class FlashcardService {
  final ApiClient _apiClient = ApiClient();

  /// Lấy danh sách bộ thẻ
  Future<Map<String, dynamic>> getDecks({
    int page = 1,
    int limit = 20,
    String? category,
    String? level,
    bool myDecksOnly = false,
  }) async {
    final params = <String>[];
    params.add('page=$page');
    params.add('limit=$limit');

    if (category != null && category.isNotEmpty) {
      params.add('category=$category');
    }

    if (level != null && level.isNotEmpty) {
      params.add('level=$level');
    }

    if (myDecksOnly) {
      params.add('myDecks=true');
    }

    final queryString = params.join('&');
    final response = await _apiClient.get('/flashcard/decks?$queryString');

    return {
      'totalItems': response['totalItems'] ?? 0,
      'totalPages': response['totalPages'] ?? 1,
      'currentPage': response['currentPage'] ?? 1,
      'data': (response['data'] as List?)
              ?.map((deck) => FlashcardDeck.fromJson(deck))
              .toList() ??
          [],
    };
  }

  /// Lấy chi tiết một bộ thẻ
  Future<FlashcardDeck> getDeckById(String deckId) async {
    final response = await _apiClient.get('/flashcard/decks/$deckId');
    return FlashcardDeck.fromJson(response);
  }

  /// Tạo bộ thẻ mới
  Future<FlashcardDeck> createDeck({
    required String title,
    String? description,
    bool isPublic = false,
    String category = 'custom',
    String? level,
    List<String>? tags,
  }) async {
    final body = {
      'title': title,
      'description': description,
      'is_public': isPublic,
      'category': category,
      'level': level,
      'tags': tags ?? [],
    };

    final response = await _apiClient.post('/flashcard/decks', body);
    return FlashcardDeck.fromJson(response['data']);
  }

  /// Cập nhật thông tin bộ thẻ
  Future<FlashcardDeck> updateDeck({
    required String deckId,
    String? title,
    String? description,
    bool? isPublic,
    String? category,
    String? level,
    List<String>? tags,
  }) async {
    final body = <String, dynamic>{};

    if (title != null) body['title'] = title;
    if (description != null) body['description'] = description;
    if (isPublic != null) body['is_public'] = isPublic;
    if (category != null) body['category'] = category;
    if (level != null) body['level'] = level;
    if (tags != null) body['tags'] = tags;

    final response = await _apiClient.put('/flashcard/decks/$deckId', body);
    return FlashcardDeck.fromJson(response['data']);
  }

  /// Xóa bộ thẻ
  Future<void> deleteDeck(String deckId) async {
    await _apiClient.delete('/flashcard/decks/$deckId');
  }

  /// Thêm thẻ mới vào bộ
  Future<FlashcardDeck> addCard({
    required String deckId,
    required String front,
    required String back,
    String? frontSubtext,
    String? backSubtext,
    String? imageUrl,
    String? audioUrl,
  }) async {
    final body = {
      'front': front,
      'back': back,
      'front_subtext': frontSubtext,
      'back_subtext': backSubtext,
      'image_url': imageUrl,
      'audio_url': audioUrl,
    };

    final response =
        await _apiClient.post('/flashcard/decks/$deckId/cards', body);
    return FlashcardDeck.fromJson(response['data']);
  }

  /// Cập nhật thẻ trong bộ
  Future<FlashcardDeck> updateCard({
    required String deckId,
    required String cardId,
    String? front,
    String? back,
    String? frontSubtext,
    String? backSubtext,
    String? imageUrl,
    String? audioUrl,
  }) async {
    final body = <String, dynamic>{};

    if (front != null) body['front'] = front;
    if (back != null) body['back'] = back;
    if (frontSubtext != null) body['front_subtext'] = frontSubtext;
    if (backSubtext != null) body['back_subtext'] = backSubtext;
    if (imageUrl != null) body['image_url'] = imageUrl;
    if (audioUrl != null) body['audio_url'] = audioUrl;

    final response =
        await _apiClient.put('/flashcard/decks/$deckId/cards/$cardId', body);
    return FlashcardDeck.fromJson(response['data']);
  }

  /// Xóa thẻ khỏi bộ
  Future<FlashcardDeck> deleteCard({
    required String deckId,
    required String cardId,
  }) async {
    final response =
        await _apiClient.delete('/flashcard/decks/$deckId/cards/$cardId');
    return FlashcardDeck.fromJson(response['data']);
  }

  /// Ghi nhận lượt học
  Future<void> recordStudy(String deckId) async {
    await _apiClient.post('/flashcard/decks/$deckId/study', {});
  }

  /// Tìm kiếm bộ thẻ
  Future<Map<String, dynamic>> searchDecks({
    required String keyword,
    int page = 1,
    int limit = 20,
  }) async {
    final params = <String>[];
    params.add('keyword=$keyword');
    params.add('page=$page');
    params.add('limit=$limit');

    final queryString = params.join('&');
    final response =
        await _apiClient.get('/flashcard/decks/search?$queryString');

    return {
      'totalItems': response['totalItems'] ?? 0,
      'totalPages': response['totalPages'] ?? 1,
      'currentPage': response['currentPage'] ?? 1,
      'data': (response['data'] as List?)
              ?.map((deck) => FlashcardDeck.fromJson(deck))
              .toList() ??
          [],
    };
  }
}
