import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/content_pane.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../shared/widgets/adaptive_table.dart';

class AdminReportManagementScreen extends StatefulWidget {
  const AdminReportManagementScreen({Key? key}) : super(key: key);

  @override
  State<AdminReportManagementScreen> createState() =>
      _AdminReportManagementScreenState();
}

class _AdminReportManagementScreenState
    extends State<AdminReportManagementScreen> {
  String _selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadReports();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Quản Lý Reports',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => context.read<AdminProvider>().loadReports(),
        ),
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: _showFilterDialog,
        ),
      ],
      body: ContentWidthLimit(
        child: Consumer<AdminProvider>(
          builder: (context, adminProvider, child) {
            final allReports = adminProvider.reports;

            final filteredReports = _selectedStatus == 'all'
                ? allReports
                : allReports
                    .where((r) => r['status'] == _selectedStatus)
                    .toList();

            return Column(
              children: [
                // Stats Bar
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey[100],
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatCard(
                          '${allReports.length}', 'Tổng', Colors.blue),
                      _buildStatCard(
                          '${allReports.where((r) => r['status'] == 'pending').length}',
                          'Chờ xử lý',
                          Colors.orange),
                      _buildStatCard(
                          '${allReports.where((r) => r['status'] == 'in_progress').length}',
                          'Đang xử lý',
                          Colors.purple),
                      _buildStatCard(
                          '${allReports.where((r) => r['status'] == 'resolved').length}',
                          'Đã xong',
                          Colors.green),
                    ],
                  ),
                ),

                // Status Filter
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildStatusChip('Tất cả', 'all', Colors.grey),
                        _buildStatusChip('Chờ xử lý', 'pending', Colors.orange),
                        _buildStatusChip(
                            'Đang xử lý', 'in_progress', Colors.purple),
                        _buildStatusChip('Đã xong', 'resolved', Colors.green),
                      ],
                    ),
                  ),
                ),

                // Reports List
                Expanded(
                  child: adminProvider.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : filteredReports.isEmpty
                          ? const Center(child: Text('Không có reports nào'))
                          : AdaptiveTable<Map<String, dynamic>>(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              items: filteredReports,
                              rowKey: (report) =>
                                  ValueKey(report['_id'] ?? report['id']),
                              columns: _reportColumns(),
                              cardBuilder: (context, report) =>
                                  _buildReportCard(report),
                            ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String label, String value, Color color) {
    final isSelected = _selectedStatus == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _selectedStatus = value);
        },
        selectedColor: color.withValues(alpha: 0.3),
        backgroundColor: Colors.grey[200],
        labelStyle: TextStyle(
          color: isSelected ? color : Colors.black,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report) {
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
            _buildPriorityBadge(report['priority']),
          ],
        ),
        subtitle: Row(
          children: [
            Text('👤 ${report['user']}'),
            const SizedBox(width: 12),
            Text('🕐 ${report['createdAt']}'),
          ],
        ),
        trailing: _buildStatusBadge(report['status']),
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
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  report['description'],
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),

                // Admin Response
                if (report['status'] == 'resolved') ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '✅ Phản hồi từ Admin:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text('Đã kiểm tra và sửa lỗi. Cảm ơn bạn đã báo cáo!'),
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
                          onPressed: () => _showResponseDialog(report),
                          icon: const Icon(Icons.reply, size: 18),
                          label: const Text('Phản hồi'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    if (report['status'] != 'resolved')
                      const SizedBox(width: 8),
                    if (report['status'] == 'pending')
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _updateStatus(report, 'in_progress'),
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
                          onPressed: () => _updateStatus(report, 'resolved'),
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('Đánh dấu xong'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _deleteReport(report),
                      icon: const Icon(Icons.delete, color: Colors.red),
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

  Widget _buildPriorityBadge(String priority) {
    Color color;
    String text;
    switch (priority) {
      case 'high':
        color = Colors.red;
        text = 'Cao';
        break;
      case 'medium':
        color = Colors.orange;
        text = 'Trung bình';
        break;
      default:
        color = Colors.grey;
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
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;
    switch (status) {
      case 'pending':
        color = Colors.orange;
        text = 'Chờ';
        break;
      case 'in_progress':
        color = Colors.purple;
        text = 'Xử lý';
        break;
      case 'resolved':
        color = Colors.green;
        text = 'Xong';
        break;
      default:
        color = Colors.grey;
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
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'bug':
        return Colors.red;
      case 'suggestion':
        return Colors.blue;
      case 'content':
        return Colors.orange;
      default:
        return Colors.grey;
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

  /// Cot bang bao cao tren vung rong; cung du lieu voi the o man hep.
  List<AdaptiveColumn<Map<String, dynamic>>> _reportColumns() {
    return [
      AdaptiveColumn(
        label: 'Tiêu đề',
        minWidth: 240,
        cell: (context, report) => Text(
          (report['title'] ?? '').toString(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
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
          onPressed: () => _showResponseDialog(report),
        ),
      ),
    ];
  }

  void _showResponseDialog(Map<String, dynamic> report) {
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
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã gửi phản hồi!')),
              );
            },
            child: const Text('Gửi'),
          ),
        ],
      ),
    );
  }

  void _updateStatus(Map<String, dynamic> report, String newStatus) {
    setState(() {
      report['status'] = newStatus;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã cập nhật trạng thái!')),
    );
  }

  void _deleteReport(Map<String, dynamic> report) {
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

              if (mounted && context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Đã xóa report!' : 'Lỗi khi xóa!'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lọc Reports'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Theo loại'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {},
            ),
            ListTile(
              title: const Text('Theo độ ưu tiên'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {},
            ),
            ListTile(
              title: const Text('Theo ngày'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}
