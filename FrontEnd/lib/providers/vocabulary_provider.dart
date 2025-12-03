import 'package:flutter/material.dart';
import '../models/vocabulary.dart';
import '../services/vocabulary_service.dart';

class VocabularyProvider extends ChangeNotifier {
  final VocabularyService _vocabularyService = VocabularyService();

  List<Vocabulary> _vocabularies = [];
  Vocabulary? _selectedVocabulary;
  bool _isLoading = false;
  String? _error;

  // Pagination
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;
  final int _itemsPerPage = 20;

  // Filter
  String? _selectedLevel;
  String _searchQuery = '';

  // Getters
  List<Vocabulary> get vocabularies => _vocabularies;
  Vocabulary? get selectedVocabulary => _selectedVocabulary;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalItems => _totalItems;
  String? get selectedLevel => _selectedLevel;
  String get searchQuery => _searchQuery;
  bool get hasNextPage => _currentPage < _totalPages;
  bool get hasPrevPage => _currentPage > 1;

  /// Load danh sách từ vựng
  Future<void> loadVocabularies({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _vocabularies = [];
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _vocabularyService.getVocabularies(
        page: _currentPage,
        limit: _itemsPerPage,
        level: _selectedLevel,
      );

      _vocabularies = result['data'];
      _totalPages = result['totalPages'];
      _totalItems = result['totalItems'];
      _currentPage = result['currentPage'];
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Tìm kiếm từ vựng
  Future<void> searchVocabularies(String keyword) async {
    _searchQuery = keyword;
    
    if (keyword.trim().isEmpty) {
      await loadVocabularies(refresh: true);
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _vocabularies = await _vocabularyService.searchVocabularies(
        keyword: keyword,
        level: _selectedLevel,
      );
      _totalItems = _vocabularies.length;
      _totalPages = 1;
      _currentPage = 1;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Lọc theo level
  Future<void> filterByLevel(String? level) async {
    _selectedLevel = level;
    await loadVocabularies(refresh: true);
  }

  /// Load từ vựng theo bài học
  Future<void> loadVocabulariesByLesson(String lessonId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _vocabularies = await _vocabularyService.getVocabulariesByLesson(lessonId);
      _totalItems = _vocabularies.length;
      _totalPages = 1;
      _currentPage = 1;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load chi tiết từ vựng
  Future<void> loadVocabularyDetail(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedVocabulary = await _vocabularyService.getVocabularyById(id);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Chuyển trang tiếp theo
  Future<void> nextPage() async {
    if (hasNextPage) {
      _currentPage++;
      await loadVocabularies();
    }
  }

  /// Chuyển trang trước
  Future<void> previousPage() async {
    if (hasPrevPage) {
      _currentPage--;
      await loadVocabularies();
    }
  }

  /// Chuyển đến trang cụ thể
  Future<void> goToPage(int page) async {
    if (page >= 1 && page <= _totalPages) {
      _currentPage = page;
      await loadVocabularies();
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Reset filter
  Future<void> resetFilter() async {
    _selectedLevel = null;
    _searchQuery = '';
    await loadVocabularies(refresh: true);
  }

  /// Đánh dấu đã học từ vựng
  Future<void> markAsLearned(String vocabularyId) async {
    try {
      await _vocabularyService.markAsLearned(vocabularyId);
    } catch (e) {
      rethrow;
    }
  }

  /// Clear all state
  void clear() {
    _vocabularies = [];
    _selectedVocabulary = null;
    _isLoading = false;
    _error = null;
    _currentPage = 1;
    _totalPages = 1;
    _totalItems = 0;
    _selectedLevel = null;
    _searchQuery = '';
    notifyListeners();
  }
}
