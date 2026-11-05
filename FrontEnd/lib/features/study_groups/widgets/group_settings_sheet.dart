import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app/theme/app_tokens.dart';
import '../models/study_group.dart';
import 'group_edit_dialog.dart';

/// Hộp thoại chọn loại thông báo của nhóm.
void showGroupNotificationSettings(
    BuildContext context, StudyGroup group) async {
  final hostContext = context;
  // Load settings from SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  final groupId = group.id;

  bool notifyNewMessage = prefs.getBool('notify_message_$groupId') ?? true;
  bool notifyMemberJoin = prefs.getBool('notify_join_$groupId') ?? true;
  bool notifyMemberLeave = prefs.getBool('notify_leave_$groupId') ?? false;

  if (!hostContext.mounted) return;

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.notifications,
                color: context.colors.readable(Colors.orange[700]!)),
            const SizedBox(width: 8),
            const Text('Cài đặt thông báo'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Tin nhắn mới'),
              subtitle: const Text('Nhận thông báo khi có tin nhắn mới'),
              value: notifyNewMessage,
              onChanged: (value) {
                setState(() => notifyNewMessage = value);
              },
              secondary: const Icon(Icons.message),
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Thành viên mới'),
              subtitle: const Text('Nhận thông báo khi có người tham gia'),
              value: notifyMemberJoin,
              onChanged: (value) {
                setState(() => notifyMemberJoin = value);
              },
              secondary: const Icon(Icons.person_add),
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Thành viên rời nhóm'),
              subtitle: const Text('Nhận thông báo khi có người rời đi'),
              value: notifyMemberLeave,
              onChanged: (value) {
                setState(() => notifyMemberLeave = value);
              },
              secondary: const Icon(Icons.person_remove),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Save to SharedPreferences
              final prefs = await SharedPreferences.getInstance();
              final groupId = group.id;

              await prefs.setBool('notify_message_$groupId', notifyNewMessage);
              await prefs.setBool('notify_join_$groupId', notifyMemberJoin);
              await prefs.setBool('notify_leave_$groupId', notifyMemberLeave);

              if (hostContext.mounted && context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(hostContext).showSnackBar(
                  const SnackBar(content: Text('Đã lưu cài đặt thông báo')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[700],
            ),
            child: const Text('Lưu'),
          ),
        ],
      ),
    ),
  );
}

/// Bảng dưới gồm các thao tác quản lý nhóm.
void showGroupSettingsSheet(BuildContext context, StudyGroup group) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: context.colors.surfaceVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            'Cài đặt nhóm',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: context.colors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.edit,
                  color: context.colors.readable(Colors.blue[700]!)),
            ),
            title: const Text(
              'Chỉnh sửa thông tin',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: const Text('Sửa tên, mô tả, cấp độ nhóm'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pop(context);
              showGroupEditDialog(context, group);
            },
          ),
          const Divider(),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.notifications,
                  color: context.colors.readable(Colors.orange[700]!)),
            ),
            title: const Text(
              'Cài đặt thông báo',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: const Text('Quản lý thông báo từ nhóm'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pop(context);
              showGroupNotificationSettings(context, group);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    ),
  );
}
