import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_tokens.dart';
import '../models/admin_user.dart';
import '../providers/admin_users_provider.dart';
import 'admin_user_style.dart';
import 'send_notification_dialog.dart';

/// Thao tác trên một tài khoản, chọn từ menu của dòng đó.
enum AdminUserAction { view, notify, toggleAdmin, toggleBan, delete }

/// Hộp thoại xem chi tiết một người dùng.
void showAdminUserDetails(BuildContext context, AdminUser user) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(user.displayName.isEmpty ? 'Chi tiết người dùng' : user.displayName),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (icon, label, value) in [
            (Icons.email_outlined, 'Email', user.email.isEmpty ? 'Chưa cập nhật' : user.email),
            (Icons.badge_outlined, 'Vai trò', user.isAdmin ? 'Quản trị viên' : 'Người học'),
            (Icons.school_outlined, 'Trình độ', user.level),
            (Icons.star_outline, 'Tổng XP', '${user.totalXp}'),
            (Icons.event_outlined, 'Tham gia', adminDate(user.joinedAt)),
            (Icons.schedule, 'Đăng nhập gần nhất', adminDate(user.lastActiveAt)),
          ])
            ListTile(leading: Icon(icon), title: Text(label), subtitle: Text(value)),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng')),
      ],
    ),
  );
}

/// Thực hiện [action] trên [user]; thao tác ghi báo kết quả bằng snackbar.
/// [context] phải nằm dưới [AdminUsersProvider] của màn quản lý người dùng.
Future<void> runAdminUserAction(BuildContext context, AdminUserAction action, AdminUser user) async {
  final name = user.displayName;
  switch (action) {
    case AdminUserAction.view:
      showAdminUserDetails(context, user);
    case AdminUserAction.notify:
      await openSendNotificationForm(context, user: user);
    case AdminUserAction.toggleAdmin:
      await _write(
        context,
        (users) => users.setAdmin(user, !user.isAdmin),
        done: user.isAdmin ? 'Đã hạ quyền $name xuống người học.' : 'Đã nâng quyền $name lên quản trị viên.',
      );
    case AdminUserAction.toggleBan:
      await _write(
        context,
        (users) => users.setBanned(user, !user.isBanned),
        done: user.isBanned ? 'Đã mở khoá $name.' : 'Đã khoá $name.',
      );
    case AdminUserAction.delete:
      if (await _confirmDelete(context, user) && context.mounted) {
        await _write(context, (users) => users.delete(user), done: 'Đã xoá $name.');
      }
  }
}

Future<void> _write(
  BuildContext context,
  Future<String?> Function(AdminUsersProvider users) action, {
  required String done,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final error = await action(context.read<AdminUsersProvider>());
  messenger.showSnackBar(SnackBar(
    content: Text(error ?? done),
    backgroundColor: error == null ? AppColors.successStrong : AppColors.errorStrong,
  ));
}

/// Xoá tài khoản không hoàn tác được: hỏi lại, nói rõ tên người bị xoá.
Future<bool> _confirmDelete(BuildContext context, AdminUser user) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Xoá tài khoản?'),
      content: Text(
        'Tài khoản "${user.displayName}" bị xoá vĩnh viễn và không đăng nhập lại được. '
        'Muốn tạm chặn thì dùng "Khoá tài khoản" — mở khoá được.',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Huỷ')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.errorStrong, foregroundColor: Colors.white),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Xoá'),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
