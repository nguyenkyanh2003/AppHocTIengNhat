import 'package:flutter/foundation.dart';
import '../models/lesson.dart';
import '../services/lesson_service.dart';

class LessonProvider with ChangeNotifier {
  final LessonService _lessonService = LessonService();

  List<Lesson> _lessons = [];
  LessonDetail? _currentLessonDetail;
  Map<String, dynamic>? _stats;

  bool _isLoading = false;
  String? _error;

  // Pagination
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;
  final int _itemsPerPage = 10;

  // Filters
  String? _selectedLevel;
  String? _searchQuery;

  // Getters
  List<Lesson> get lessons => _lessons;
  LessonDetail? get currentLessonDetail => _currentLessonDetail;
  Map<String, dynamic>? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalItems => _totalItems;
  String? get selectedLevel => _selectedLevel;
  String? get searchQuery => _searchQuery;

  // Load danh sách bài học
  Future<void> loadLessons({
    int? page,
    String? level,
    String? search,
    bool refresh = false,
  }) async {
    try {
      if (refresh) {
        _currentPage = 1;
        _lessons.clear();
      }

      _isLoading = true;
      _error = null;
      notifyListeners();

      final targetPage = page ?? _currentPage;
      _selectedLevel = level ?? _selectedLevel;
      _searchQuery = search ?? _searchQuery;

      final result = await _lessonService.getLessons(
        page: targetPage,
        limit: _itemsPerPage,
        level: _selectedLevel,
        search: _searchQuery,
      );

      _lessons = result['lessons'] as List<Lesson>;
      _currentPage = result['currentPage'] ?? 1;
      _totalPages = result['totalPages'] ?? 1;
      _totalItems = result['totalItems'] ?? 0;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load chi tiết bài học
  Future<void> loadLessonDetail(String id) async {
    try {
      _isLoading = true;
      _error = null;
      _currentLessonDetail = null;
      notifyListeners();

      _currentLessonDetail = await _lessonService.getLessonDetail(id);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load bài học theo level
  Future<void> loadLessonsByLevel(String level) async {
    try {
      _isLoading = true;
      _error = null;
      _selectedLevel = level;
      notifyListeners();

      _lessons = await _lessonService.getLessonsByLevel(level);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load thống kê
  Future<void> loadStats() async {
    try {
      _stats = await _lessonService.getLessonStats();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Tìm kiếm bài học
  Future<void> searchLessons(String query) async {
    _searchQuery = query;
    _currentPage = 1;
    await loadLessons(search: query, refresh: true);
  }

  // Lọc theo level
  Future<void> filterByLevel(String? level) async {
    _selectedLevel = level;
    _currentPage = 1;
    await loadLessons(level: level, refresh: true);
  }

  // Clear filters
  Future<void> clearFilters() async {
    _selectedLevel = null;
    _searchQuery = null;
    _currentPage = 1;
    await loadLessons(refresh: true);
  }

  // Chuyển trang
  Future<void> goToPage(int page) async {
    if (page >= 1 && page <= _totalPages && page != _currentPage) {
      _currentPage = page;
      await loadLessons(page: page);
    }
  }

  // Trang tiếp theo
  Future<void> nextPage() async {
    if (_currentPage < _totalPages) {
      await goToPage(_currentPage + 1);
    }
  }

  // Trang trước
  Future<void> previousPage() async {
    if (_currentPage > 1) {
      await goToPage(_currentPage - 1);
    }
  }

  // Reset
  void reset() {
    _lessons = [];
    _currentLessonDetail = null;
    _stats = null;
    _isLoading = false;
    _error = null;
    _currentPage = 1;
    _totalPages = 1;
    _totalItems = 0;
    _selectedLevel = null;
    _searchQuery = null;
    notifyListeners();
  }

  // Lấy bài học theo ID từ danh sách đã tải
  Lesson? getLessonById(String id) {
    try {
      return _lessons.firstWhere((lesson) => lesson.id == id);
    } catch (e) {
      return null;
    }
  }

  // Clear all state
  void clear() {
    _lessons = [];
    _currentLessonDetail = null;
    _stats = null;
    _isLoading = false;
    _error = null;
    _currentPage = 1;
    _totalPages = 1;
    _totalItems = 0;
    _selectedLevel = null;
    _searchQuery = null;
    notifyListeners();
  }
}
