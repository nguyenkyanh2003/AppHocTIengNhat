import 'package:flutter/foundation.dart';

import '../../../core/state/view_state.dart';
import '../models/notification.dart';
import '../services/notification_service.dart';

/// Thông báo của người đang đăng nhập — dùng chung cho màn Thông báo và chấm
/// trên chuông Trang chủ, nên đọc hay xoá ở một nơi thì nơi kia cập nhật theo.
///
/// Danh sách, bộ đếm và các thao tác có bộ đếm generation riêng: đổi bộ lọc,
/// đổi trang hay đăng xuất biến phản hồi đang chờ thành phản hồi cũ, và phản
/// hồi cũ không được chạm vào state.
class NotificationProvider extends ChangeNotifier {
  NotificationProvider({NotificationService? service})
      : _service = service ?? NotificationService();

  final NotificationService _service;

  ViewState<NotificationPage> _page = const ViewState.idle();
  NotificationFilter _filter = NotificationFilter.all;
  int _currentPage = 1;
  int? _unreadCount;
  final Set<String> _busy = {};
  bool _markingAll = false;
  String? _message;

  int _listGeneration = 0;
  int _countGeneration = 0;
  int _session = 0;
  bool _disposed = false;

  ViewState<NotificationPage> get page => _page;
  NotificationFilter get filter => _filter;
  int get currentPage => _currentPage;

  /// Số chưa đọc đã biết gần nhất; lần đếm lỗi không xoá số này về 0.
  int get unreadCount => _unreadCount ?? 0;

  bool isBusy(String id) => _busy.contains(id);
  bool get isMarkingAll => _markingAll;

  /// Thông báo lỗi của thao tác gần nhất, màn hình hiện một lần bằng snackbar.
  String? consumeMessage() {
    final message = _message;
    _message = null;
    return message;
  }

  /// Tải trang [page] của bộ lọc [filter] (giữ bộ lọc hiện tại nếu bỏ trống).
  Future<void> load({NotificationFilter? filter, int page = 1}) {
    _filter = filter ?? _filter;
    _currentPage = page;
    return _fetch(showLoading: true);
  }

  Future<void> refreshUnreadCount() async {
    final generation = ++_countGeneration;
    final result = await ViewState.guard(_service.unreadCount);
    if (generation != _countGeneration) return;
    if (result case ViewData(:final value)) {
      _unreadCount = value;
      _notify();
    }
  }

  Future<void> markAsRead(AppNotification notification) async {
    if (notification.isRead) return;
    await _mutate(notification.id, () => _service.markAsRead(notification.id));
  }

  /// Xoá được cả thông báo đã đọc lẫn chưa đọc.
  Future<void> delete(AppNotification notification) =>
      _mutate(notification.id, () => _service.deleteNotification(notification.id));

  Future<void> markAllAsRead() async {
    if (_markingAll) return;
    _markingAll = true;
    _notify();

    final session = _session;
    final result = await ViewState.guard(_service.markAllAsRead);
    if (session != _session) return;
    _markingAll = false;
    await _afterChange(result);
  }

  /// Đăng xuất: bỏ dữ liệu của tài khoản cũ và mọi phản hồi đang chờ.
  void clear() {
    _listGeneration++;
    _countGeneration++;
    _session++;
    _page = const ViewState.idle();
    _filter = NotificationFilter.all;
    _currentPage = 1;
    _unreadCount = null;
    _busy.clear();
    _markingAll = false;
    _message = null;
    _notify();
  }

  Future<void> _fetch({required bool showLoading}) async {
    final generation = ++_listGeneration;
    if (showLoading || !_page.hasData) {
      _page = const ViewState.loading();
      _notify();
    }

    final result = await ViewState.guard(
      () => _service.getNotifications(page: _currentPage, status: _filter),
    );
    if (generation != _listGeneration) return;

    // Trang đang xem đã trống (vừa xoá hết trang cuối): lùi về trang cuối còn dữ liệu.
    if (result case ViewData(:final value) when value.items.isEmpty && _currentPage > 1) {
      final lastPage = value.totalPages < 1 ? 1 : value.totalPages;
      _currentPage = lastPage < _currentPage ? lastPage : _currentPage - 1;
      return _fetch(showLoading: false);
    }

    // Làm mới ngầm sau một thao tác mà lỗi: giữ danh sách đang có, chỉ báo lỗi.
    if (result case ViewFailure(:final message) when !showLoading && _page.hasData) {
      _message = message;
    } else {
      _page = result;
    }
    _notify();
  }

  Future<void> _mutate(String id, Future<void> Function() action) async {
    if (!_busy.add(id)) return;
    _notify();

    final session = _session;
    final result = await ViewState.guard(action);
    if (session != _session) return;
    _busy.remove(id);
    await _afterChange(result);
  }

  /// Sau đọc/xoá: tải lại trang đang xem (không chớp trạng thái đang tải) và bộ đếm.
  Future<void> _afterChange(ViewState<Object?> result) async {
    if (result case ViewFailure(:final message)) {
      _message = message;
      _notify();
      return;
    }
    await Future.wait([_fetch(showLoading: false), refreshUnreadCount()]);
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
