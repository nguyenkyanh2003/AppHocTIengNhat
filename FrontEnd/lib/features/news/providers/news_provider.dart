import 'package:flutter/foundation.dart';
import '../models/news.dart';
import '../services/news_service.dart';

class NewsProvider extends ChangeNotifier {
  final NewsService _service = NewsService();

  List<News> _newsList = [];
  News? _selectedNews;
  List<News> _relatedNews = [];

  int _currentPage = 1;
  int _totalPages = 1;
  final int _limit = 10;

  bool _isLoading = false;
  bool _isLoadingDetail = false;
  String? _error;

  String? _selectedLevel;
  String? _searchQuery;

  final Set<String> _bookmarks = {}; // Local bookmarks (in-memory)

  // Getters
  List<News> get newsList => _newsList;
  News? get selectedNews => _selectedNews;
  List<News> get relatedNews => _relatedNews;
  bool get isLoading => _isLoading;
  bool get isLoadingDetail => _isLoadingDetail;
  String? get error => _error;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  String? get selectedLevel => _selectedLevel;
  String? get searchQuery => _searchQuery;

  bool isBookmarked(String newsId) => _bookmarks.contains(newsId);
  List<News> get bookmarkedNews =>
      _newsList.where((n) => isBookmarked(n.id)).toList();

  // Load danh sách tin tức
  Future<void> loadNews({
    bool refresh = false,
    String? level,
    String? search,
  }) async {
    if (refresh) {
      _currentPage = 1;
      _newsList = [];
    }

    if (_currentPage > _totalPages && !refresh) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _service.getNewsList(
        page: _currentPage,
        limit: _limit,
        level: level,
        search: search,
      );

      _totalPages = response['pages'] as int;
      final newNews = response['data'] as List<News>;

      if (refresh) {
        _newsList = newNews;
      } else {
        _newsList.addAll(newNews);
      }

      _selectedLevel = level;
      _searchQuery = search;
      _currentPage++;
    } catch (e) {
      _error = 'Lỗi tải tin tức: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load chi tiết tin tức
  Future<void> loadNewsDetail(String newsId) async {
    _isLoadingDetail = true;
    _error = null;
    notifyListeners();

    try {
      final news = await _service.getNewsDetail(newsId);
      _selectedNews = news;

      // Load tin tức liên quan
      _relatedNews = await _service.getRelatedNews(newsId);
    } catch (e) {
      _error = 'Lỗi tải chi tiết tin tức: $e';
      debugPrint(_error);
    } finally {
      _isLoadingDetail = false;
      notifyListeners();
    }
  }

  // Toggle bookmark
  void toggleBookmark(String newsId) {
    if (_bookmarks.contains(newsId)) {
      _bookmarks.remove(newsId);
    } else {
      _bookmarks.add(newsId);
    }
    notifyListeners();
  }

  // Clear
  void clearSelection() {
    _selectedNews = null;
    _relatedNews = [];
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
