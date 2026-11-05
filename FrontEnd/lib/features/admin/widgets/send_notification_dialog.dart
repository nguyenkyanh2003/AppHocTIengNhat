import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../shared/widgets/app_dialog.dart';
import '../../notifications/models/notification.dart';
import '../providers/admin_provider.dart';

/// Gửi một thông báo; trả thông báo lỗi để form hiện, `null` khi đã gửi.
typedef SendNotification = Future<String?> Function(
    String title, String message, NotificationType type);

/// Giới hạn khớp với schema backend (`notification.schema.js`).
const _titleMax = 120;
const _messageMax = 2000;

/// Mở form gửi thông báo từ màn Quản lý người dùng rồi báo kết quả bằng
/// snackbar. [user] là một dòng của danh sách quản trị; `null` là gửi cho mọi
/// người học.
Future<void> openSendNotificationForm(BuildContext context, {Map<String, dynamic>? user}) async {
  final admin = context.read<AdminProvider>();
  final messenger = ScaffoldMessenger.of(context);
  final userId = user == null ? null : (user['_id'] ?? user['id'])?.toString();
  final name = user == null
      ? null
      : [user['name'], user['email']]
          .map((value) => value?.toString().trim() ?? '')
          .firstWhere((value) => value.isNotEmpty, orElse: () => 'người dùng này');

  var sent = 0;
  final done = await showAppDialog<bool>(
    context: context,
    builder: (_) => SendNotificationDialog(
      recipientName: name,
      onSend: (title, message, type) async {
        final result = await admin.sendNotification(userId: userId, title: title, message: message, type: type);
        sent = result.sent;
        return result.error;
      },
    ),
  );
  if (done != true) return;
  messenger.showSnackBar(SnackBar(
    content: Text(userId == null ? 'Đã gửi thông báo cho $sent người học.' : 'Đã gửi thông báo cho $name.'),
  ));
}

/// Form gửi thông báo: tiêu đề, nội dung, loại. Đóng với kết quả `true` khi
/// gửi xong; lỗi thì hiện ngay trong form và giữ nguyên nội dung đã nhập.
class SendNotificationDialog extends StatefulWidget {
  const SendNotificationDialog({super.key, required this.onSend, this.recipientName});

  final SendNotification onSend;

  /// `null` nghĩa là gửi cho mọi người học.
  final String? recipientName;

  @override
  State<SendNotificationDialog> createState() => _SendNotificationDialogState();
}

class _SendNotificationDialogState extends State<SendNotificationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _message = TextEditingController();
  NotificationType _type = NotificationType.system;
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _message.dispose();
    super.dispose();
  }

  static String? _required(String? value, String message) =>
      value == null || value.trim().isEmpty ? message : null;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    final error = await widget.onSend(_title.text.trim(), _message.text.trim(), _type);
    if (!mounted) return;
    if (error == null) return Navigator.pop(context, true);
    setState(() {
      _sending = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final recipient = widget.recipientName;

    return AlertDialog(
      title: const Text('Gửi thông báo'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  recipient == null ? 'Gửi tới: tất cả người học' : 'Gửi tới: $recipient',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                AppGap.md,
                TextFormField(
                  controller: _title,
                  maxLength: _titleMax,
                  decoration: const InputDecoration(labelText: 'Tiêu đề'),
                  validator: (value) => _required(value, 'Vui lòng nhập tiêu đề.'),
                ),
                TextFormField(
                  controller: _message,
                  minLines: 3,
                  maxLines: 6,
                  maxLength: _messageMax,
                  decoration: const InputDecoration(labelText: 'Nội dung', alignLabelWithHint: true),
                  validator: (value) => _required(value, 'Vui lòng nhập nội dung.'),
                ),
                DropdownButtonFormField<NotificationType>(
                  value: _type,
                  decoration: const InputDecoration(labelText: 'Loại'),
                  items: [
                    for (final type in NotificationType.values)
                      DropdownMenuItem(value: type, child: Text(type.label)),
                  ],
                  onChanged: _sending ? null : (type) => setState(() => _type = type ?? _type),
                ),
                if (_error != null) ...[
                  AppGap.md,
                  Text(_error!, style: TextStyle(color: context.colors.error)),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _sending ? null : () => Navigator.pop(context, false),
          child: const Text('Huỷ'),
        ),
        FilledButton(
          onPressed: _sending ? null : _submit,
          child: _sending
              ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Gửi'),
        ),
      ],
    );
  }
}
