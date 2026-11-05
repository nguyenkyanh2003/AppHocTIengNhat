import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/report_provider.dart';
import '../services/report_service.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../core/state/view_state.dart';

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({Key? key}) : super(key: key);

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ReportProvider>(context, listen: false).loadMyReports();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReportProvider>(
      builder: (context, provider, _) {
        return AsyncView<List<Report>>(
          state: ViewState.fromLegacy(
            isLoading: provider.isLoading,
            error: provider.error,
            value: provider.reports,
            isEmpty: provider.reports.isEmpty,
          ),
          onRetry: () => provider.loadMyReports(),
          isEmpty: (reports) => reports.isEmpty,
          emptyTitle: 'Bạn chưa gửi báo cáo nào',
          builder: (context, reports) => ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,
            itemBuilder: (context, index) =>
                _buildReportCard(context, reports[index], provider),
          ),
        );
      },
    );
  }

  Widget _buildReportCard(
    BuildContext context,
    Report report,
    ReportProvider provider,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(
          report.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          _getTypeLabel(report.type),
          style: TextStyle(
            fontSize: AppTypography.caption,
            color: context.colors.readable(_getTypeColor(report.type)),
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getStatusColor(report.status).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            _getStatusLabel(report.status),
            style: TextStyle(
              fontSize: AppTypography.caption,
              fontWeight: FontWeight.bold,
              color: context.colors.readable(_getStatusColor(report.status)),
            ),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Mô tả:', report.description),
                const SizedBox(height: 12),
                _buildDetailRow('Mức độ:', _getPriorityLabel(report.priority)),
                const SizedBox(height: 12),
                _buildDetailRow(
                  'Ngày gửi:',
                  '${report.createdAt.day}/${report.createdAt.month}/${report.createdAt.year}',
                ),
                if (report.adminResponse != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Phản hồi từ Admin:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: context.colors.readable(AppColors.success),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(report.adminResponse ?? ''),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(value),
        ),
      ],
    );
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'bug':
        return '🐛 Lỗi ứng dụng';
      case 'suggestion':
        return '💡 Gợi ý cải thiện';
      case 'content':
        return '📚 Vấn đề nội dung';
      default:
        return '❓ Khác';
    }
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

  String _getPriorityLabel(String priority) {
    switch (priority) {
      case 'low':
        return '🟢 Thấp';
      case 'medium':
        return '🟡 Trung bình';
      case 'high':
        return '🔴 Cao';
      default:
        return priority;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Chờ xử lý';
      case 'approved':
        return 'Đã giải quyết';
      case 'rejected':
        return 'Bị từ chối';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.warning;
      case 'approved':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.neutral;
    }
  }
}
