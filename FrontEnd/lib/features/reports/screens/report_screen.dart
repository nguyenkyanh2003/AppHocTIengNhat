import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/report_provider.dart';
import '../services/report_service.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/content_pane.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({Key? key}) : super(key: key);

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController =
      TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Báo Cáo & Góp Ý',
      // Trước đây hai mục này nằm trên `BottomNavigationBar` — nay `AppShell`
      // đã giữ chỗ đó cho điều hướng chính, nên chúng thành tab của trang.
      bottom: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(icon: Icon(Icons.feedback), text: 'Gửi Báo Cáo'),
          Tab(icon: Icon(Icons.history), text: 'Báo Cáo Của Tôi'),
        ],
      ),
      body: ContentWidthLimit(
        child: TabBarView(
          controller: _tabController,
          children: const [
            CreateReportScreen(),
            MyReportsScreen(),
          ],
        ),
      ),
    );
  }
}

class CreateReportScreen extends StatefulWidget {
  const CreateReportScreen({Key? key}) : super(key: key);

  @override
  State<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends State<CreateReportScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedType = 'bug';
  String _selectedPriority = 'medium';
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<ReportProvider>(context, listen: false);

      final success = await provider.createReport(
        type: _selectedType,
        title: _titleController.text,
        description: _descriptionController.text,
        priority: _selectedPriority,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gửi báo cáo thành công!'),
              backgroundColor: Colors.green,
            ),
          );
          _formKey.currentState!.reset();
          _titleController.clear();
          _descriptionController.clear();
          setState(() {
            _selectedType = 'bug';
            _selectedPriority = 'medium';
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(provider.error ?? 'Gửi báo cáo thất bại'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReportProvider>(
      builder: (context, provider, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type selection
                const Text(
                  'Loại báo cáo',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                DropdownButton<String>(
                  value: _selectedType,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(
                      value: 'bug',
                      child: Text('🐛 Lỗi ứng dụng'),
                    ),
                    DropdownMenuItem(
                      value: 'suggestion',
                      child: Text('💡 Gợi ý cải thiện'),
                    ),
                    DropdownMenuItem(
                      value: 'content',
                      child: Text('📚 Vấn đề nội dung'),
                    ),
                    DropdownMenuItem(
                      value: 'other',
                      child: Text('❓ Khác'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedType = value ?? 'bug');
                  },
                ),
                const SizedBox(height: 24),

                // Priority selection
                const Text(
                  'Mức độ ưu tiên',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildPriorityButton('low', '🟢 Thấp'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildPriorityButton('medium', '🟡 Trung bình'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildPriorityButton('high', '🔴 Cao'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Title
                const Text(
                  'Tiêu đề',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: 'Nhập tiêu đề báo cáo',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập tiêu đề';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Description
                const Text(
                  'Chi tiết mô tả',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 6,
                  decoration: InputDecoration(
                    hintText: 'Mô tả chi tiết vấn đề...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập mô tả';
                    }
                    if (value.length < 10) {
                      return 'Mô tả phải có ít nhất 10 ký tự';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: provider.isLoading ? null : _submitReport,
                    icon: provider.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.send),
                    label: Text(
                      provider.isLoading ? 'Đang gửi...' : 'Gửi báo cáo',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (provider.error != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      border: Border.all(color: Colors.red),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      provider.error ?? '',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPriorityButton(String value, String label) {
    final isSelected = _selectedPriority == value;
    return ElevatedButton(
      onPressed: () {
        setState(() => _selectedPriority = value);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue : Colors.grey[300],
        foregroundColor: isSelected ? Colors.white : Colors.black,
      ),
      child: Text(label),
    );
  }
}

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
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(provider.error ?? ''),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    provider.loadMyReports();
                  },
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }

        if (provider.reports.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Bạn chưa gửi báo cáo nào'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: provider.reports.length,
          itemBuilder: (context, index) {
            final report = provider.reports[index];
            return _buildReportCard(context, report, provider);
          },
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
            fontSize: 12,
            color: _getTypeColor(report.type),
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
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: _getStatusColor(report.status),
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
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Phản hồi từ Admin:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
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
        return Colors.red;
      case 'suggestion':
        return Colors.blue;
      case 'content':
        return Colors.orange;
      default:
        return Colors.grey;
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
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
