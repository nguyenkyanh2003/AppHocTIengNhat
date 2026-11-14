import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/widgets/adaptive_table.dart';
import 'admin_user_actions_menu.dart';
import 'admin_user_status_badge.dart';
import 'admin_user_style.dart';

/// Cột của bảng người dùng trên vùng rộng.
///
/// Cùng dữ liệu với thẻ ở màn hẹp, chỉ khác cách bày: tên, email, vai trò,
/// trạng thái và cùng một menu thao tác.
List<AdaptiveColumn<Map<String, dynamic>>> adminUserColumns() => [
      AdaptiveColumn(
        label: 'Người dùng',
        minWidth: 200,
        cell: (context, user) {
          final name = user['name']?.toString().trim() ?? '';
          return Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: adminUserRoleColor(user['role']),
                child: Text(
                  name.isEmpty ? '?' : name.characters.first.toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: AppTypography.caption),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(name.isEmpty ? 'Chưa đặt tên' : name, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          );
        },
      ),
      AdaptiveColumn(
        label: 'Email',
        minWidth: 220,
        cell: (context, user) =>
            Text(user['email']?.toString() ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      AdaptiveColumn(
        label: 'Vai trò',
        width: 110,
        cell: (context, user) => Text(user['role']?.toString() ?? 'user'),
      ),
      AdaptiveColumn(
        label: 'Trạng thái',
        width: 120,
        cell: (context, user) => AdminUserStatusBadge(status: user['status']),
      ),
      AdaptiveColumn(
        label: 'Thao tác',
        width: 72,
        alignEnd: true,
        cell: (context, user) => AdminUserActionsMenu(user: user),
      ),
    ];

/// Đếm nhanh người dùng theo trạng thái và vai trò, trên toàn bộ danh sách (không theo bộ lọc).
class AdminUserStatsBar extends StatelessWidget {
  const AdminUserStatsBar({super.key, required this.users});

  final List<Map<String, dynamic>> users;

  @override
  Widget build(BuildContext context) {
    int count(bool Function(Map<String, dynamic> user) test) => users.where(test).length;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.lg),
      color: context.colors.primarySoft,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Stat(value: users.length, label: 'Tổng Users'),
          _Stat(value: count((user) => user['status'] == 'active'), label: 'Active'),
          _Stat(value: count((user) => user['role'] == 'admin'), label: 'Admin'),
          _Stat(value: count((user) => user['status'] == 'banned'), label: 'Banned'),
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
          Text(label, style: TextStyle(fontSize: AppTypography.caption, color: context.colors.textSecondary)),
        ],
      ),
    );
  }
}
