import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/files/file_saver.dart';
import '../../../core/state/view_state.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/content_pane.dart';
import '../models/export_document.dart';
import '../providers/export_provider.dart';
import '../widgets/export_options.dart';

/// Xuất dữ liệu học tập ra tệp JSON/CSV. Việc gom dữ liệu — kể cả đọc hết mọi
/// trang lịch sử XP và lịch học — nằm ở `ExportService`; màn này chỉ chọn loại,
/// định dạng và lưu tệp.
class ExportScreen extends StatelessWidget {
  const ExportScreen({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (_) => ExportProvider(),
        child: const _ExportView(),
      );
}

class _ExportView extends StatefulWidget {
  const _ExportView();

  @override
  State<_ExportView> createState() => _ExportViewState();
}

class _ExportViewState extends State<_ExportView> {
  String _selectedType = ExportType.allData;
  String _selectedFormat = ExportFormat.json;

  @override
  Widget build(BuildContext context) {
    final isExporting = context.watch<ExportProvider>().isExporting;
    const sectionTitle = TextStyle(fontSize: AppTypography.subtitle, fontWeight: FontWeight.bold);
    return AppScaffold(
      title: 'Xuất dữ liệu',
      body: ContentPaneList(
        maxWidth: AppContentWidth.dashboard,
        padding: AppSpacing.page,
        builder: (context, padding) => ListView(
          padding: padding,
          children: [
            const ExportHeader(),
            const SizedBox(height: AppSpacing.xl),
            const Text('Chọn loại dữ liệu', style: sectionTitle),
            const SizedBox(height: AppSpacing.sm),
            ExportTypePicker(
              selected: _selectedType,
              onChanged: isExporting ? null : (type) => setState(() => _selectedType = type),
            ),
            const SizedBox(height: 20),
            const Text('Định dạng tệp', style: sectionTitle),
            const SizedBox(height: AppSpacing.sm),
            ExportFormatPicker(
              selected: _selectedFormat,
              onChanged: isExporting ? null : (format) => setState(() => _selectedFormat = format),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: isExporting ? null : _exportToFile,
              icon: isExporting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.download),
              label: Text(isExporting ? 'Đang xuất...' : 'Xuất tệp'),
            ),
            if (isExporting) ...[
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: context.read<ExportProvider>().cancel,
                icon: const Icon(Icons.close),
                label: const Text('Huỷ xuất'),
              ),
            ],
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: isExporting ? null : _copyJson,
              icon: const Icon(Icons.content_copy),
              label: const Text('Sao chép JSON'),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'CSV dùng hai cột “section” và “data”; dữ liệu lồng nhau được giữ dưới dạng JSON để không bị mất trường.',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.colors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  /// Chạy một lần xuất; huỷ giữa chừng hay lỗi ở bất kỳ trang nào đều không
  /// tạo tệp và không báo thành công một phần.
  Future<void> _guarded(Future<void> Function(Map<String, dynamic> data) use, String failure) async {
    try {
      final data = await context.read<ExportProvider>().load(_selectedType);
      if (data == null) {
        if (mounted) _message('Đã huỷ xuất dữ liệu.', false);
        return;
      }
      await use(data);
    } catch (error) {
      if (mounted) _message('$failure: ${userMessageOf(error)}', false);
    }
  }

  Future<void> _exportToFile() => _guarded((data) async {
        final document = ExportDocument.build(
          type: _selectedType,
          format: _selectedFormat,
          data: data,
          now: DateTime.now(),
        );
        final saved = await saveBytes(
          fileName: document.fileName,
          bytes: document.bytes,
          mimeType: document.mimeType,
        );
        if (mounted) _message(saved ? 'Đã xuất tệp ${document.fileName}.' : 'Đã hủy xuất tệp.', saved);
      }, 'Không thể xuất dữ liệu');

  Future<void> _copyJson() => _guarded((data) async {
        final content = ExportDocument.jsonOf(_selectedType, data, DateTime.now());
        await Clipboard.setData(ClipboardData(text: content));
        if (mounted) _message('Đã sao chép dữ liệu JSON.', true);
      }, 'Không thể sao chép dữ liệu');

  void _message(String message, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? AppColors.successStrong : AppColors.errorStrong,
      ),
    );
  }
}
