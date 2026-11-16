import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/widgets/adaptive_table.dart';
import '../models/admin_report.dart';
import '../providers/admin_reports_provider.dart';
import 'admin_report_dialogs.dart';
import 'admin_report_style.dart';
import 'admin_user_style.dart';

/// Cột bảng báo cáo trên vùng rộng; cùng dữ liệu với thẻ ở màn hẹp.
List<AdaptiveColumn<AdminReport>> adminReportColumns() => [
      AdaptiveColumn(
        label: 'Tiêu đề',
        minWidth: 240,
        cell: (context, item) => Text(item.report.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      AdaptiveColumn(
        label: 'Người gửi',
        minWidth: 160,
        cell: (context, item) => Text(item.reporter, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      AdaptiveColumn(
        label: 'Loại',
        width: 120,
        cell: (context, item) => Text(AdminReportsProvider.types[item.report.type] ?? item.report.type),
      ),
      AdaptiveColumn(
        label: 'Ngày gửi',
        width: 110,
        cell: (context, item) => Text(adminDate(item.report.createdAt)),
      ),
      AdaptiveColumn(
        label: 'Trạng thái',
        width: 130,
        cell: (context, item) => Align(
          alignment: Alignment.centerLeft,
          child: AdminBadge(
            label: AdminReportStatus.labels[item.report.status] ?? item.report.status,
            color: AdminReportStatus.colorOf(item.report.status),
          ),
        ),
      ),
      AdaptiveColumn(
        label: 'Thao tác',
        width: 72,
        alignEnd: true,
        cell: (context, item) => PopupMenuButton<String>(
          tooltip: 'Thao tác',
          onSelected: (action) => switch (action) {
            'respond' => showAdminReportResponseDialog(context, item),
            'delete' => confirmDeleteAdminReport(context, item),
            final status => runAdminReportAction(
                context,
                (reports) => reports.setStatus(item, status),
                done: 'Đã cập nhật trạng thái.',
              ),
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'respond', child: Text('Phản hồi')),
            for (final MapEntry(:key, :value) in AdminReportStatus.labels.entries)
              if (key != item.report.status) PopupMenuItem(value: key, child: Text('Chuyển sang: $value')),
            const PopupMenuItem(value: 'delete', child: Text('Xoá')),
          ],
        ),
      ),
    ];

/// Số báo cáo theo trạng thái trên toàn hệ thống (không theo bộ lọc).
class AdminReportStatsBar extends StatelessWidget {
  const AdminReportStatsBar({super.key, required this.stats});

  final AdminReportStats stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.page,
      color: context.colors.surfaceVariant,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Stat(value: stats.total, label: 'Tổng', color: AppColors.primary),
          _Stat(value: stats.pending, label: 'Chờ xử lý', color: AdminReportStatus.colorOf('pending')),
          _Stat(value: stats.inProgress, label: 'Đang xử lý', color: AdminReportStatus.colorOf('in_progress')),
          _Stat(value: stats.resolved, label: 'Đã xong', color: AdminReportStatus.colorOf('resolved')),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, required this.color});

  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontSize: AppTypography.headline,
              fontWeight: FontWeight.bold,
              color: context.colors.readable(color),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: AppTypography.caption, color: context.colors.textSecondary),
          ),
        ],
      ),
    );
  }
}
