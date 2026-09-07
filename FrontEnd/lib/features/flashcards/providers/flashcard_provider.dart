import 'package:flutter/material.dart';
import '../models/flashcard_deck.dart';
import '../services/flashcard_service.dart';

class FlashcardProvider extends ChangeNotifier {
  final FlashcardService _flashcardService = FlashcardService();

  // State
  List<FlashcardDeck> _decks = [];
  FlashcardDeck? _selectedDeck;
  bool _isLoading = false;
  String? _error;

  // Pagination
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;
  final int _itemsPerPage = 20;

  // Filters
  String? _selectedCategory;
  String? _selectedLevel;
  bool _myDecksOnly = true; // Mặc định chỉ hiện bộ thẻ của mình

  // Getters
  List<FlashcardDeck> get decks => _decks;
  FlashcardDeck? get selectedDeck => _selectedDeck;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalItems => _totalItems;
  String? get selectedCategory => _selectedCategory;
  String? get selectedLevel => _selectedLevel;
  bool get myDecksOnly => _myDecksOnly;

  /// Tải danh sách bộ thẻ
  Future<void> loadDecks({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _flashcardService.getDecks(
        page: _currentPage,
        limit: _itemsPerPage,
        category: _selectedCategory,
        level: _selectedLevel,
        myDecksOnly: _myDecksOnly,
      );

      _decks = result['data'] as List<FlashcardDeck>;
      _totalItems = result['totalItems'] as int;
      _totalPages = result['totalPages'] as int;
      _currentPage = result['currentPage'] as int;
      _error = null;
    } catch (e) {
      _error = e.toString();
      _decks = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Tải chi tiết một bộ thẻ
  Future<FlashcardDeck?> loadDeckById(String deckId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedDeck = await _flashcardService.getDeckById(deckId);
      _error = null;
      return _selectedDeck;
    } catch (e) {
      _error = e.toString();
      _selectedDeck = null;
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Tạo bộ thẻ mới
  Future<FlashcardDeck?> createDeck({
    required String title,
    String? description,
    bool isPublic = false,
    String category = 'custom',
    String? level,
    List<String>? tags,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newDeck = await _flashcardService.createDeck(
        title: title,
        description: description,
        isPublic: isPublic,
        category: category,
        level: level,
        tags: tags,
      );

      // Thêm vào đầu danh sách
      _decks.insert(0, newDeck);
      _error = null;
      return newDeck;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cập nhật thông tin bộ thẻ
  Future<bool> updateDeck({
    required String deckId,
    String? title,
    String? description,
    bool? isPublic,
    String? category,
    String? level,
    List<String>? tags,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedDeck = await _flashcardService.updateDeck(
        deckId: deckId,
        title: title,
        description: description,
        isPublic: isPublic,
        category: category,
        level: level,
        tags: tags,
      );

      // Cập nhật trong danh sách
      final index = _decks.indexWhere((deck) => deck.id == deckId);
      if (index != -1) {
        _decks[index] = updatedDeck;
      }

      // Cập nhật selectedDeck nếu đang xem bộ thẻ này
      if (_selectedDeck?.id == deckId) {
        _selectedDeck = updatedDeck;
      }

      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Xóa bộ thẻ
  Future<bool> deleteDeck(String deckId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _flashcardService.deleteDeck(deckId);

      // Xóa khỏi danh sách
      _decks.removeWhere((deck) => deck.id == deckId);

      // Clear selectedDeck nếu đang xem bộ thẻ bị xóa
      if (_selectedDeck?.id == deckId) {
        _selectedDeck = null;
      }

      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Thêm thẻ mới vào bộ
  Future<bool> addCard({
    required String deckId,
    required String front,
    required String back,
    String? frontSubtext,
    String? backSubtext,
    String? imageUrl,
    String? audioUrl,
  }) async {
    try {
      final updatedDeck = await _flashcardService.addCard(
        deckId: deckId,
        front: front,
        back: back,
        frontSubtext: frontSubtext,
        backSubtext: backSubtext,
        imageUrl: imageUrl,
        audioUrl: audioUrl,
      );

      // Cập nhật trong danh sách
      final index = _decks.indexWhere((deck) => deck.id == deckId);
      if (index != -1) {
        _decks[index] = updatedDeck;
      }

      // Cập nhật selectedDeck
      if (_selectedDeck?.id == deckId) {
        _selectedDeck = updatedDeck;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Cập nhật thẻ
  Future<bool> updateCard({
    required String deckId,
    required String cardId,
    String? front,
    String? back,
    String? frontSubtext,
    String? backSubtext,
    String? imageUrl,
    String? audioUrl,
  }) async {
    try {
      final updatedDeck = await _flashcardService.updateCard(
        deckId: deckId,
        cardId: cardId,
        front: front,
        back: back,
        frontSubtext: frontSubtext,
        backSubtext: backSubtext,
        imageUrl: imageUrl,
        audioUrl: audioUrl,
      );

      // Cập nhật trong danh sách
      final index = _decks.indexWhere((deck) => deck.id == deckId);
      if (index != -1) {
        _decks[index] = updatedDeck;
      }

      // Cập nhật selectedDeck
      if (_selectedDeck?.id == deckId) {
        _selectedDeck = updatedDeck;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Xóa thẻ
  Future<bool> deleteCard({
    required String deckId,
    required String cardId,
  }) async {
    try {
      final updatedDeck = await _flashcardService.deleteCard(
        deckId: deckId,
        cardId: cardId,
      );

      // Cập nhật trong danh sách
      final index = _decks.indexWhere((deck) => deck.id == deckId);
      if (index != -1) {
        _decks[index] = updatedDeck;
      }

      // Cập nhật selectedDeck
      if (_selectedDeck?.id == deckId) {
        _selectedDeck = updatedDeck;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Ghi nhận lượt học
  Future<void> recordStudy(String deckId) async {
    try {
      await _flashcardService.recordStudy(deckId);
    } catch (e) {
      // Không cần thông báo lỗi cho việc ghi nhận lượt học
    }
  }

  /// Filter theo category
  Future<void> filterByCategory(String? category) async {
    _selectedCategory = category;
    await loadDecks(refresh: true);
  }

  /// Filter theo level
  Future<void> filterByLevel(String? level) async {
    _selectedLevel = level;
    await loadDecks(refresh: true);
  }

  /// Toggle my decks only
  Future<void> toggleMyDecksOnly() async {
    _myDecksOnly = !_myDecksOnly;
    await loadDecks(refresh: true);
  }

  /// Reset filter
  Future<void> resetFilter() async {
    _selectedCategory = null;
    _selectedLevel = null;
    _myDecksOnly = false;
    await loadDecks(refresh: true);
  }

  /// Next page
  Future<void> nextPage() async {
    if (_currentPage < _totalPages) {
      _currentPage++;
      await loadDecks();
    }
  }

  /// Previous page
  Future<void> previousPage() async {
    if (_currentPage > 1) {
      _currentPage--;
      await loadDecks();
    }
  }

  /// Go to page
  Future<void> goToPage(int page) async {
    if (page >= 1 && page <= _totalPages) {
      _currentPage = page;
      await loadDecks();
    }
  }

  /// Clear selected deck
  void clearSelectedDeck() {
    _selectedDeck = null;
    notifyListeners();
  }
}
