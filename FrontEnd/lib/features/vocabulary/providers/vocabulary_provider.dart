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

  /// Số thứ tự của yêu cầu danh sách đang có hiệu lực.
  ///
  /// Mọi thao tác ghi vào danh sách (lọc, tìm kiếm, sắp xếp, tải thêm, xoá
  /// state) đều tăng số này. Phản hồi về sau khi số đã đổi là phản hồi của một
  /// yêu cầu đã bị bỏ, và nó không được phép chạm vào **bất kỳ** state nào —
  /// kể cả metadata phân trang và cờ tải, chứ không riêng danh sách.
  int _listGeneration = 0;

  /// Chi tiết có bộ đếm riêng để mở một từ không huỷ yêu cầu của danh sách.
  int _detailGeneration = 0;

  bool _isLoadingMore = false;
  String? _loadMoreError;
  bool _disposed = false;

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

  /// Đang tải trang kế tiếp trong khi danh sách hiện tại vẫn hiển thị.
  bool get isLoadingMore => _isLoadingMore;

  /// Lỗi của riêng lần tải thêm gần nhất; danh sách đang có vẫn được giữ.
  String? get loadMoreError => _loadMoreError;

  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalItems => _totalItems;
  String? get selectedLevel => _selectedLevel;
  String get searchQuery => _searchQuery;
  String? get studyStatus => _studyStatus;
  String? get sortBy => _sortBy;
  bool get hasNextPage => _currentPage < _totalPages;
  bool get hasPrevPage => _currentPage > 1;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _notify() {
    if (_disposed) return;
    notifyListeners();
  }

  /// Tải trang đầu tiên theo bộ lọc hiện tại.
  Future<void> loadVocabularies({bool refresh = false}) async {
    if (refresh) _currentPage = 1;
    _searchQuery = '';
    await _loadPage(_currentPage, append: false);
  }

  /// Tải thêm trang kế tiếp và **nối** vào danh sách đang hiển thị.
  ///
  /// Danh sách và vị trí cuộn được giữ nguyên trong lúc tải: thay cả danh sách
  /// bằng trạng thái loading sẽ tháo `ListView` và đưa người dùng về đầu trang.
  Future<void> loadMore() async {
    if (!hasNextPage) return;
    await _loadPage(_currentPage + 1, append: true);
  }

  Future<void> _loadPage(int page, {required bool append}) async {
    // Chặn nhiều ScrollEndNotification cùng gửi một trang.
    if (append && (_isLoadingMore || _list.isLoading)) return;

    final generation = ++_listGeneration;
    final previous = append ? vocabularies : const <Vocabulary>[];

    if (append) {
      _isLoadingMore = true;
    } else {
      _list = const ViewState.loading();
      _isLoadingMore = false;
    }
    _loadMoreError = null;
    _notify();

    // `guard` chỉ dịch lỗi và trả về kết quả; nó không đụng field nào của
    // provider, nên toàn bộ việc ghi state nằm sau chốt generation bên dưới.
    final result = await ViewState.guard(
      () => _service.getVocabularies(
        page: page,
        limit: _pageSize,
        level: _selectedLevel,
        studyStatus: _studyStatus,
        sortBy: _sortBy,
      ),
    );

    if (generation != _listGeneration) return;

    switch (result) {
      case ViewData(:final value):
        _totalItems = value.total;
        _totalPages = value.totalPages;
        _currentPage = value.page;
        _list = ViewState.data([...previous, ...value.items]);
        _isLoadingMore = false;
      case ViewFailure(:final message):
        if (append) {
          // Giữ nguyên items và trang hiện tại để người dùng thử lại đúng
          // trang bị lỗi thay vì mất hết những gì đã xem.
          _isLoadingMore = false;
          _loadMoreError = message;
        } else {
          _list = ViewState.failure(message);
        }
      default:
        break;
    }

    _notify();
  }

  /// Chạy một yêu cầu danh sách không phân trang dưới cùng bộ đếm generation.
  Future<void> _loadWholeList(Future<List<Vocabulary>> Function() task) async {
    final generation = ++_listGeneration;

    _list = const ViewState.loading();
    _isLoadingMore = false;
    _loadMoreError = null;
    _notify();

    final result = await ViewState.guard(task);

    if (generation != _listGeneration) return;

    _list = result;
    _totalItems = result.valueOrNull?.length ?? 0;
    _totalPages = 1;
    _currentPage = 1;
    _notify();
  }

  Future<void> searchVocabularies(String keyword) async {
    _searchQuery = keyword;

    if (keyword.trim().isEmpty) {
      await loadVocabularies(refresh: true);
      return;
    }

    await _loadWholeList(
      () => _service.searchVocabularies(
        keyword: keyword,
        level: _selectedLevel,
      ),
    );
  }

  Future<void> loadVocabulariesByLesson(String lessonId) =>
      _loadWholeList(() => _service.getVocabulariesByLesson(lessonId));

  Future<void> loadVocabularyDetail(String id) async {
    final generation = ++_detailGeneration;

    _detail = const ViewState.loading();
    _notify();

    final result = await ViewState.guard(() => _service.getVocabularyById(id));

    if (generation != _detailGeneration) return;

    _detail = result;
    _notify();
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
    // Tăng generation để phản hồi của các yêu cầu đang chạy không dựng lại
    // state vừa bị xoá.
    _listGeneration++;
    _detailGeneration++;

    _list = const ViewState.idle();
    _detail = const ViewState.idle();
    _isLoadingMore = false;
    _loadMoreError = null;
    _currentPage = 1;
    _totalPages = 1;
    _totalItems = 0;
    _selectedLevel = null;
    _searchQuery = '';
    _studyStatus = null;
    _sortBy = null;
    _notify();
  }

  void clearError() {
    if (_list is ViewFailure) {
      _list = const ViewState.idle();
      _notify();
    }
    if (_loadMoreError != null) {
      _loadMoreError = null;
      _notify();
    }
  }
}
