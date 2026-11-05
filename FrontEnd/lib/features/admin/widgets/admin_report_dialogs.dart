import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../../../app/theme/app_tokens.dart';

/// Hộp thoại phản hồi một báo cáo.
void showAdminReportResponseDialog(
    BuildContext context, Map<String, dynamic> report) {
  final controller = TextEditingController();
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Phản hồi Report'),
      content: TextField(
        autofocus: true,
        controller: controller,
        maxLines: 5,
        decoration: const InputDecoration(
          hintText: 'Nhập phản hồi của bạn...',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () async {
            final text = controller.text.trim();
            if (text.isEmpty) return;
            final provider = context.read<AdminProvider>();
            final messenger = ScaffoldMessenger.of(context);
            final navigator = Navigator.of(context);
            final id = (report['id'] ?? report['_id']).toString();
            // Đã phản hồi thì báo cáo chuyển sang "đang xử lý", trừ khi đã đóng.
            final status =
                report['status'] == 'resolved' ? 'resolved' : 'in_progress';
            final success = await provider.respondToReport(id, text, status);
            navigator.pop();
            messenger.showSnackBar(
              SnackBar(
                content: Text(success
                    ? 'Đã gửi phản hồi.'
                    : provider.error ?? 'Không gửi được phản hồi.'),
                backgroundColor:
                    success ? AppColors.successStrong : AppColors.errorStrong,
              ),
            );
          },
          child: const Text('Gửi'),
        ),
      ],
    ),
  );
}

/// Xác nhận rồi xoá một báo cáo.
void confirmDeleteAdminReport(
    BuildContext context, Map<String, dynamic> report) {
  final hostContext = context;
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Xác nhận xóa'),
      content: const Text('Bạn có chắc muốn xóa report này?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () async {
            final adminProvider = context.read<AdminProvider>();
            final id = report['id'] ?? report['_id'];
            final success = await adminProvider.deleteReport(id);

            if (hostContext.mounted && context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(hostContext).showSnackBar(
                SnackBar(
                  content: Text(success ? 'Đã xóa report!' : 'Lỗi khi xóa!'),
                  backgroundColor:
                      success ? AppColors.successStrong : AppColors.errorStrong,
                ),
              );
            }
          },
          style:
              ElevatedButton.styleFrom(backgroundColor: AppColors.errorStrong),
          child: const Text('Xóa'),
        ),
      ],
    ),
  );
}
