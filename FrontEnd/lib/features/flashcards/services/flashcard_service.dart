import '../../../core/network/api_client.dart';
import '../../../core/network/api_envelope.dart';
import '../models/flashcard_deck.dart';

/// Bộ thẻ tự tạo. Thao tác trên thẻ trả lại cả bộ sau khi đổi.
class FlashcardService {
  FlashcardService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  static const pageSize = 20;

  /// Bộ thẻ của người đang đăng nhập, bộ vừa dùng trước.
  Future<Paged<FlashcardDeck>> listMine({int page = 1, int limit = pageSize}) async {
    final query = Uri(queryParameters: {'page': '$page', 'limit': '$limit'}).query;
    return Paged.fromJson(await _client.get('/flashcard/decks?$query'), FlashcardDeck.fromJson);
  }

  Future<FlashcardDeck> detail(String id) async => _deckOf(await _client.get('/flashcard/decks/$id'));

  Future<FlashcardDeck> createDeck(FlashcardDeckDraft draft) async =>
      _deckOf(await _client.post('/flashcard/decks', draft.toJson()));

  Future<FlashcardDeck> updateDeck(String id, {required String title, required String description}) async =>
      _deckOf(await _client.put('/flashcard/decks/$id', {'title': title, 'description': description}));

  Future<void> deleteDeck(String id) => _client.delete('/flashcard/decks/$id');

  Future<FlashcardDeck> addCard(String deckId, FlashcardCardDraft card) async =>
      _deckOf(await _client.post('/flashcard/decks/$deckId/cards', card.toJson()));

  Future<FlashcardDeck> updateCard(String deckId, String cardId, FlashcardCardDraft card) async =>
      _deckOf(await _client.put('/flashcard/decks/$deckId/cards/$cardId', card.toJson()));

  Future<FlashcardDeck> deleteCard(String deckId, String cardId) async =>
      _deckOf(await _client.delete('/flashcard/decks/$deckId/cards/$cardId'));

  /// Đếm một lượt học bộ thẻ.
  Future<void> recordStudy(String id) => _client.post('/flashcard/decks/$id/study', const {});

  static FlashcardDeck _deckOf(Object? response) => objectOf(response, FlashcardDeck.fromJson);
}
