import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/state/view_state.dart';
import '../models/notification.dart';
import '../services/notification_service.dart';

/// Báo ngay khi người học vừa nhận huy hiệu.
///
/// Server ghi một thông báo `ACHIEVEMENT` trong **cùng transaction** cấp huy
/// hiệu, nên thông báo chưa đọc loại này chính là "huy hiệu chưa báo". Provider
/// hỏi chúng sau mỗi lệnh ghi hoạt động học (nghe [ApiClient]) và khi mở Trang
/// chủ; huy hiệu mới vào [takePending] để `AchievementToastHost` hiện, rồi được
/// đánh dấu đã đọc qua [markShown] để không báo lại ở lần mở app sau hay trên
/// thiết bị khác. Thông báo vẫn nằm trong màn Thông báo.
///
/// Lần hỏi lỗi thì im lặng: người học không yêu cầu gì nên không có gì để báo
/// lỗi, và lần ghi hay lần mở Trang chủ sau sẽ hỏi lại.
class AchievementAnnouncer extends ChangeNotifier {
  AchievementAnnouncer({
    NotificationService? service,
    bool listenToWrites = true,
    this.settle = const Duration(milliseconds: 600),
  }) : _service = service ?? NotificationService() {
    if (listenToWrites) {
      _api = ApiClient()..addWriteListener(onWrite);
    }
  }

  /// Chờ sau lệnh ghi cuối trước khi hỏi: học liền tay (ôn nhiều thẻ, đánh dấu
  /// nhiều mục) chỉ tốn một lần hỏi.
  final Duration settle;

  /// Các lệnh ghi có thể cấp huy hiệu — đúng những chỗ backend gọi
  /// `recordActivity` hoặc `awardEarnedAchievements`. Thêm đường cấp huy hiệu
  /// mới ở backend thì thêm ở đây.
  static final learningWrites = <RegExp>[
    RegExp(r'^/lesson-progress/lesson/[^/]+/(update|complete)$'),
    RegExp(r'^/exercise/submit/[^/]+$'),
    RegExp(r'^/jlpt/[^/]+/submit$'),
    RegExp(r'^/srs/review$'),
    RegExp(r'^/vocabulary/[^/]+/mark-learned$'),
  ];

  static bool isLearningWrite(String method, String endpoint) =>
      method == 'POST' && learningWrites.any((pattern) => pattern.hasMatch(endpoint));

  final NotificationService _service;
  ApiClient? _api;
  Timer? _timer;

  final List<AppNotification> _pending = [];

  /// Huy hiệu đã đưa ra trong phiên này. Giữ cả khi đánh dấu đã đọc lỗi, để
  /// không báo một huy hiệu hai lần trong lúc server chưa ghi nhận.
  final Set<String> _announced = {};
  int _session = 0;
  bool _disposed = false;

  /// Một lệnh ghi vừa thành công; hoạt động học thì hẹn hỏi sau [settle].
  void onWrite(String method, String endpoint) {
    if (!isLearningWrite(method, endpoint)) return;
    _timer?.cancel();
    _timer = Timer(settle, () => unawaited(check()));
  }

  /// Hỏi server các huy hiệu chưa báo.
  Future<void> check() async {
    final session = _session;
    final result = await ViewState.guard(
      () => _service.getNotifications(
        status: NotificationFilter.unread,
        type: NotificationType.achievement,
      ),
    );
    if (session != _session || _disposed) return;
    if (result case ViewData(:final value)) {
      // API trả mới nhất trước; báo theo thứ tự nhận.
      final fresh = value.items.reversed.where((item) => _announced.add(item.id)).toList();
      if (fresh.isEmpty) return;
      _pending.addAll(fresh);
      notifyListeners();
    }
  }

  /// Lấy và xoá các huy hiệu đang chờ hiện.
  List<AppNotification> takePending() {
    final taken = List<AppNotification>.of(_pending);
    _pending.clear();
    return taken;
  }

  /// Đã hiện cho người học: đánh dấu đã đọc. Lỗi ở một thông báo không chặn
  /// các thông báo còn lại.
  Future<void> markShown(List<AppNotification> shown) async {
    final session = _session;
    for (final notification in shown) {
      if (session != _session) return;
      await ViewState.guard(() => _service.markAsRead(notification.id));
    }
  }

  /// Đăng xuất: bỏ huy hiệu đang chờ, lần hỏi đang hẹn và phản hồi đang về.
  void clear() {
    _session++;
    _timer?.cancel();
    _timer = null;
    _pending.clear();
    _announced.clear();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _api?.removeWriteListener(onWrite);
    super.dispose();
  }
}
