import 'package:flutter/foundation.dart';

import '../../../core/state/detail_state.dart';
import '../../../core/state/paged_list.dart';
import '../../../core/state/view_state.dart';
import '../models/flashcard_deck.dart';
import '../services/flashcard_service.dart';

/// Bộ thẻ của người học: danh sách (tải thêm khi cuộn), bộ đang mở và các thao
/// tác sửa bộ/thẻ.
///
/// Mọi thao tác ghi trả `null` khi xong hoặc câu báo lỗi để màn hiện. Ghi xong
/// thì bộ đang mở cập nhật theo bản server trả, danh sách đã mở được tải lại.
class FlashcardProvider extends ChangeNotifier {
  FlashcardProvider({FlashcardService? service}) : _service = service ?? FlashcardService();

  final FlashcardService _service;
  late final _decks = PagedList<FlashcardDeck>(onChanged: _notify);
  late final _detail = DetailState<FlashcardDeck>(idOf: (deck) => deck.id, onChanged: _notify);
  bool _saving = false;
  bool _disposed = false;

  ViewState<List<FlashcardDeck>> get decks => _decks.state;
  bool get hasMore => _decks.hasMore;
  bool get isLoadingMore => _decks.isLoadingMore;
  String? get loadMoreError => _decks.loadMoreError;
  ViewState<FlashcardDeck> get detail => _detail.state;
  bool get isSaving => _saving;

  /// Chi tiết của đúng bộ [id] (xem [DetailState.of]).
  ViewState<FlashcardDeck> detailOf(String id) => _detail.of(id);

  Future<void> loadDecks() => _decks.load((page) => _service.listMine(page: page));

  Future<void> loadMore() => _decks.loadMore();

  Future<void> loadDetail(String id) => _detail.load(id, () => _service.detail(id));

  Future<String?> createDeck(FlashcardDeckDraft draft) => _write(() => _service.createDeck(draft));

  Future<String?> updateDeck(String id, {required String title, required String description}) =>
      _write(() => _service.updateDeck(id, title: title, description: description));

  Future<String?> addCard(String deckId, FlashcardCardDraft card) => _write(() => _service.addCard(deckId, card));

  Future<String?> updateCard(String deckId, String cardId, FlashcardCardDraft card) =>
      _write(() => _service.updateCard(deckId, cardId, card));

  Future<String?> deleteCard(String deckId, String cardId) => _write(() => _service.deleteCard(deckId, cardId));

  /// Lối tắt của hộp "Thêm vào Flashcard": tạo bộ từ vựng mới rồi thêm thẻ vào đó.
  Future<String?> addCardToNewDeck(String title, FlashcardCardDraft card) => _write(() async {
        final deck = await _service.createDeck(FlashcardDeckDraft(title: title, category: 'vocabulary'));
        return _service.addCard(deck.id, card);
      });

  Future<String?> deleteDeck(String id) async {
    final result = await ViewState.guard(() => _service.deleteDeck(id));
    if (!result.hasData) return result.errorOrNull;
    _detail.remove(id);
    _reloadOpenList();
    return null;
  }

  /// Đếm lượt học là phụ: hỏng thì bỏ qua, không chặn người học vào học.
  Future<void> recordStudy(String id) => ViewState.guard(() => _service.recordStudy(id));

  /// Về trạng thái chưa tải (đăng xuất).
  void clear() {
    _decks.clear();
    _detail.clear();
  }

  Future<String?> _write(Future<FlashcardDeck> Function() action) async {
    if (_saving) return 'Thao tác trước vẫn đang được lưu.';
    _saving = true;
    _notify();

    final result = await ViewState.guard(action);
    _saving = false;
    if (result case ViewData(:final value)) _detail.replace(value);
    _notify();
    if (result.hasData) _reloadOpenList();
    return result.errorOrNull;
  }

  void _reloadOpenList() {
    if (_decks.state is! ViewIdle) _decks.reload();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
