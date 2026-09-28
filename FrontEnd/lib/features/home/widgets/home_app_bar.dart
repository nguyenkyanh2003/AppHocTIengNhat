import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/calm_colors.dart';
import 'home_layout.dart';

/// Thanh trên cùng của Trang chủ: logo + tên app bên trái, Thông báo và Cài
/// đặt bên phải. Không có nút làm mới — Trang chủ kéo xuống để làm mới.
///
/// Cùng màu nền với màn. Viền dưới chỉ hiện khi nội dung đã cuộn lên dưới thanh,
/// để lúc đứng yên đầu trang liền một khối, còn khi cuộn thì nội dung không bị
/// cắt ngang đột ngột.
class HomeAppBar extends StatefulWidget implements PreferredSizeWidget {
  const HomeAppBar({super.key, required this.unreadNotifications});

  final int unreadNotifications;

  static const double height = 48;

  @override
  Size get preferredSize => const Size.fromHeight(height);

  @override
  State<HomeAppBar> createState() => _HomeAppBarState();
}

class _HomeAppBarState extends State<HomeAppBar> {
  ScrollNotificationObserverState? _observer;
  bool _scrolledUnder = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _observer?.removeListener(_onScroll);
    _observer = ScrollNotificationObserver.maybeOf(context);
    _observer?.addListener(_onScroll);
  }

  @override
  void dispose() {
    _observer?.removeListener(_onScroll);
    super.dispose();
  }

  /// Chỉ nghe vùng cuộn dọc của chính trang (độ sâu 0): danh sách tin tức cuộn
  /// ngang bên trong không được bật tắt viền.
  void _onScroll(ScrollNotification notification) {
    if (notification.depth != 0 ||
        notification.metrics.axis != Axis.vertical) {
      return;
    }
    final scrolled = notification.metrics.extentBefore > 0;
    if (scrolled != _scrolledUnder) setState(() => _scrolledUnder = scrolled);
  }

  @override
  Widget build(BuildContext context) {
    final calm = CalmColors.of(context);
    final l10n = AppLocalizations.of(context);

    return AppBar(
      toolbarHeight: HomeAppBar.height,
      backgroundColor: calm.background,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleSpacing: HomeLayout.gutter,
      shape: Border(
          bottom: BorderSide(
              color: _scrolledUnder ? calm.cardBorder : Colors.transparent)),
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: calm.green, borderRadius: BorderRadius.circular(10)),
            child: Text(
              '日',
              style:
                  AppTypography.japaneseDisplay(size: 18, color: calm.onGreen)
                      .copyWith(height: 1),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              l10n.appName,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.ui(
                  size: 18, weight: FontWeight.w700, color: calm.textPrimary),
            ),
          ),
        ],
      ),
      actions: [
        _HeaderButton(
          tooltip: 'Thông báo',
          icon: Icons.notifications_none_rounded,
          showDot: widget.unreadNotifications > 0,
          onPressed: () => context.push('/notifications'),
        ),
        _HeaderButton(
          tooltip: 'Cài đặt',
          icon: Icons.settings_outlined,
          onPressed: () => context.push('/settings'),
        ),
        const SizedBox(width: HomeLayout.gutter - 12),
      ],
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.showDot = false,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    final calm = CalmColors.of(context);
    return IconButton(
      tooltip: showDot ? '$tooltip (có thông báo chưa đọc)' : tooltip,
      onPressed: onPressed,
      constraints: const BoxConstraints.tightFor(
          width: HomeLayout.minTap, height: HomeLayout.minTap),
      padding: EdgeInsets.zero,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(icon, size: 22, color: calm.textPrimary),
          if (showDot)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: calm.notificationDot,
                  shape: BoxShape.circle,
                  border: Border.all(color: calm.background, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
