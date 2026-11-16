import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../models/admin_report.dart';
import 'admin_report_dialogs.dart';
import 'admin_report_style.dart';
import 'admin_user_style.dart';

/// Một báo cáo ở khổ hẹp.
class AdminReportCard extends StatelessWidget {
  const AdminReportCard({super.key, required this.item});

  final AdminReport item;

  @override
  Widget build(BuildContext context) {
    final report = item.report;
    final (typeColor, typeIcon) = adminReportTypeStyle(report.type);
    final (priorityColor, priorityLabel) = adminReportPriorityStyle(context, report.priority);
    final response = report.adminResponse?.trim() ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: typeColor,
          child: Icon(typeIcon, color: AppColors.onFill(typeColor), size: 20),
        ),
        title: Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(report.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            AdminBadge(label: priorityLabel, color: priorityColor),
          ],
        ),
        subtitle: Wrap(
          spacing: AppSpacing.md,
          children: [
            Text('👤 ${item.reporter}'),
            Text('🕐 ${adminDate(report.createdAt)}'),
          ],
        ),
        trailing: AdminBadge(
          label: AdminReportStatus.labels[report.status] ?? report.status,
          color: AdminReportStatus.colorOf(report.status),
          filled: true,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Mô tả:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: AppTypography.bodySmall)),
                const SizedBox(height: AppSpacing.sm),
                Text(report.description, style: const TextStyle(fontSize: AppTypography.bodySmall)),
                const SizedBox(height: AppSpacing.lg),
                if (response.isNotEmpty) ...[
                  _Response(response),
                  const SizedBox(height: AppSpacing.lg),
                ],
                _Actions(item: item),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Response extends StatelessWidget {
  const _Response(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.success),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Phản hồi từ quản trị:',
            style: TextStyle(fontWeight: FontWeight.bold, color: context.colors.readable(AppColors.success)),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(text),
        ],
      ),
    );
  }
}

/// Phản hồi, chuyển bước xử lý tiếp theo, xoá.
class _Actions extends StatelessWidget {
  const _Actions({required this.item});

  final AdminReport item;

  @override
  Widget build(BuildContext context) {
    final status = item.report.status;
    final next = switch (status) {
      'pending' => ('in_progress', 'Bắt đầu xử lý', Icons.play_arrow),
      'in_progress' => ('resolved', 'Đánh dấu xong', Icons.check),
      _ => null,
    };

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (status != 'resolved')
          ElevatedButton.icon(
            onPressed: () => showAdminReportResponseDialog(context, item),
            icon: const Icon(Icons.reply, size: 18),
            label: const Text('Phản hồi'),
          ),
        if (next case (final nextStatus, final label, final icon))
          OutlinedButton.icon(
            onPressed: () => runAdminReportAction(
              context,
              (reports) => reports.setStatus(item, nextStatus),
              done: 'Đã cập nhật trạng thái.',
            ),
            icon: Icon(icon, size: 18),
            label: Text(label),
          ),
        IconButton(
          tooltip: 'Xoá báo cáo',
          onPressed: () => confirmDeleteAdminReport(context, item),
          icon: Icon(Icons.delete, color: context.colors.error),
        ),
      ],
    );
  }
}
