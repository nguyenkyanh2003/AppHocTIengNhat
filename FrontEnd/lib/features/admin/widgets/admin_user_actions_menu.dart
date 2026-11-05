import 'package:flutter/material.dart';
import '../../../app/theme/app_tokens.dart';
import 'admin_user_actions.dart';

/// Menu thao tác của một người dùng.
class AdminUserActionsMenu extends StatelessWidget {
  const AdminUserActionsMenu({
    super.key,
    required this.user,
  });

  final Map<String, dynamic> user;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'view',
          child: Row(
            children: [
              Icon(Icons.visibility, size: 20),
              SizedBox(width: 8),
              Text('Xem chi tiết'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'notify',
          child: Row(
            children: [
              Icon(Icons.notifications_outlined, size: 20),
              SizedBox(width: 8),
              Text('Gửi thông báo'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'promote',
          child: Row(
            children: [
              const Icon(Icons.admin_panel_settings, size: 20),
              const SizedBox(width: 8),
              Text(
                user['role'] == 'admin' ? 'Hạ quyền User' : 'Nâng quyền Admin',
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'ban',
          child: Row(
            children: [
              Icon(Icons.block, size: 20, color: context.colors.error),
              const SizedBox(width: 8),
              Text('Khóa/Mở khóa',
                  style: TextStyle(color: context.colors.error)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 20, color: context.colors.error),
              const SizedBox(width: 8),
              Text('Xóa User', style: TextStyle(color: context.colors.error)),
            ],
          ),
        ),
      ],
      onSelected: (value) =>
          handleAdminUserAction(context, value.toString(), user),
    );
  }
}
