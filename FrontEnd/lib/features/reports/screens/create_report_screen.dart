import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../providers/report_provider.dart';
import '../widgets/report_form_parts.dart';

class CreateReportScreen extends StatefulWidget {
  const CreateReportScreen({super.key});

  static const types = {
    'bug': '🐛 Lỗi ứng dụng',
    'suggestion': '💡 Gợi ý cải thiện',
    'content': '📚 Vấn đề nội dung',
    'other': '❓ Khác',
  };

  @override
  State<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends State<CreateReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedType = 'bug';
  String _selectedPriority = 'medium';

  /// Lỗi của lần gửi gần nhất, hiện ngay dưới nút gửi.
  String? _submitError;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    final error = await context.read<ReportProvider>().createReport(
      type: _selectedType,
      title: _titleController.text,
      description: _descriptionController.text,
      priority: _selectedPriority,
    );
    if (!mounted) return;

    setState(() => _submitError = error);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'Gửi báo cáo thành công!'),
        backgroundColor: error == null ? AppColors.successStrong : AppColors.errorStrong,
      ),
    );
    if (error != null) return;

    _formKey.currentState!.reset();
    _titleController.clear();
    _descriptionController.clear();
    setState(() {
      _selectedType = 'bug';
      _selectedPriority = 'medium';
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReportProvider>();
    const section = SizedBox(height: AppSpacing.xl);
    const border = OutlineInputBorder(borderRadius: AppRadius.mdAll);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ReportFieldLabel('Loại báo cáo'),
            DropdownButton<String>(
              value: _selectedType,
              isExpanded: true,
              items: [
                for (final MapEntry(key: value, value: label) in CreateReportScreen.types.entries)
                  DropdownMenuItem(value: value, child: Text(label)),
              ],
              onChanged: (value) => setState(() => _selectedType = value ?? 'bug'),
            ),
            section,
            const ReportFieldLabel('Mức độ ưu tiên'),
            ReportPriorityPicker(
              selected: _selectedPriority,
              onSelected: (priority) => setState(() => _selectedPriority = priority),
            ),
            section,
            const ReportFieldLabel('Tiêu đề'),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(hintText: 'Nhập tiêu đề báo cáo', border: border),
              validator: (value) => value == null || value.isEmpty ? 'Vui lòng nhập tiêu đề' : null,
            ),
            section,
            const ReportFieldLabel('Chi tiết mô tả'),
            TextFormField(
              controller: _descriptionController,
              maxLines: 6,
              decoration: const InputDecoration(hintText: 'Mô tả chi tiết vấn đề...', border: border),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Vui lòng nhập mô tả';
                if (value.length < 10) return 'Mô tả phải có ít nhất 10 ký tự';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.xxl),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: provider.isSubmitting ? null : _submitReport,
                icon: provider.isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.send),
                label: Text(
                  provider.isSubmitting ? 'Đang gửi...' : 'Gửi báo cáo',
                  style: const TextStyle(fontSize: AppTypography.body),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_submitError case final error?) ReportErrorBox(error),
          ],
        ),
      ),
    );
  }
}
