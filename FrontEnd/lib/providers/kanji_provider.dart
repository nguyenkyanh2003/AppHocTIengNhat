import 'package:flutter/foundation.dart';
import '../models/kanji.dart';
import '../services/kanji_service.dart';

class KanjiProvider with ChangeNotifier {
  final KanjiService _kanjiService = KanjiService();

  List<Kanji> _kanjis = [];
  Kanji? _selectedKanji;
  bool _isLoading = false;
  String _errorMessage = '';
  
  // Phân trang
  int _currentPage = 1;
  int _totalPages = 1;
  int _total = 0;
  final int _itemsPerPage = 20;

  // Lọc
  String? _selectedLevel;

  // Getters
  List<Kanji> get kanjis => _kanjis;
  Kanji? get selectedKanji => _selectedKanji;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get total => _total;
  int get itemsPerPage => _itemsPerPage;
  String? get selectedLevel => _selectedLevel;

  bool get hasNextPage => _currentPage < _totalPages;
  bool get hasPreviousPage => _currentPage > 1;

  // Tải danh sách kanji
  Future<void> loadKanjis({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _kanjis.clear();
    }

    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final result = await _kanjiService.getKanjis(
        page: _currentPage,
        limit: _itemsPerPage,
        level: _selectedLevel,
      );

      _kanjis = result['kanjis'] as List<Kanji>;
      _total = result['total'] as int;
      _currentPage = result['page'] as int;
      _totalPages = result['totalPages'] as int;
      _errorMessage = '';
    } catch (e) {
      _errorMessage = e.toString();
      _kanjis = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Tìm kiếm kanji
  Future<void> searchKanjis(String query) async {
    if (query.isEmpty) {
      await loadKanjis(refresh: true);
      return;
    }

    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _kanjis = await _kanjiService.searchKanjis(query);
      _currentPage = 1;
      _totalPages = 1;
      _total = _kanjis.length;
      _errorMessage = '';
    } catch (e) {
      _errorMessage = e.toString();
      _kanjis = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Lọc theo level
  Future<void> filterByLevel(String? level) async {
    _selectedLevel = level;
    await loadKanjis(refresh: true);
  }

  // Trang tiếp theo
  Future<void> nextPage() async {
    if (hasNextPage) {
      _currentPage++;
      await loadKanjis();
    }
  }

  // Trang trước
  Future<void> previousPage() async {
    if (hasPreviousPage) {
      _currentPage--;
      await loadKanjis();
    }
  }

  // Tải chi tiết kanji
  Future<void> loadKanjiDetail(String id) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _selectedKanji = await _kanjiService.getKanjiById(id);
      _errorMessage = '';
    } catch (e) {
      _errorMessage = e.toString();
      _selectedKanji = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Tải kanji theo bài học
  Future<void> loadKanjisByLesson(String lessonId) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _kanjis = await _kanjiService.getKanjisByLesson(lessonId);
      _currentPage = 1;
      _totalPages = 1;
      _total = _kanjis.length;
      _errorMessage = '';
    } catch (e) {
      _errorMessage = e.toString();
      _kanjis = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Tải kanji ngẫu nhiên
  Future<void> loadRandomKanjis({int count = 10}) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _kanjis = await _kanjiService.getRandomKanjis(
        count: count,
        level: _selectedLevel,
      );
      _currentPage = 1;
      _totalPages = 1;
      _total = _kanjis.length;
      _errorMessage = '';
    } catch (e) {
      _errorMessage = e.toString();
      _kanjis = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Reset
  void reset() {
    _kanjis = [];
    _selectedKanji = null;
    _isLoading = false;
    _errorMessage = '';
    _currentPage = 1;
    _totalPages = 1;
    _total = 0;
    _selectedLevel = null;
    notifyListeners();
  }

  // Đánh dấu đã học kanji
  Future<void> markAsLearned(String kanjiId) async {
    try {
      await _kanjiService.markAsLearned(kanjiId);
    } catch (e) {
      rethrow;
    }
  }

  // Clear all state
  void clear() {
    _kanjis = [];
    _selectedKanji = null;
    _isLoading = false;
    _errorMessage = '';
    _currentPage = 1;
    _totalPages = 1;
    _total = 0;
    _selectedLevel = null;
    notifyListeners();
  }
}
