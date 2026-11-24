import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/state/view_state.dart';
import '../models/notification.dart';
import '../services/notification_service.dart';

/// Thông báo mới tới trong lúc app đang mở (quản trị viên gửi, nhóm học…), để
/// báo ngay thay vì chờ người dùng tự mở chuông.
///
/// Hỏi danh sách chưa đọc theo chu kỳ [interval] trong lúc đăng nhập. Lần hỏi
/// được đầu tiên chỉ ghi nhận những gì đã có — mở app không bị báo dồn tin cũ —
/// từ lần sau mới đưa tin mới vào [takeNew]. Thông báo huy hiệu không tính:
/// `AchievementAnnouncer` báo riêng ngay sau lần học.
///
/// Lần hỏi lỗi thì im lặng: người dùng không yêu cầu gì, lần sau hỏi lại.
class NotificationAlerts extends ChangeNotifier {
  NotificationAlerts({NotificationService? service, this.interval = const Duration(minutes: 1)})
      : _service = service ?? NotificationService();

  final NotificationService _service;
  final Duration interval;

  final Set<String> _seen = {};
  final List<AppNotification> _new = [];
  bool _baselined = false;
  Timer? _timer;
  int _session = 0;
  bool _disposed = false;

  /// Bắt đầu theo dõi cho một tài khoản (đổi tài khoản thì bỏ mọi thứ của người trước).
  void start(String userId) {
    stop();
    _timer = Timer.periodic(interval, (_) => unawaited(check()));
    unawaited(check());
  }

  /// Đăng xuất hoặc rời vùng đã đăng nhập.
  void stop() {
    _session++;
    _timer?.cancel();
    _timer = null;
    _seen.clear();
    _new.clear();
    _baselined = false;
  }

  Future<void> check() async {
    final session = _session;
    final result = await ViewState.guard(() => _service.getNotifications(status: NotificationFilter.unread));
    if (session != _session || _disposed) return;
    final items = result.valueOrNull?.items;
    if (items == null) return;

    final arrived = items.where((item) => !_seen.contains(item.id)).toList();
    _seen.addAll(arrived.map((item) => item.id));
    if (!_baselined) {
      _baselined = true;
      return;
    }
    final fresh = arrived.where((item) => item.type != NotificationType.achievement).toList();
    if (fresh.isEmpty) return;
    _new.addAll(fresh);
    notifyListeners();
  }

  /// Tin mới chưa báo, mới nhất trước; lấy ra là xoá khỏi hàng chờ.
  List<AppNotification> takeNew() {
    final taken = [..._new];
    _new.clear();
    return taken;
  }

  @override
  void dispose() {
    _disposed = true;
    stop();
    super.dispose();
  }
}
