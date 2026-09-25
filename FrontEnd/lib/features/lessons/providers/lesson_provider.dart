import 'package:flutter/foundation.dart';

import '../../../core/state/view_state.dart';
import '../models/lesson.dart';
import '../services/lesson_service.dart';

class LessonProvider with ChangeNotifier {
  final LessonService _lessonService = LessonService();

  List<Lesson> _lessons = [];
  LessonDetail? _currentLessonDetail;
  Map<String, dynamic>? _stats;

  // Trạng thái của màn chi tiết và thống kê.
  bool _isLoading = false;
  String? _error;

  // Trạng thái riêng của danh sách: mở một bài bị lỗi rồi quay lại không được
  // biến cả danh sách thành màn lỗi. Chưa nạp lần nào cũng tính là đang tải, để
  // màn không chớp trạng thái rỗng trước request đầu tiên.
  bool _isListLoading = true;
  String? _listError;
  bool _listOpened = false;

  // Mỗi lần nạp mang một số thế hệ; response về muộn của lần nạp cũ bị bỏ qua.
  int _listGeneration = 0;
  int _situationsGeneration = 0;
  int _detailGeneration = 0;

  /// Chi tiết các bài đã mở trong phiên, theo `id`.
  final Map<String, LessonDetail> _detailCache = {};

  // Pagination. Đủ rộng để cả một trình độ (N5 hiện 15 bài) nằm trên một
  // trang: lộ trình học bị cắt đôi giữa chừng thì khó theo, còn danh sách chỉ
  // chở phần tóm tắt của bài nên tải nhẹ.
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;
  final int _itemsPerPage = 20;

  // Filters
  String? _selectedLevel;
  String? _selectedSituation;
  String? _searchQuery;
  List<String> _situations = [];

  // Getters
  List<Lesson> get lessons => _lessons;
  LessonDetail? get currentLessonDetail => _currentLessonDetail;

  /// Chi tiết bài ở dạng [ViewState], để màn hình dùng `AsyncView`.
  ViewState<LessonDetail> get detailState {
    if (_error != null) return ViewState.failure(_error!);
    final detail = _currentLessonDetail;
    return detail == null ? const ViewState.loading() : ViewState.data(detail);
  }
  Map<String, dynamic>? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isListLoading => _isListLoading;
  String? get listError => _listError;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalItems => _totalItems;
  String? get selectedLevel => _selectedLevel;
  String? get selectedSituation => _selectedSituation;
  List<String> get situations => _situations;
  String? get searchQuery => _searchQuery;

  /// Nạp danh sách khi mở màn Bài học.
  ///
  /// Lần mở đầu tiên trong phiên lọc sẵn theo [defaultLevel] — trình độ của
  /// người học. Những lần mở sau giữ nguyên bộ lọc họ đã chọn và chỉ nạp lại
  /// khi lần trước bị lỗi.
  Future<void> openLessonList({required String defaultLevel}) async {
    if (!_listOpened) {
      _listOpened = true;
      await filterByLevel(defaultLevel);
    } else if (_listError != null) {
      await loadLessons(refresh: true);
    }
  }

  /// Nạp danh sách bài học theo bộ lọc hiện tại.
  ///
  /// Danh sách cũ được giữ trong lúc chờ để đổi bộ lọc không làm màn nháy trắng.
  /// Người học đổi bộ lọc liên tiếp thì response về sau cùng chưa chắc là của
  /// bộ lọc mới nhất, nên chỉ response của lần gọi mới nhất được ghi vào state.
  Future<void> loadLessons({
    int? page,
    String? level,
    String? situation,
    String? search,
    bool refresh = false,
  }) async {
    final generation = ++_listGeneration;
    if (refresh) _currentPage = 1;
    _selectedLevel = level ?? _selectedLevel;
    _selectedSituation = situation ?? _selectedSituation;
    _searchQuery = search ?? _searchQuery;
    _isListLoading = true;
    _listError = null;
    notifyListeners();

    try {
      final result = await _lessonService.getLessons(
        page: page ?? _currentPage,
        limit: _itemsPerPage,
        level: _selectedLevel,
        situation: _selectedSituation,
        search: _searchQuery,
      );
      if (generation != _listGeneration) return;

      _lessons = result['lessons'] as List<Lesson>;
      _currentPage = result['currentPage'] ?? 1;
      _totalPages = result['totalPages'] ?? 1;
      _totalItems = result['totalItems'] ?? 0;
    } catch (e) {
      if (generation != _listGeneration) return;

      _lessons = [];
      _listError = e.toString();
    }

    _isListLoading = false;
    notifyListeners();
  }

  /// Nạp chi tiết một bài.
  ///
  /// Nội dung bài học gần như không đổi, nên bài đã mở trong phiên này hiện
  /// ngay từ bộ nhớ — không vòng xoay khi quay lại bài vừa học hay đi từ màn
  /// chi tiết sang màn học — rồi mới lặng lẽ làm mới từ server. Lỗi mạng lúc
  /// làm mới thì giữ bản đang hiện thay vì biến trang thành màn lỗi.
  Future<void> loadLessonDetail(String id) async {
    final generation = ++_detailGeneration;
    final cached = _detailCache[id];
    _currentLessonDetail = cached;
    _isLoading = cached == null;
    _error = null;
    notifyListeners();

    try {
      final detail = await _lessonService.getLessonDetail(id);
      _detailCache[id] = detail;
      // Người học đã mở bài khác trong lúc chờ: chỉ cất vào bộ nhớ.
      if (generation != _detailGeneration) return;
      _currentLessonDetail = detail;
    } catch (e) {
      if (generation != _detailGeneration) return;
      if (cached == null) _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
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

  /// Lọc theo cấp độ, kéo theo dải chủ đề của cấp đó. `null` là mọi cấp độ.
  ///
  /// Chủ đề đang chọn bị bỏ: một chủ đề có bài ở N5 chưa chắc có bài ở N3, giữ
  /// lại thì danh sách rỗng mà người học không hiểu vì sao.
  Future<void> filterByLevel(String? level) async {
    _selectedLevel = level;
    _selectedSituation = null;
    _currentPage = 1;
    await Future.wait([
      loadLessons(refresh: true),
      loadSituations(),
    ]);
  }

  /// Lọc theo tình huống thực tế. `null` là mọi chủ đề của cấp đang chọn.
  Future<void> filterBySituation(String? situation) async {
    _selectedSituation = situation;
    _currentPage = 1;
    await loadLessons(refresh: true);
  }

  /// Nạp danh sách tình huống có bài học ở cấp đang lọc để dựng bộ lọc.
  ///
  /// Lỗi ở đây không được làm hỏng màn danh sách: không có tình huống thì chỉ
  /// là bộ lọc trống, bài học vẫn xem được bình thường.
  Future<void> loadSituations() async {
    final generation = ++_situationsGeneration;
    List<String> situations;
    try {
      situations = await _lessonService.getSituations(level: _selectedLevel);
    } catch (_) {
      situations = [];
    }
    if (generation != _situationsGeneration) return;

    _situations = situations;
    notifyListeners();
  }

  // Clear filters
  Future<void> clearFilters() async {
    _selectedLevel = null;
    _selectedSituation = null;
    _searchQuery = null;
    _currentPage = 1;
    await Future.wait([loadLessons(refresh: true), loadSituations()]);
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
  void reset() => clear();

  // Lấy bài học theo ID từ danh sách đã tải
  Lesson? getLessonById(String id) {
    try {
      return _lessons.firstWhere((lesson) => lesson.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Xoá toàn bộ state, dùng khi đăng xuất.
  ///
  /// Tăng số thế hệ để response của phiên trước còn đang bay không ghi lại dữ
  /// liệu của người vừa đăng xuất.
  void clear() {
    _listGeneration++;
    _situationsGeneration++;
    _detailGeneration++;
    _lessons = [];
    _detailCache.clear();
    _currentLessonDetail = null;
    _stats = null;
    _isLoading = false;
    _error = null;
    _isListLoading = true;
    _listError = null;
    _listOpened = false;
    _currentPage = 1;
    _totalPages = 1;
    _totalItems = 0;
    _selectedLevel = null;
    _selectedSituation = null;
    _situations = [];
    _searchQuery = null;
    notifyListeners();
  }
}
