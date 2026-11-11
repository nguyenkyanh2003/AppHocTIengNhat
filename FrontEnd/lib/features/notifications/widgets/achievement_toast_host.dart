import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../models/notification.dart';
import '../providers/achievement_announcer.dart';
import '../providers/notification_provider.dart';

/// Hiện lời báo "Huy hiệu mới" ở bất kỳ màn nào khi [AchievementAnnouncer] có
/// huy hiệu vừa nhận. Gắn một lần ở `MaterialApp.builder`, dưới
/// `ScaffoldMessenger` của app, nên báo được cả khi đang ở màn học toàn màn hình.
class AchievementToastHost extends StatefulWidget {
  const AchievementToastHost({
    super.key,
    required this.onOpenAchievements,
    required this.child,
  });

  /// Nút "Xem" — mở màn Thành tích.
  final VoidCallback onOpenAchievements;
  final Widget child;

  @override
  State<AchievementToastHost> createState() => _AchievementToastHostState();
}

class _AchievementToastHostState extends State<AchievementToastHost> {
  static const _duration = Duration(seconds: 6);

  AchievementAnnouncer? _announcer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final announcer = context.read<AchievementAnnouncer>();
    if (identical(announcer, _announcer)) return;
    _announcer?.removeListener(_show);
    _announcer = announcer..addListener(_show);
  }

  @override
  void dispose() {
    _announcer?.removeListener(_show);
    super.dispose();
  }

  void _show() {
    final announcer = _announcer;
    if (announcer == null || !mounted) return;
    final badges = announcer.takePending();
    if (badges.isEmpty) return;

    // Huy hiệu chỉ đến sau một lần lưu thành công, nên lời báo đang hiện gần như
    // chắc là "đã lưu" của chính lần đó: thay nó, đừng xếp hàng chờ 4 giây phía sau.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        key: const ValueKey('achievement-toast'),
        behavior: SnackBarBehavior.floating,
        duration: _duration,
        content: _AchievementToastContent(badges: badges),
        action: SnackBarAction(label: 'Xem', onPressed: widget.onOpenAchievements),
      ));

    final notifications = context.read<NotificationProvider>();
    unawaited(announcer.markShown(badges).then((_) => notifications.refreshUnreadCount()));
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Một huy hiệu: tên và tiêu chí vừa đạt. Nhiều huy hiệu: số lượng và tên.
class _AchievementToastContent extends StatelessWidget {
  const _AchievementToastContent({required this.badges});

  final List<AppNotification> badges;

  @override
  Widget build(BuildContext context) {
    final single = badges.length == 1;
    final title = single ? badges.single.title : 'Bạn vừa nhận ${badges.length} huy hiệu mới';
    final detail = single
        ? badges.single.message
        : badges.map((badge) => badge.badgeName ?? badge.title).join(', ');
    // Emoji tự mang màu nên đọc rõ trên nền SnackBar ở cả hai chế độ sáng/tối.
    final icon = (single ? badges.single.badgeIcon : null) ?? '🏆';

    return Row(
      children: [
        ExcludeSemantics(child: Text(icon, style: const TextStyle(fontSize: AppTypography.headline))),
        AppGap.md,
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              AppGap.xs,
              Text(detail, maxLines: 3, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}
