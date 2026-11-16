import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../models/admin_user.dart';
import 'admin_user_actions_menu.dart';
import 'admin_user_status_badge.dart';
import 'admin_user_style.dart';

/// Một người dùng ở khổ hẹp.
class AdminUserCard extends StatelessWidget {
  const AdminUserCard({super.key, required this.user});

  final AdminUser user;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: adminUserRoleColor(user),
          child: Text(
            adminUserInitial(user),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              user.displayName.isEmpty ? 'Chưa đặt tên' : user.displayName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            AdminUserStatusBadge(status: user.status),
            if (user.isAdmin)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(12)),
                child: const Text(
                  'ADMIN',
                  style: TextStyle(fontSize: AppTypography.caption, fontWeight: FontWeight.bold, color: AppColors.ink),
                ),
              ),
          ],
        ),
        subtitle: Text(user.email, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: AdminUserActionsMenu(user: user),
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _Info('📅 Tham gia', adminDate(user.joinedAt))),
                    Expanded(child: _Info('🕐 Đăng nhập', adminDate(user.lastActiveAt))),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(child: _Info('✨ Tổng XP', '${user.totalXp}')),
                    Expanded(child: _Info('🔥 Chuỗi ngày', '${user.streak} ngày')),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: AppTypography.caption, color: context.colors.textSecondary)),
        const SizedBox(height: AppSpacing.xs),
        Text(value, style: const TextStyle(fontSize: AppTypography.bodySmall, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
