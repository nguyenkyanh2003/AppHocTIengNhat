import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/report_provider.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/app_tokens.dart';

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
              backgroundColor: AppColors.successStrong,
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
              backgroundColor: AppColors.errorStrong,
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
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: AppTypography.body),
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
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: AppTypography.body),
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
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: AppTypography.body),
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
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: AppTypography.body),
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
                      style: const TextStyle(fontSize: AppTypography.body),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (provider.error != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      border: Border.all(color: context.colors.error),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      provider.error ?? '',
                      style: TextStyle(color: context.colors.error),
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
        backgroundColor: isSelected ? AppColors.primary : context.colors.border,
        foregroundColor: isSelected ? Colors.white : context.colors.textPrimary,
      ),
      child: Text(label),
    );
  }
}
