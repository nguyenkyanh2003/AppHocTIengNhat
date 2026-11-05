import 'package:flutter/material.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import 'admin_user_style.dart';
import 'admin_user_actions_menu.dart';
import 'admin_user_status_badge.dart';

/// Một người dùng ở khổ hẹp.
class AdminUserCard extends StatelessWidget {
  const AdminUserCard({
    super.key,
    required this.user,
  });

  final Map<String, dynamic> user;

  /// Ngày từ API là chuỗi ISO; giá trị khác ("Chưa có") giữ nguyên.
  String _date(Object? value) {
    final text = (value ?? '').toString();
    final date = DateTime.tryParse(text)?.toLocal();
    if (date == null) return text;
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final displayName = user['name']?.toString().trim() ?? '';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: adminUserRoleColor(user['role']),
          child: Text(
            displayName.isEmpty
                ? '?'
                : displayName.characters.first.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              displayName.isEmpty ? 'Chưa đặt tên' : displayName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            AdminUserStatusBadge(status: user['status']),
            if (user['role'] == 'admin') ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'ADMIN',
                  style: TextStyle(
                    fontSize: AppTypography.caption,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          user['email'],
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: AdminUserActionsMenu(user: user),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        context,
                        '📅 Tham gia',
                        _date(user['joinDate']),
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        context,
                        '🕐 Hoạt động',
                        _date(user['lastActive']),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        context,
                        '✨ Tổng XP',
                        user['totalXP'].toString(),
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        context,
                        '🔥 Chuỗi ngày',
                        '${user['streak']} ngày',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: AppTypography.caption,
            color: context.colors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: AppTypography.bodySmall,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
