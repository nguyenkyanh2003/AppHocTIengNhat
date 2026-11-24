import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_tokens.dart';
import '../../auth/providers/auth_provider.dart';
import '../../settings/providers/settings_provider.dart';
import '../../settings/services/alert_feedback.dart';
import '../models/notification.dart';
import '../providers/notification_alerts.dart';
import '../providers/notification_provider.dart';

/// Báo "thông báo mới" ở mọi màn trong vùng đã đăng nhập khi [NotificationAlerts]
/// thấy tin mới tới.
///
/// Gắn ở `ShellRoute` cạnh nhắc học: chỉ chạy khi đã đăng nhập, rời vùng đó là
/// dừng hỏi. Theo Cài đặt thông báo: tắt "Nhận thông báo" thì không bật lời báo
/// (tin vẫn nằm chưa đọc trong màn Thông báo); âm báo và rung theo hai công tắc kia.
class NotificationAlertHost extends StatefulWidget {
  const NotificationAlertHost({super.key, required this.onOpenNotifications, required this.child});

  /// Nút "Xem" — mở màn Thông báo.
  final VoidCallback onOpenNotifications;
  final Widget child;

  @override
  State<NotificationAlertHost> createState() => _NotificationAlertHostState();
}

class _NotificationAlertHostState extends State<NotificationAlertHost> with WidgetsBindingObserver {
  static const _duration = Duration(seconds: 6);

  NotificationAlerts? _alerts;
  String? _userId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final alerts = context.read<NotificationAlerts>();
    if (identical(alerts, _alerts)) return;
    _alerts?.removeListener(_show);
    _alerts = alerts..addListener(_show);
  }

  /// Quay lại app (từ nền, từ ứng dụng khác) là lúc tin mới hay đã tới.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _userId != null) unawaited(_alerts?.check());
  }

  void _follow(String? userId) {
    if (userId == _userId) return;
    _userId = userId;
    if (userId == null) {
      _alerts?.stop();
    } else {
      _alerts?.start(userId);
    }
  }

  void _show() {
    final alerts = _alerts;
    if (alerts == null || !mounted) return;
    final notices = alerts.takeNew();
    final settings = context.read<SettingsProvider>().settings;
    if (notices.isEmpty || !settings.notificationsEnabled) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        key: const ValueKey('notification-alert'),
        behavior: SnackBarBehavior.floating,
        duration: _duration,
        content: _AlertContent(notices: notices),
        action: SnackBarAction(label: 'Xem', onPressed: widget.onOpenNotifications),
      ));
    unawaited(context.read<AlertFeedback>().alert(settings));
    unawaited(context.read<NotificationProvider>().refreshUnreadCount());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _alerts?.removeListener(_show);
    _alerts?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.select<AuthProvider, String?>((auth) => auth.user?.id);
    if (userId != _userId) {
      // Sau frame: bắt đầu hỏi là gọi mạng, rồi báo listener.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _follow(userId);
      });
    }
    return widget.child;
  }
}

/// Một tin: tiêu đề và nội dung. Nhiều tin: số lượng và các tiêu đề.
class _AlertContent extends StatelessWidget {
  const _AlertContent({required this.notices});

  final List<AppNotification> notices;

  @override
  Widget build(BuildContext context) {
    final single = notices.length == 1;
    final title = single ? notices.single.title : 'Bạn có ${notices.length} thông báo mới';
    final detail = single ? notices.single.message : notices.map((notice) => notice.title).join(', ');

    return Row(
      children: [
        // Chuông theo màu chữ SnackBar đang dùng, nên nổi trên nền lời báo ở cả hai chế độ.
        Icon(Icons.notifications_active_outlined, color: DefaultTextStyle.of(context).style.color),
        AppGap.md,
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              AppGap.xs,
              Text(detail, maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}
