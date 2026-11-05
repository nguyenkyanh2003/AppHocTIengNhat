import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../widgets/send_notification_dialog.dart';

/// Hộp thoại xem chi tiết một người dùng.
void showAdminUserDetails(BuildContext context, Map<String, dynamic> user) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(user['name']?.toString() ?? 'Chi tiết người dùng'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: const Text('Email'),
            subtitle: Text(user['email']?.toString() ?? 'Chưa cập nhật'),
          ),
          ListTile(
            leading: const Icon(Icons.badge_outlined),
            title: const Text('Vai trò'),
            subtitle: Text(user['role']?.toString() ?? 'user'),
          ),
          ListTile(
            leading: const Icon(Icons.verified_user_outlined),
            title: const Text('Trạng thái'),
            subtitle: Text(user['status']?.toString() ?? 'unknown'),
          ),
          ListTile(
            leading: const Icon(Icons.star_outline),
            title: const Text('Tổng XP'),
            subtitle: Text(user['totalXP']?.toString() ?? '0'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Đóng'),
        ),
      ],
    ),
  );
}

/// Thực hiện thao tác chọn từ menu của một người dùng.
void handleAdminUserAction(
    BuildContext context, String action, Map<String, dynamic> user) async {
  final hostContext = context;
  final adminProvider = context.read<AdminProvider>();
  String message = '';

  switch (action) {
    case 'view':
      showAdminUserDetails(context, user);
      return;
    case 'notify':
      await openSendNotificationForm(context, user: user);
      return;
    case 'promote':
      final isAdmin = user['role'] == 'admin';
      final success = isAdmin
          ? await adminProvider.demoteToUser(user['id'] ?? user['_id'])
          : await adminProvider.promoteToAdmin(user['id'] ?? user['_id']);
      message = success
          ? isAdmin
              ? 'Đã hạ quyền ${user['name']} xuống User'
              : 'Đã nâng quyền ${user['name']} lên Admin'
          : 'Không thể cập nhật quyền ${user['name']}';
      break;
    case 'ban':
      final isBanned = user['status'] == 'banned';
      final success = isBanned
          ? await adminProvider.unbanUser(user['id'] ?? user['_id'])
          : await adminProvider.banUser(user['id'] ?? user['_id']);
      message = success
          ? isBanned
              ? 'Đã mở khóa ${user['name']}'
              : 'Đã khóa ${user['name']}'
          : 'Không thể cập nhật ${user['name']}';
      break;
    case 'delete':
      final success = await adminProvider.deleteUser(user['id'] ?? user['_id']);
      message =
          success ? 'Đã xóa ${user['name']}' : 'Lỗi khi xóa ${user['name']}';
      break;
  }

  if (hostContext.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
