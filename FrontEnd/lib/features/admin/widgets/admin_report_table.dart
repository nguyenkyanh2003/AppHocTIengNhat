import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/widgets/adaptive_table.dart';
import 'admin_report_dialogs.dart';

/// Màu của từng trạng thái báo cáo, dùng chung cho số đếm và bộ lọc.
abstract final class AdminReportStatusColors {
  static const pending = AppColors.warning;
  static const inProgress = Colors.purple;
  static const resolved = AppColors.success;
}

/// Cột bảng báo cáo trên vùng rộng; cùng dữ liệu với thẻ ở màn hẹp.
List<AdaptiveColumn<Map<String, dynamic>>> adminReportColumns() => [
      AdaptiveColumn(
        label: 'Tiêu đề',
        minWidth: 240,
        cell: (context, report) =>
            Text((report['title'] ?? '').toString(), maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      AdaptiveColumn(
        label: 'Loại',
        width: 130,
        cell: (context, report) => Text((report['type'] ?? '').toString()),
      ),
      AdaptiveColumn(
        label: 'Trạng thái',
        width: 130,
        cell: (context, report) => Text((report['status'] ?? '').toString()),
      ),
      AdaptiveColumn(
        label: 'Thao tác',
        width: 72,
        alignEnd: true,
        cell: (context, report) => IconButton(
          tooltip: 'Phản hồi',
          icon: const Icon(Icons.reply),
          onPressed: () => showAdminReportResponseDialog(context, report),
        ),
      ),
    ];

/// Đếm báo cáo theo trạng thái, trên toàn bộ danh sách (không theo bộ lọc).
class AdminReportStatsBar extends StatelessWidget {
  const AdminReportStatsBar({super.key, required this.reports});

  final List<Map<String, dynamic>> reports;

  @override
  Widget build(BuildContext context) {
    int count(String status) => reports.where((report) => report['status'] == status).length;
    return Container(
      padding: AppSpacing.page,
      color: context.colors.surfaceVariant,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Stat(value: reports.length, label: 'Tổng', color: AppColors.primary),
          _Stat(value: count('pending'), label: 'Chờ xử lý', color: AdminReportStatusColors.pending),
          _Stat(value: count('in_progress'), label: 'Đang xử lý', color: AdminReportStatusColors.inProgress),
          _Stat(value: count('resolved'), label: 'Đã xong', color: AdminReportStatusColors.resolved),
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
          Text(label, style: TextStyle(fontSize: AppTypography.caption, color: context.colors.textSecondary)),
        ],
      ),
    );
  }
}
