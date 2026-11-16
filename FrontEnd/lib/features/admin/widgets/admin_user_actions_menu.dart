import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../models/admin_user.dart';
import 'admin_user_actions.dart';

/// Menu thao tác của một người dùng.
class AdminUserActionsMenu extends StatelessWidget {
  const AdminUserActionsMenu({super.key, required this.user});

  final AdminUser user;

  @override
  Widget build(BuildContext context) {
    PopupMenuItem<AdminUserAction> item(AdminUserAction action, IconData icon, String label, {bool danger = false}) {
      final color = danger ? context.colors.error : null;
      return PopupMenuItem(
        value: action,
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: AppSpacing.sm),
            Flexible(child: Text(label, style: TextStyle(color: color))),
          ],
        ),
      );
    }

    return PopupMenuButton<AdminUserAction>(
      tooltip: 'Thao tác',
      itemBuilder: (context) => [
        item(AdminUserAction.view, Icons.visibility, 'Xem chi tiết'),
        item(AdminUserAction.notify, Icons.notifications_outlined, 'Gửi thông báo'),
        item(AdminUserAction.toggleAdmin, Icons.admin_panel_settings,
            user.isAdmin ? 'Hạ xuống người học' : 'Nâng lên quản trị viên'),
        item(AdminUserAction.toggleBan, Icons.block, user.isBanned ? 'Mở khoá' : 'Khoá tài khoản', danger: true),
        item(AdminUserAction.delete, Icons.delete, 'Xoá tài khoản', danger: true),
      ],
      onSelected: (action) => runAdminUserAction(context, action, user),
    );
  }
}
