import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/files/file_saver.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/content_pane.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../providers/export_provider.dart';
import '../services/export_service.dart';

/// Xuất dữ liệu học tập ra tệp JSON/CSV. Việc gom dữ liệu — kể cả đọc hết mọi
/// trang lịch sử XP và lịch học — nằm ở [ExportService]; màn này chỉ chọn loại,
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
  static const _types = <String, (String, String, IconData)>{
    ExportType.fullStats: (
      'Thống kê tổng quan',
      'Tiến độ, phân tích bài học và streak',
      Icons.analytics_outlined,
    ),
    ExportType.lessonProgress: (
      'Tiến độ bài học',
      'Toàn bộ tiến độ học tập hiện có',
      Icons.trending_up,
    ),
    ExportType.notebook: (
      'Ghi chép',
      'Danh sách ghi chú cá nhân',
      Icons.note_alt_outlined,
    ),
    ExportType.achievements: (
      'Thành tích',
      'Thành tích đã mở khóa và đang thực hiện',
      Icons.emoji_events_outlined,
    ),
    ExportType.streaks: (
      'Streak và XP',
      'Chuỗi học tập, toàn bộ lịch sử điểm và lịch ngày học',
      Icons.local_fire_department_outlined,
    ),
    ExportType.allData: (
      'Toàn bộ dữ liệu',
      'Gộp tất cả nhóm dữ liệu phía trên',
      Icons.archive_outlined,
    ),
  };

  String _selectedType = ExportType.allData;
  String _selectedFormat = 'json';

  @override
  Widget build(BuildContext context) {
    final isExporting = context.watch<ExportProvider>().isExporting;
    return AppScaffold(
      title: 'Xuất dữ liệu',
      body: ContentPaneList(
        maxWidth: AppContentWidth.dashboard,
        padding: const EdgeInsets.all(16),
        builder: (context, padding) => ListView(
          padding: padding,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: [
                  Icon(Icons.download, size: 52, color: AppColors.primary),
                  SizedBox(height: 12),
                  Text(
                    'Sao lưu dữ liệu học tập',
                    style: TextStyle(
                        fontSize: AppTypography.title,
                        fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Dữ liệu được lấy trực tiếp từ tài khoản tại thời điểm xuất.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Chọn loại dữ liệu',
              style: TextStyle(
                  fontSize: AppTypography.subtitle,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ..._types.entries.map((entry) {
              final info = entry.value;
              return Card(
                child: RadioListTile<String>(
                  value: entry.key,
                  groupValue: _selectedType,
                  onChanged: isExporting
                      ? null
                      : (value) => setState(() => _selectedType = value!),
                  secondary: Icon(info.$3),
                  title: Text(info.$1),
                  subtitle: Text(info.$2),
                ),
              );
            }),
            const SizedBox(height: 20),
            const Text(
              'Định dạng tệp',
              style: TextStyle(
                  fontSize: AppTypography.subtitle,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'json',
                  icon: Icon(Icons.data_object),
                  label: Text('JSON'),
                ),
                ButtonSegment(
                  value: 'csv',
                  icon: Icon(Icons.table_view),
                  label: Text('CSV'),
                ),
              ],
              selected: {_selectedFormat},
              onSelectionChanged: isExporting
                  ? null
                  : (values) => setState(() => _selectedFormat = values.single),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: isExporting ? null : _exportToFile,
              icon: isExporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
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
            const SizedBox(height: 16),
            const Text(
              'CSV dùng hai cột “section” và “data”; dữ liệu lồng nhau được giữ dưới dạng JSON để không bị mất trường.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  /// Chạy một lần xuất; huỷ giữa chừng hay lỗi ở bất kỳ trang nào đều không
  /// tạo tệp và không báo thành công một phần.
  Future<void> _guarded(Future<void> Function(Map<String, dynamic> data) use,
      String failure) async {
    final provider = context.read<ExportProvider>();
    try {
      await use(await provider.load(_selectedType));
    } on ExportCancelled {
      if (mounted) _message('Đã huỷ xuất dữ liệu.', false);
    } catch (error) {
      if (mounted) _message('$failure: $error', false);
    }
  }

  Future<void> _exportToFile() => _guarded((data) async {
        final content = _selectedFormat == 'json'
            ? const JsonEncoder.withIndent('  ').convert({
                'exported_at': DateTime.now().toIso8601String(),
                'type': _selectedType,
                'data': data,
              })
            : _toCsv(data);
        final encoded = utf8.encode(content);
        final bytes = Uint8List.fromList(
          _selectedFormat == 'csv' ? [0xEF, 0xBB, 0xBF, ...encoded] : encoded,
        );
        final now = DateTime.now();
        final fileName =
            '${_selectedType}_${now.year}${_two(now.month)}${_two(now.day)}.$_selectedFormat';
        final saved = await saveBytes(
          fileName: fileName,
          bytes: bytes,
          mimeType: _selectedFormat == 'json'
              ? 'application/json;charset=utf-8'
              : 'text/csv;charset=utf-8',
        );
        if (mounted) {
          _message(
              saved ? 'Đã xuất tệp $fileName.' : 'Đã hủy xuất tệp.', saved);
        }
      }, 'Không thể xuất dữ liệu');

  Future<void> _copyJson() => _guarded((data) async {
        final content = const JsonEncoder.withIndent('  ').convert({
          'exported_at': DateTime.now().toIso8601String(),
          'type': _selectedType,
          'data': data,
        });
        await Clipboard.setData(ClipboardData(text: content));
        if (mounted) _message('Đã sao chép dữ liệu JSON.', true);
      }, 'Không thể sao chép dữ liệu');

  String _toCsv(Map<String, dynamic> data) {
    final buffer = StringBuffer()..writeln('"section","data"');
    for (final entry in data.entries) {
      buffer.writeln(
        '${_csvCell(entry.key)},${_csvCell(jsonEncode(entry.value))}',
      );
    }
    return buffer.toString();
  }

  String _csvCell(String value) => '"${value.replaceAll('"', '""')}"';

  String _two(int value) => value.toString().padLeft(2, '0');

  void _message(String message, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? AppColors.success : AppColors.error,
      ),
    );
  }
}
