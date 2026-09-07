import 'package:flutter/material.dart';
import '../models/grammar.dart';
import '../services/grammar_service.dart';

class GrammarProvider with ChangeNotifier {
  final GrammarService _grammarService = GrammarService();

  List<Grammar> _grammars = [];
  Grammar? _selectedGrammar;
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 1;
  String? _selectedLevel;
  String? _searchQuery;

  // Getters
  List<Grammar> get grammars => _grammars;
  Grammar? get selectedGrammar => _selectedGrammar;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  String? get selectedLevel => _selectedLevel;
  String? get searchQuery => _searchQuery;

  /// Tải danh sách ngữ pháp
  Future<void> loadGrammars({
    int page = 1,
    int limit = 10,
    String? level,
    String? search,
    String? sortBy,
  }) async {
    _isLoading = true;
    _error = null;
    _currentPage = page;
    _selectedLevel = level;
    _searchQuery = search;
    notifyListeners();

    try {
      final response = await _grammarService.getGrammars(
        page: page,
        limit: limit,
        level: level,
        search: search,
        sortBy: sortBy,
      );

      if (response != null) {
        final data = response['data'] as List?;
        if (data != null) {
          _grammars = data.map((item) => Grammar.fromJson(item)).toList();
        }
        _totalPages = response['totalPages'] ?? 1;
        _error = null;
      } else {
        _error = 'Không thể tải dữ liệu';
      }
    } catch (e) {
      _error = 'Lỗi: $e';
      debugPrint('Error loading grammars: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Lấy chi tiết ngữ pháp
  Future<void> loadGrammarDetail(String grammarId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final grammar = await _grammarService.getGrammarDetail(grammarId);
      if (grammar != null) {
        _selectedGrammar = grammar;
        // Tăng view count
        await _grammarService.incrementGrammarView(grammarId);
      } else {
        _error = 'Không tìm thấy ngữ pháp';
      }
    } catch (e) {
      _error = 'Lỗi: $e';
      debugPrint('Error loading grammar detail: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Lấy ngữ pháp theo cấp độ
  Future<void> loadGrammarsByLevel(String level) async {
    _isLoading = true;
    _error = null;
    _selectedLevel = level;
    notifyListeners();

    try {
      final response = await _grammarService.getGrammarsByLevel(level);
      if (response != null) {
        final data = response['data'] as List?;
        if (data != null) {
          _grammars = data.map((item) => Grammar.fromJson(item)).toList();
        }
      } else {
        _error = 'Không thể tải dữ liệu';
      }
    } catch (e) {
      _error = 'Lỗi: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Tìm kiếm ngữ pháp
  Future<void> searchGrammars(String query) async {
    if (query.isEmpty) {
      _grammars = [];
      _searchQuery = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    _searchQuery = query;
    notifyListeners();

    try {
      final response = await _grammarService.searchGrammars(query);
      if (response != null) {
        final data = response['data'] as List?;
        if (data != null) {
          _grammars = data.map((item) => Grammar.fromJson(item)).toList();
        }
      }
    } catch (e) {
      _error = 'Lỗi tìm kiếm: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Chuyển trang
  Future<void> nextPage({
    int limit = 10,
    String? level,
    String? search,
  }) async {
    if (_currentPage < _totalPages) {
      await loadGrammars(
        page: _currentPage + 1,
        limit: limit,
        level: level ?? _selectedLevel,
        search: search ?? _searchQuery,
      );
    }
  }

  /// Trang trước
  Future<void> previousPage({
    int limit = 10,
    String? level,
    String? search,
  }) async {
    if (_currentPage > 1) {
      await loadGrammars(
        page: _currentPage - 1,
        limit: limit,
        level: level ?? _selectedLevel,
        search: search ?? _searchQuery,
      );
    }
  }

  /// Yêu thích ngữ pháp
  Future<bool> favoriteGrammar(String grammarId) async {
    try {
      final result = await _grammarService.favoriteGrammar(grammarId);
      if (result) {
        notifyListeners();
      }
      return result;
    } catch (e) {
      debugPrint('Error favoriting grammar: $e');
      return false;
    }
  }

  /// Bỏ yêu thích
  Future<bool> unfavoriteGrammar(String grammarId) async {
    try {
      final result = await _grammarService.unfavoriteGrammar(grammarId);
      if (result) {
        notifyListeners();
      }
      return result;
    } catch (e) {
      debugPrint('Error unfavoriting grammar: $e');
      return false;
    }
  }

  /// Reset state
  void reset() {
    _grammars = [];
    _selectedGrammar = null;
    _isLoading = false;
    _error = null;
    _currentPage = 1;
    _totalPages = 1;
    _selectedLevel = null;
    _searchQuery = null;
    notifyListeners();
  }
}
