import 'package:flutter/material.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import 'admin_report_dialogs.dart';

/// Một báo cáo ở khổ hẹp.
class AdminReportCard extends StatelessWidget {
  const AdminReportCard({
    super.key,
    required this.report,
    required this.updateStatus,
  });

  final Map<String, dynamic> report;
  final void Function(Map<String, dynamic> report, String newStatus)
      updateStatus;

  /// Backend populate người gửi vào `user_id`.
  String _reporterName() {
    final user = report['user_id'];
    if (user is Map) {
      return (user['HoTen'] ?? user['Email'] ?? 'Ẩn danh').toString();
    }
    return 'Ẩn danh';
  }

  String _createdAt() {
    final date = DateTime.tryParse((report['createdAt'] ?? '').toString());
    if (date == null) return '';
    final local = date.toLocal();
    return '${local.day}/${local.month}/${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _getTypeColor(report['type']),
          child: Icon(
            _getTypeIcon(report['type']),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                report['title'],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            _buildPriorityBadge(context, report['priority']),
          ],
        ),
        subtitle: Wrap(
          spacing: 12,
          children: [
            Text('👤 ${_reporterName()}'),
            Text('🕐 ${_createdAt()}'),
          ],
        ),
        trailing: _buildStatusBadge(context, report['status']),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mô tả:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: AppTypography.bodySmall,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  report['description'],
                  style: const TextStyle(fontSize: AppTypography.bodySmall),
                ),
                const SizedBox(height: 16),

                // Admin Response
                if ((report['admin_response'] ?? '').toString().isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
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
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: context.colors.readable(AppColors.success),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(report['admin_response'].toString()),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Action Buttons
                Row(
                  children: [
                    if (report['status'] != 'resolved')
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              showAdminReportResponseDialog(context, report),
                          icon: const Icon(Icons.reply, size: 18),
                          label: const Text('Phản hồi'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    if (report['status'] != 'resolved')
                      const SizedBox(width: 8),
                    if (report['status'] == 'pending')
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => updateStatus(report, 'in_progress'),
                          icon: const Icon(Icons.play_arrow, size: 18),
                          label: const Text('Bắt đầu xử lý'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    if (report['status'] == 'in_progress')
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => updateStatus(report, 'resolved'),
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('Đánh dấu xong'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.successStrong,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () =>
                          confirmDeleteAdminReport(context, report),
                      icon: Icon(Icons.delete, color: context.colors.error),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityBadge(BuildContext context, String priority) {
    Color color;
    String text;
    switch (priority) {
      case 'high':
        color = AppColors.error;
        text = 'Cao';
        break;
      case 'medium':
        color = AppColors.warning;
        text = 'Trung bình';
        break;
      default:
        color = context.colors.textSecondary;
        text = 'Thấp';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: AppTypography.caption,
          fontWeight: FontWeight.bold,
          color: context.colors.readable(color),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, String status) {
    Color color;
    String text;
    switch (status) {
      case 'pending':
        color = AppColors.warning;
        text = 'Chờ';
        break;
      case 'in_progress':
        color = Colors.purple;
        text = 'Xử lý';
        break;
      case 'resolved':
        color = AppColors.success;
        text = 'Xong';
        break;
      default:
        color = context.colors.textSecondary;
        text = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: AppTypography.caption,
          fontWeight: FontWeight.bold,
          color: AppColors.onFill(color),
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'bug':
        return AppColors.error;
      case 'suggestion':
        return AppColors.primary;
      case 'content':
        return AppColors.warning;
      default:
        return AppColors.neutral;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'bug':
        return Icons.bug_report;
      case 'suggestion':
        return Icons.lightbulb;
      case 'content':
        return Icons.content_copy;
      default:
        return Icons.help;
    }
  }
}
