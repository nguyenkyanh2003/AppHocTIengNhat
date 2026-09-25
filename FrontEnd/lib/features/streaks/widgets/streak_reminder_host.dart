import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/theme/app_tokens.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/streak_provider.dart';
import '../services/streak_reminder.dart';

/// Gắn bộ nhắc học vào vùng đã đăng nhập (spec §5.3).
///
/// Đặt ở `ShellRoute` của router chứ không trong `AppShell`: nhiều widget test
/// dựng thẳng `AppShell` mà không có `StreakProvider`, và nhắc học chỉ có nghĩa
/// khi người dùng đang ở trong app thật. Rời vùng đăng nhập là host bị gỡ, lịch
/// nhắc dừng theo.
class StreakReminderHost extends StatefulWidget {
  const StreakReminderHost({super.key, required this.child, this.clock, this.preferences});

  final Widget child;

  /// Mở ra cho test; mã chạy thật để trống.
  final DateTime Function()? clock;
  final Future<SharedPreferences> Function()? preferences;

  @override
  State<StreakReminderHost> createState() => _StreakReminderHostState();
}

class _StreakReminderHostState extends State<StreakReminderHost> with WidgetsBindingObserver {
  static const bannerKey = Key('streak-reminder-banner');

  StreakReminderScheduler? _scheduler;
  StreakProvider? _streak;
  ScaffoldMessengerState? _messenger;
  String? _userId;

  /// Cài đặt nhắc lần cuối đã lập lịch theo; provider báo nhiều lần (mỗi lần
  /// tải tóm tắt) nên chỉ lập lịch lại khi chính cài đặt nhắc đổi.
  (bool, String)? _scheduledFor;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _messenger = ScaffoldMessenger.maybeOf(context);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final streak = _streak;
    if (state != AppLifecycleState.resumed || streak == null) return;
    if (streak.settings.hasData) {
      _scheduler?.reschedule();
    } else if (!streak.settings.isLoading) {
      // Lần tải cài đặt trước hỏng (mất mạng): quay lại app là lúc thử lại;
      // tải xong thì listener tự lập lịch.
      streak.loadSettings();
    }
  }

  void _attach(String? userId) {
    if (userId == _userId) return;
    _detach();
    _userId = userId;
    if (userId == null) return;

    final streak = context.read<StreakProvider>();
    _streak = streak..addListener(_onStreakChanged);
    _scheduler = StreakReminderScheduler(
      userId: userId,
      readSettings: () => streak.settings.valueOrNull,
      syncStudiedToday: () async =>
          await streak.loadStreak() ? streak.currentStreak?.studiedToday ?? false : null,
      showReminder: _showBanner,
      preferences: widget.preferences,
      clock: widget.clock,
    );

    if (streak.settings.hasData) {
      _onStreakChanged();
    } else {
      streak.loadSettings();
    }
  }

  void _detach() {
    _streak?.removeListener(_onStreakChanged);
    _streak = null;
    _scheduler?.dispose();
    _scheduler = null;
    _scheduledFor = null;
  }

  void _onStreakChanged() {
    final settings = _streak?.settings.valueOrNull;
    if (settings == null) return;
    final current = (settings.reminderEnabled, settings.reminderTime);
    if (current == _scheduledFor) return;
    _scheduledFor = current;
    _scheduler?.reschedule();
  }

  void _showBanner() {
    final messenger = _messenger;
    if (!mounted || messenger == null) return;
    messenger
      ..clearMaterialBanners()
      ..showMaterialBanner(
        MaterialBanner(
          key: bannerKey,
          leading: const Icon(Icons.local_fire_department, color: AppColors.streak),
          // Không khẳng định chuỗi sẽ đứt: băng có thể che, và còn cả buổi tối.
          content: const Text('Hôm nay bạn chưa học bài nào. Dành vài phút ôn tập nhé?'),
          actions: [
            TextButton(
              onPressed: messenger.hideCurrentMaterialBanner,
              child: const Text('Để sau'),
            ),
            FilledButton(
              onPressed: () {
                messenger.hideCurrentMaterialBanner();
                if (mounted) GoRouter.maybeOf(context)?.go('/review');
              },
              child: const Text('Ôn tập ngay'),
            ),
          ],
        ),
      );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _detach();
    // Banner nằm ở messenger gốc, sống lâu hơn host: không dọn thì nó còn treo
    // trên màn đăng nhập sau khi đăng xuất. Dọn sau frame vì lúc gỡ cây không
    // được yêu cầu dựng lại widget khác.
    final messenger = _messenger;
    if (messenger != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (messenger.mounted) messenger.clearMaterialBanners();
      });
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.select<AuthProvider, String?>((auth) => auth.user?.id);
    if (userId != _userId) {
      // Gắn sau frame: gắn sẽ tải cài đặt, và tải thì báo listener.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _attach(userId);
      });
    }
    return widget.child;
  }
}
