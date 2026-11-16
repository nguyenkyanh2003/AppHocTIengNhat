import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_tokens.dart';
import '../models/admin_report.dart';
import '../providers/admin_reports_provider.dart';

/// Thao tác ghi trên báo cáo, báo kết quả bằng snackbar. [context] phải nằm
/// dưới [AdminReportsProvider] của màn quản lý báo cáo.
Future<void> runAdminReportAction(
  BuildContext context,
  Future<String?> Function(AdminReportsProvider reports) action, {
  required String done,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final error = await action(context.read<AdminReportsProvider>());
  messenger.showSnackBar(SnackBar(
    content: Text(error ?? done),
    backgroundColor: error == null ? AppColors.successStrong : AppColors.errorStrong,
  ));
}

/// Hộp thoại phản hồi một báo cáo. Lỗi gửi hiện ngay trong hộp thoại, giữ
/// nguyên nội dung đã nhập.
Future<void> showAdminReportResponseDialog(BuildContext context, AdminReport item) async {
  final reports = context.read<AdminReportsProvider>();
  final messenger = ScaffoldMessenger.of(context);
  final sent = await showDialog<bool>(
    context: context,
    builder: (_) => _ResponseDialog(onSend: (text) => reports.respond(item, text)),
  );
  if (sent == true) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Đã gửi phản hồi.'), backgroundColor: AppColors.successStrong),
    );
  }
}

class _ResponseDialog extends StatefulWidget {
  const _ResponseDialog({required this.onSend});

  final Future<String?> Function(String response) onSend;

  @override
  State<_ResponseDialog> createState() => _ResponseDialogState();
}

class _ResponseDialogState extends State<_ResponseDialog> {
  final _controller = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _error = 'Vui lòng nhập phản hồi.');
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    final error = await widget.onSend(text);
    if (!mounted) return;
    if (error == null) return Navigator.pop(context, true);
    setState(() {
      _sending = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Phản hồi báo cáo'),
      content: TextField(
        autofocus: true,
        controller: _controller,
        maxLines: 5,
        decoration: InputDecoration(
          hintText: 'Nhập phản hồi của bạn...',
          border: const OutlineInputBorder(),
          errorText: _error,
        ),
      ),
      actions: [
        TextButton(onPressed: _sending ? null : () => Navigator.pop(context, false), child: const Text('Hủy')),
        ElevatedButton(onPressed: _sending ? null : _send, child: const Text('Gửi')),
      ],
    );
  }
}

/// Xác nhận rồi xoá một báo cáo.
Future<void> confirmDeleteAdminReport(BuildContext context, AdminReport item) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Xác nhận xóa'),
      content: Text('Xoá báo cáo "${item.report.title}"?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Hủy')),
        ElevatedButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.errorStrong, foregroundColor: Colors.white),
          child: const Text('Xóa'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  await runAdminReportAction(context, (reports) => reports.delete(item), done: 'Đã xoá báo cáo.');
}
