import 'package:flutter/material.dart';

import '../localization/app_localizations.dart';
import '../theme/app_tokens.dart';

/// Một mục dẫn tới màn hình cụ thể bên trong một nhóm.
@immutable
class AppNavEntry {
  const AppNavEntry({
    required this.path,
    required this.label,
    required this.icon,
    required this.color,
    this.subtitle,
  });

  final String path;
  final String label;
  final String? subtitle;
  final IconData icon;
  final Color color;
}

/// Một đích đến của thanh điều hướng chính.
///
/// [entries] rỗng nghĩa là đích đến này tự nó là một màn hình (`/home`,
/// `/progress`); có phần tử nghĩa là nó là trang hub liệt kê các mục con.
@immutable
class AppDestination {
  const AppDestination({
    required this.path,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    this.entries = const [],
    this.adminOnly = false,
  });

  final String path;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final List<AppNavEntry> entries;
  final bool adminOnly;

  bool get isHub => entries.isNotEmpty;
}

/// Nguồn sự thật duy nhất của điều hướng chính.
///
/// Thanh dưới, rail và các trang hub đều đọc từ đây, nên mobile và desktop
/// không thể lệch danh sách đích đến.
abstract final class AppNavigation {
  static List<AppDestination> destinations(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return [
      AppDestination(
        path: '/home',
        label: l10n.home,
        icon: Icons.home_outlined,
        selectedIcon: Icons.home,
      ),
      AppDestination(
        path: '/study',
        label: l10n.lessons,
        icon: Icons.school_outlined,
        selectedIcon: Icons.school,
        entries: const [
          AppNavEntry(
            path: '/lessons',
            label: 'Bài học',
            subtitle: 'Học theo lộ trình',
            icon: Icons.menu_book,
            color: AppColors.lesson,
          ),
          AppNavEntry(
            path: '/vocabulary',
            label: 'Từ vựng',
            subtitle: 'Tra cứu và bộ thẻ',
            icon: Icons.spellcheck,
            color: AppColors.vocabulary,
          ),
          AppNavEntry(
            path: '/kanji',
            label: 'Kanji',
            subtitle: 'Chữ Hán theo cấp độ',
            icon: Icons.draw_outlined,
            color: AppColors.kanji,
          ),
          AppNavEntry(
            path: '/grammar',
            label: 'Ngữ pháp',
            subtitle: 'Mẫu câu và cách dùng',
            icon: Icons.rule,
            color: AppColors.grammar,
          ),
          AppNavEntry(
            path: '/exercise',
            label: 'Bài tập',
            subtitle: 'Luyện tập theo chủ đề',
            icon: Icons.quiz_outlined,
            color: AppColors.exercise,
          ),
          AppNavEntry(
            path: '/jlpt',
            label: 'JLPT',
            subtitle: 'Đề thi thử',
            icon: Icons.workspace_premium_outlined,
            color: AppColors.jlpt,
          ),
          AppNavEntry(
            path: '/news',
            label: 'Tin tức',
            subtitle: 'Đọc hiểu tiếng Nhật',
            icon: Icons.newspaper,
            color: AppColors.news,
          ),
          AppNavEntry(
            path: '/search',
            label: 'Tìm kiếm',
            subtitle: 'Tra toàn bộ nội dung',
            icon: Icons.search,
            color: AppColors.info,
          ),
        ],
      ),
      AppDestination(
        path: '/review',
        label: l10n.review,
        icon: Icons.style_outlined,
        selectedIcon: Icons.style,
        entries: const [
          AppNavEntry(
            path: '/flashcards',
            label: 'Bộ thẻ',
            subtitle: 'Ôn tập lặp ngắt quãng',
            icon: Icons.style,
            color: AppColors.vocabulary,
          ),
          AppNavEntry(
            path: '/streak',
            label: 'Chuỗi học',
            subtitle: 'Giữ nhịp mỗi ngày',
            icon: Icons.local_fire_department,
            color: AppColors.warning,
          ),
          AppNavEntry(
            path: '/achievements',
            label: 'Thành tích',
            subtitle: 'Huy hiệu đã đạt',
            icon: Icons.emoji_events,
            color: AppColors.secondary,
          ),
          AppNavEntry(
            path: '/notebook',
            label: 'Sổ tay',
            subtitle: 'Ghi chú của bạn',
            icon: Icons.book_outlined,
            color: AppColors.notebook,
          ),
          AppNavEntry(
            path: '/study-groups',
            label: 'Nhóm học',
            subtitle: 'Học cùng bạn bè',
            icon: Icons.groups_outlined,
            color: AppColors.group,
          ),
        ],
      ),
      AppDestination(
        path: '/progress',
        label: l10n.progress,
        icon: Icons.insights_outlined,
        selectedIcon: Icons.insights,
      ),
      AppDestination(
        path: '/account',
        label: l10n.account,
        icon: Icons.person_outline,
        selectedIcon: Icons.person,
        entries: const [
          AppNavEntry(
            path: '/profile',
            label: 'Hồ sơ',
            subtitle: 'Thông tin cá nhân',
            icon: Icons.badge_outlined,
            color: AppColors.primary,
          ),
          AppNavEntry(
            path: '/settings',
            label: 'Cài đặt',
            subtitle: 'Ngôn ngữ, giao diện',
            icon: Icons.settings_outlined,
            color: AppColors.textSecondary,
          ),
          AppNavEntry(
            path: '/notifications',
            label: 'Thông báo',
            subtitle: 'Tin nhắn và nhắc nhở',
            icon: Icons.notifications_outlined,
            color: AppColors.info,
          ),
          AppNavEntry(
            path: '/notification-settings',
            label: 'Cài đặt thông báo',
            subtitle: 'Chọn loại nhắc nhở',
            icon: Icons.notifications_active_outlined,
            color: AppColors.info,
          ),
          AppNavEntry(
            path: '/offline-mode',
            label: 'Ngoại tuyến',
            subtitle: 'Dữ liệu đã tải sẵn',
            icon: Icons.cloud_off_outlined,
            color: AppColors.textSecondary,
          ),
          AppNavEntry(
            path: '/export',
            label: 'Xuất dữ liệu',
            subtitle: 'Tải bản sao dữ liệu học',
            icon: Icons.download_outlined,
            color: AppColors.accent,
          ),
          AppNavEntry(
            path: '/payment',
            label: 'Nâng cấp',
            subtitle: 'Gói học và thanh toán',
            icon: Icons.workspace_premium,
            color: AppColors.secondary,
          ),
          AppNavEntry(
            path: '/report',
            label: 'Báo lỗi',
            subtitle: 'Gửi phản hồi nội dung',
            icon: Icons.flag_outlined,
            color: AppColors.error,
          ),
          AppNavEntry(
            path: '/help',
            label: 'Trợ giúp',
            subtitle: 'Câu hỏi thường gặp',
            icon: Icons.help_outline,
            color: AppColors.textSecondary,
          ),
          AppNavEntry(
            path: '/change-password',
            label: 'Đổi mật khẩu',
            subtitle: 'Bảo mật tài khoản',
            icon: Icons.lock_outline,
            color: AppColors.textSecondary,
          ),
        ],
      ),
      const AppDestination(
        path: '/admin',
        label: 'Quản trị',
        icon: Icons.admin_panel_settings_outlined,
        selectedIcon: Icons.admin_panel_settings,
        adminOnly: true,
        entries: [
          AppNavEntry(
            path: '/admin/dashboard',
            label: 'Bảng điều khiển',
            subtitle: 'Số liệu tổng quan',
            icon: Icons.dashboard_outlined,
            color: AppColors.primary,
          ),
          AppNavEntry(
            path: '/admin/users',
            label: 'Người dùng',
            subtitle: 'Tài khoản và phân quyền',
            icon: Icons.people_outline,
            color: AppColors.info,
          ),
          AppNavEntry(
            path: '/admin/content',
            label: 'Nội dung',
            subtitle: 'Bài học, từ vựng, kanji',
            icon: Icons.library_books_outlined,
            color: AppColors.lesson,
          ),
          AppNavEntry(
            path: '/admin/reports',
            label: 'Báo cáo',
            subtitle: 'Phản hồi từ người học',
            icon: Icons.flag_outlined,
            color: AppColors.error,
          ),
          AppNavEntry(
            path: '/admin/achievements',
            label: 'Thành tích',
            subtitle: 'Huy hiệu và điều kiện',
            icon: Icons.emoji_events_outlined,
            color: AppColors.secondary,
          ),
          AppNavEntry(
            path: '/admin/analytics',
            label: 'Thống kê',
            subtitle: 'Hoạt động hệ thống',
            icon: Icons.analytics_outlined,
            color: AppColors.progress,
          ),
          AppNavEntry(
            path: '/admin/transactions',
            label: 'Giao dịch',
            subtitle: 'Lịch sử thanh toán',
            icon: Icons.receipt_long_outlined,
            color: AppColors.accent,
          ),
        ],
      ),
    ];
  }

  /// Đích đến hiển thị cho một người dùng, theo quyền.
  static List<AppDestination> visibleDestinations(
    BuildContext context, {
    required bool isAdmin,
  }) =>
      destinations(context)
          .where((d) => !d.adminOnly || isAdmin)
          .toList(growable: false);

  /// Chỉ số đích đến đang mở, suy từ URL hiện tại.
  ///
  /// Trả `-1` khi trang hiện tại không thuộc đích đến nào, để shell không tô
  /// sáng nhầm mục.
  static int indexOfLocation(
    List<AppDestination> destinations,
    String location,
  ) {
    var best = -1;
    var bestLength = 0;
    for (var i = 0; i < destinations.length; i++) {
      final path = destinations[i].path;
      final matches = location == path || location.startsWith('$path/');
      if (matches && path.length > bestLength) {
        best = i;
        bestLength = path.length;
      }
    }
    return best;
  }
}
