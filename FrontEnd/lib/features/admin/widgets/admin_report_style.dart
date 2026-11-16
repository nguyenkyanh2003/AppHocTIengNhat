import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';

/// Màu và nhãn của từng trạng thái báo cáo, dùng chung cho số đếm, bộ lọc,
/// thẻ và bảng.
abstract final class AdminReportStatus {
  static const labels = {
    'pending': 'Chờ xử lý',
    'in_progress': 'Đang xử lý',
    'resolved': 'Đã xong',
    'rejected': 'Từ chối',
  };

  static Color colorOf(String status) => switch (status) {
        'pending' => AppColors.warning,
        'in_progress' => Colors.purple,
        'resolved' => AppColors.success,
        _ => AppColors.neutral,
      };
}

/// Màu và biểu tượng của loại báo cáo.
(Color, IconData) adminReportTypeStyle(String type) => switch (type) {
      'bug' => (AppColors.error, Icons.bug_report),
      'suggestion' => (AppColors.primary, Icons.lightbulb),
      'content' => (AppColors.warning, Icons.content_copy),
      _ => (AppColors.neutral, Icons.help),
    };

/// Nhãn mức ưu tiên của báo cáo.
(Color, String) adminReportPriorityStyle(BuildContext context, String priority) => switch (priority) {
      'urgent' => (AppColors.error, 'Khẩn cấp'),
      'high' => (AppColors.error, 'Cao'),
      'medium' => (AppColors.warning, 'Trung bình'),
      _ => (context.colors.textSecondary, 'Thấp'),
    };

/// Nhãn bo tròn, nền nhạt theo [color].
class AdminBadge extends StatelessWidget {
  const AdminBadge({super.key, required this.label, required this.color, this.filled = false});

  final String label;
  final Color color;

  /// Nền đặc màu thay vì nền nhạt.
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: filled ? color : color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: filled ? AppColors.onFill(color) : context.colors.readable(color),
            ),
      ),
    );
  }
}
