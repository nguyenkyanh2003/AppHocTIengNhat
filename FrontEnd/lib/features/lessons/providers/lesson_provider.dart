import 'package:flutter/foundation.dart';

import '../../../core/state/paged_list.dart';
import '../../../core/state/view_state.dart';
import '../models/lesson.dart';
import '../services/lesson_service.dart';

/// Danh sách bài học (lọc theo trình độ rồi chủ đề, tìm kiếm, tải thêm) và
/// chi tiết bài đang mở.
class LessonProvider extends ChangeNotifier {
  LessonProvider({LessonService? service}) : _service = service ?? LessonService();

  final LessonService _service;
  late final _lessons = PagedList<Lesson>(onChanged: _notify);
  bool _listOpened = false;
  String? _level;
  String? _situation;
  String? _search;
  List<String> _situations = const [];
  int _situationsGeneration = 0;

  /// Chi tiết các bài đã mở trong phiên, theo `id`.
  final Map<String, LessonDetail> _detailCache = {};
  String? _detailId;
  ViewState<LessonDetail> _detail = const ViewState.idle();
  int _detailGeneration = 0;
  bool _disposed = false;

  ViewState<List<Lesson>> get lessons => _lessons.state;
  bool get hasMore => _lessons.hasMore;
  bool get isLoadingMore => _lessons.isLoadingMore;
  String? get loadMoreError => _lessons.loadMoreError;

  /// Đổi bộ lọc đang chờ: danh sách cũ vẫn hiện kèm thanh tải mảnh.
  bool get isRefreshing => _lessons.isRefreshing;
  String? get selectedLevel => _level;
  String? get selectedSituation => _situation;
  String? get searchQuery => _search;
  List<String> get situations => _situations;

  /// Chi tiết của bài [id]. Bài đã mở trong phiên hiện ngay từ bộ nhớ.
  ViewState<LessonDetail> detailOf(String id) {
    if (id == _detailId) return _detail;
    final cached = _detailCache[id];
    return cached == null ? const ViewState.loading() : ViewState.data(cached);
  }

  /// Mở màn Bài học. Lần đầu trong phiên lọc sẵn theo [defaultLevel] (trình độ
  /// của người học); lần sau giữ bộ lọc họ đã chọn, chỉ tải lại khi lần trước lỗi.
  Future<void> openLessonList({required String defaultLevel}) async {
    if (!_listOpened) {
      _listOpened = true;
      await filterByLevel(defaultLevel);
    } else if (_lessons.state is ViewFailure) {
      await loadLessons();
    }
  }

  /// Tải lại từ trang đầu với bộ lọc đang chọn, giữ danh sách cũ trong lúc chờ.
  Future<void> loadLessons() {
    final (level, situation, search) = (_level, _situation, _search);
    return _lessons.load(
      (page) => _service.list(page: page, level: level, situation: situation, search: search),
      keepCurrent: true,
    );
  }

  Future<void> loadMore() => _lessons.loadMore();

  /// Lọc theo cấp độ, kéo theo dải chủ đề của cấp đó. `null` là mọi cấp độ.
  ///
  /// Chủ đề đang chọn bị bỏ: một chủ đề có bài ở N5 chưa chắc có bài ở N3, giữ
  /// lại thì danh sách rỗng mà người học không hiểu vì sao.
  Future<void> filterByLevel(String? level) async {
    _level = level;
    _situation = null;
    await Future.wait([loadLessons(), _loadSituations()]);
  }

  /// Lọc theo tình huống thực tế. `null` là mọi chủ đề của cấp đang chọn.
  Future<void> filterBySituation(String? situation) {
    _situation = situation;
    return loadLessons();
  }

  Future<void> searchLessons(String query) {
    final trimmed = query.trim();
    _search = trimmed.isEmpty ? null : trimmed;
    return loadLessons();
  }

  /// Chủ đề chỉ là bộ lọc phụ: lỗi thì dải chủ đề trống, danh sách bài vẫn xem được.
  Future<void> _loadSituations() async {
    final generation = ++_situationsGeneration;
    final result = await ViewState.guard(() => _service.situations(level: _level));
    if (generation != _situationsGeneration) return;
    _situations = result.valueOrNull ?? const [];
    _notify();
  }

  /// Nạp chi tiết một bài.
  ///
  /// Bài đã mở trong phiên hiện ngay từ bộ nhớ rồi mới lặng lẽ làm mới từ
  /// server. Lỗi mạng lúc làm mới thì giữ bản đang hiện thay vì biến trang
  /// thành màn lỗi; bài chưa từng mở thì báo lỗi.
  Future<void> loadLessonDetail(String id) async {
    final generation = ++_detailGeneration;
    final cached = _detailCache[id];
    _detailId = id;
    _detail = cached == null ? const ViewState.loading() : ViewState.data(cached);
    _notify();

    final result = await ViewState.guard(() => _service.detail(id));
    if (result.valueOrNull case final detail?) _detailCache[id] = detail;
    // Người học đã mở bài khác trong lúc chờ: chỉ cất vào bộ nhớ.
    if (generation != _detailGeneration) return;
    if (result.hasData || cached == null) _detail = result;
    _notify();
  }

  /// Xoá toàn bộ state (đăng xuất). Phản hồi đang chạy của phiên trước bị bỏ.
  void clear() {
    _lessons.clear();
    _situationsGeneration++;
    _detailGeneration++;
    _listOpened = false;
    _level = null;
    _situation = null;
    _search = null;
    _situations = const [];
    _detailCache.clear();
    _detailId = null;
    _detail = const ViewState.idle();
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
