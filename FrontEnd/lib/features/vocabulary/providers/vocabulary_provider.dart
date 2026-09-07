import 'package:flutter/material.dart';

import '../../../core/state/view_state.dart';
import '../models/vocabulary.dart';
import '../services/vocabulary_service.dart';

/// State của màn từ vựng.
///
/// Provider chỉ giữ trạng thái và gọi service: mọi việc bắt lỗi và dịch lỗi
/// sang thông báo đã nằm trong [ViewState.guard], nên không còn bộ ba cờ
/// `_isLoading` / `_error` / `_data` tự quản như trước.
class VocabularyProvider extends ChangeNotifier {
  VocabularyProvider({VocabularyService? service})
      : _service = service ?? VocabularyService();

  final VocabularyService _service;

  static const int _pageSize = 20;

  ViewState<List<Vocabulary>> _list = const ViewState.idle();
  ViewState<Vocabulary> _detail = const ViewState.idle();

  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;

  String? _selectedLevel;
  String _searchQuery = '';
  String? _studyStatus;
  String? _sortBy;

  ViewState<List<Vocabulary>> get listState => _list;
  ViewState<Vocabulary> get detailState => _detail;

  List<Vocabulary> get vocabularies => _list.valueOrNull ?? const [];
  Vocabulary? get selectedVocabulary => _detail.valueOrNull;
  bool get isLoading => _list.isLoading;
  String? get error => _list.errorOrNull;

  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalItems => _totalItems;
  String? get selectedLevel => _selectedLevel;
  String get searchQuery => _searchQuery;
  String? get studyStatus => _studyStatus;
  String? get sortBy => _sortBy;
  bool get hasNextPage => _currentPage < _totalPages;
  bool get hasPrevPage => _currentPage > 1;

  /// Tải trang đầu tiên theo bộ lọc hiện tại.
  Future<void> loadVocabularies({bool refresh = false}) async {
    if (refresh) _currentPage = 1;
    _searchQuery = '';
    await _loadPage(_currentPage, append: false);
  }

  /// Tải thêm trang kế tiếp và **nối** vào danh sách đang hiển thị.
  ///
  /// Trước đây thao tác cuộn tới cuối gọi `loadVocabularies()` và thay nguyên
  /// danh sách bằng trang mới, nên danh sách nhảy về đầu và người dùng mất các
  /// mục đã xem.
  Future<void> loadMore() async {
    if (!hasNextPage || _list.isLoading) return;
    await _loadPage(_currentPage + 1, append: true);
  }

  Future<void> _loadPage(int page, {required bool append}) async {
    final previous = append ? vocabularies : const <Vocabulary>[];

    _list = const ViewState.loading();
    notifyListeners();

    final state = await ViewState.guard(() async {
      final result = await _service.getVocabularies(
        page: page,
        limit: _pageSize,
        level: _selectedLevel,
        studyStatus: _studyStatus,
        sortBy: _sortBy,
      );

      _totalItems = result.total;
      _totalPages = result.totalPages;
      _currentPage = result.page;

      return [...previous, ...result.items];
    });

    _list = state;
    notifyListeners();
  }

  Future<void> searchVocabularies(String keyword) async {
    _searchQuery = keyword;

    if (keyword.trim().isEmpty) {
      await loadVocabularies(refresh: true);
      return;
    }

    _list = const ViewState.loading();
    notifyListeners();

    _list = await ViewState.guard(
      () => _service.searchVocabularies(
        keyword: keyword,
        level: _selectedLevel,
      ),
    );

    final found = _list.valueOrNull?.length ?? 0;
    _totalItems = found;
    _totalPages = 1;
    _currentPage = 1;
    notifyListeners();
  }

  Future<void> loadVocabulariesByLesson(String lessonId) async {
    _list = const ViewState.loading();
    notifyListeners();

    _list = await ViewState.guard(
      () => _service.getVocabulariesByLesson(lessonId),
    );

    _totalItems = _list.valueOrNull?.length ?? 0;
    _totalPages = 1;
    _currentPage = 1;
    notifyListeners();
  }

  Future<void> loadVocabularyDetail(String id) async {
    _detail = const ViewState.loading();
    notifyListeners();

    _detail = await ViewState.guard(() => _service.getVocabularyById(id));
    notifyListeners();
  }

  Future<void> filterByLevel(String? level) async {
    _selectedLevel = level;
    await loadVocabularies(refresh: true);
  }

  Future<void> filterByStudyStatus(String? status) async {
    _studyStatus = status;
    await loadVocabularies(refresh: true);
  }

  Future<void> sortVocabularies(String? sortOption) async {
    _sortBy = sortOption;
    await loadVocabularies(refresh: true);
  }

  Future<void> resetFilter() async {
    _selectedLevel = null;
    _studyStatus = null;
    _sortBy = null;
    await loadVocabularies(refresh: true);
  }

  /// Giữ lại tên cũ cho các màn hình đang gọi.
  Future<void> clearFilter() => resetFilter();

  Future<void> nextPage() => loadMore();

  Future<void> previousPage() async {
    if (!hasPrevPage) return;
    await _loadPage(_currentPage - 1, append: false);
  }

  Future<void> goToPage(int page) async {
    if (page < 1 || page > _totalPages) return;
    await _loadPage(page, append: false);
  }

  Future<void> markAsLearned(String vocabularyId) =>
      _service.markAsLearned(vocabularyId);

  Future<void> unmarkAsLearned(String vocabularyId) =>
      _service.unmarkAsLearned(vocabularyId);

  void clear() {
    _list = const ViewState.idle();
    _detail = const ViewState.idle();
    _currentPage = 1;
    _totalPages = 1;
    _totalItems = 0;
    _selectedLevel = null;
    _searchQuery = '';
    _studyStatus = null;
    _sortBy = null;
    notifyListeners();
  }

  void clearError() {
    if (_list is ViewFailure) {
      _list = const ViewState.idle();
      notifyListeners();
    }
  }
}
