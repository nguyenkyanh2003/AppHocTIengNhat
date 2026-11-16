import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/widgets/adaptive_table.dart';
import '../models/admin_user.dart';
import 'admin_user_actions_menu.dart';
import 'admin_user_status_badge.dart';
import 'admin_user_style.dart';

/// Cột của bảng người dùng trên vùng rộng.
///
/// Cùng dữ liệu với thẻ ở màn hẹp, chỉ khác cách bày: tên, email, vai trò,
/// trạng thái và cùng một menu thao tác.
List<AdaptiveColumn<AdminUser>> adminUserColumns() => [
      AdaptiveColumn(
        label: 'Người dùng',
        minWidth: 200,
        cell: (context, user) => Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: adminUserRoleColor(user),
              child: Text(
                adminUserInitial(user),
                style: const TextStyle(color: Colors.white, fontSize: AppTypography.caption),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                user.displayName.isEmpty ? 'Chưa đặt tên' : user.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      AdaptiveColumn(
        label: 'Email',
        minWidth: 220,
        cell: (context, user) => Text(user.email, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      AdaptiveColumn(
        label: 'Vai trò',
        width: 120,
        cell: (context, user) => Text(user.isAdmin ? 'Quản trị viên' : 'Người học'),
      ),
      AdaptiveColumn(
        label: 'Trạng thái',
        width: 120,
        cell: (context, user) => Align(
          alignment: Alignment.centerLeft,
          child: AdminUserStatusBadge(status: user.status),
        ),
      ),
      AdaptiveColumn(
        label: 'Thao tác',
        width: 72,
        alignEnd: true,
        cell: (context, user) => AdminUserActionsMenu(user: user),
      ),
    ];

/// Số tài khoản theo trạng thái và vai trò trên toàn hệ thống (không theo bộ lọc).
class AdminUserStatsBar extends StatelessWidget {
  const AdminUserStatsBar({super.key, required this.stats});

  final AdminUserStats stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.lg),
      color: context.colors.primarySoft,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Stat(value: stats.total, label: 'Tài khoản'),
          _Stat(value: stats.active, label: 'Hoạt động'),
          _Stat(value: stats.admins, label: 'Quản trị'),
          _Stat(value: stats.banned, label: 'Bị khoá'),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontSize: AppTypography.subtitle,
              fontWeight: FontWeight.bold,
              color: context.colors.primary,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: AppTypography.caption, color: context.colors.textSecondary),
          ),
        ],
      ),
    );
  }
}
