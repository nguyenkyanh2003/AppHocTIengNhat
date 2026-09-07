import 'package:flutter/material.dart';
import '../services/search_service.dart';

class SearchProvider with ChangeNotifier {
  final SearchService _searchService = SearchService();

  List<SearchResult> _searchResults = [];
  bool _isLoading = false;
  String? _error;
  String? _lastQuery;

  List<SearchResult> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get lastQuery => _lastQuery;

  /// Tìm kiếm global
  Future<void> search(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      _lastQuery = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    _lastQuery = query;
    notifyListeners();

    try {
      final results = await _searchService.globalSearch(query);
      if (results != null) {
        _searchResults = results;
      } else {
        _error = 'Không thể tìm kiếm';
      }
    } catch (e) {
      _error = 'Lỗi: $e';
      debugPrint('Search error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear results
  void clearSearch() {
    _searchResults = [];
    _lastQuery = null;
    _error = null;
    notifyListeners();
  }
}
