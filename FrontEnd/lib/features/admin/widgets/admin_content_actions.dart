import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/files/file_saver.dart';
import '../providers/admin_provider.dart';
import '../utils/admin_content_csv.dart';
import '../widgets/excel_import_options_dialog.dart';
import '../../../app/theme/app_tokens.dart';
import 'admin_content_format.dart';
import '../../../core/state/view_state.dart';

/// Xác nhận rồi xoá một mục nội dung.
Future<void> confirmDeleteAdminContent(
    BuildContext context, Map<String, dynamic> item,
    {required String selectedContentType,
    required String Function(Map<String, dynamic> item) contentTitle}) async {
  final hostContext = context;
  final id = adminContentItemId(item);
  if (id == null) {
    showAdminContentMessage(context, 'Nội dung không có ID hợp lệ.',
        success: false);
    return;
  }
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Xác nhận xóa'),
      content: Text('Xóa “${contentTitle(item)}”?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Hủy'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
              backgroundColor: AppColors.errorStrong,
              foregroundColor: Colors.white),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Xóa'),
        ),
      ],
    ),
  );
  if (confirmed != true || !hostContext.mounted) return;

  final provider = context.read<AdminProvider>();
  final success = switch (selectedContentType) {
    'vocabulary' => await provider.deleteVocabulary(id),
    'kanji' => await provider.deleteKanji(id),
    'grammar' => await provider.deleteGrammar(id),
    'lessons' => await provider.deleteLesson(id),
    _ => false,
  };
  if (!hostContext.mounted) return;
  showAdminContentMessage(context,
      success ? 'Đã xóa nội dung.' : provider.error ?? 'Không thể xóa.',
      success: success);
}

/// Nhập nội dung từ file CSV.
Future<void> importAdminContentCsv(BuildContext context,
    {required String selectedContentType}) async {
  final hostContext = context;
  final picked = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: const ['csv'],
    withData: true,
  );
  final bytes = picked?.files.single.bytes;
  if (bytes == null || !hostContext.mounted) return;

  try {
    final rows = AdminContentCsv.decode(selectedContentType, bytes);

    final provider = context.read<AdminProvider>();
    final imported = await provider.importContent(selectedContentType, rows);
    if (!hostContext.mounted) return;
    final complete = imported == rows.length;
    showAdminContentMessage(
        context,
        complete
            ? 'Đã import $imported dòng dữ liệu.'
            : 'Đã import $imported/${rows.length} dòng. ${provider.error ?? ''}',
        success: complete);
  } catch (error) {
    if (hostContext.mounted) {
      showAdminContentMessage(
          context, 'Không thể đọc CSV: ${userMessageOf(error)}',
          success: false);
    }
  }
}

/// Nhập nội dung từ file Excel qua bước xem trước.
Future<void> importAdminContentExcel(BuildContext context,
    {required String selectedContentType}) async {
  final hostContext = context;
  ExcelImportOptions? options;

  if (selectedContentType == 'vocabulary') {
    final provider = context.read<AdminProvider>();
    if (provider.lessons.isEmpty) {
      await provider.loadLessons();
    }
    if (!hostContext.mounted) return;

    options = await showDialog<ExcelImportOptions>(
      context: context,
      builder: (_) => ExcelImportOptionsDialog(
        lessons: context.read<AdminProvider>().lessons,
      ),
    );
    if (options == null || !hostContext.mounted) return;
  }

  final picked = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: const ['xls', 'xlsx'],
    withData: true,
  );
  final file = picked?.files.single;
  if (file?.bytes == null || !hostContext.mounted) return;
  final provider = context.read<AdminProvider>();
  final success = await provider.importExcel(
    selectedContentType,
    file!.bytes!,
    file.name,
    lesson: options?.lessonId,
    level: options?.level,
  );
  if (!hostContext.mounted) return;
  showAdminContentMessage(
      context,
      success
          ? 'Đã import dữ liệu Excel.'
          : provider.error ?? 'Import thất bại.',
      success: success);
}

/// Hộp thoại chọn cách nhập dữ liệu.
void showAdminContentImportDialog(BuildContext context,
    {required String selectedContentType}) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('Import ${adminContentTypeLabel(selectedContentType)}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.table_view),
            title: const Text('Import từ CSV'),
            subtitle: const Text('Dòng đầu tiên phải chứa tên các trường.'),
            onTap: () {
              Navigator.pop(dialogContext);
              importAdminContentCsv(context,
                  selectedContentType: selectedContentType);
            },
          ),
          if (selectedContentType == 'vocabulary' ||
              selectedContentType == 'kanji')
            ListTile(
              leading: const Icon(Icons.grid_on),
              title: const Text('Import từ Excel'),
              subtitle: const Text('Hỗ trợ định dạng .xls và .xlsx.'),
              onTap: () {
                Navigator.pop(dialogContext);
                importAdminContentExcel(context,
                    selectedContentType: selectedContentType);
              },
            ),
          const Divider(),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Cột CSV: ${AdminContentCsv.columns(selectedContentType).where((column) => column != '_id').join(', ')}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Đóng'),
        ),
      ],
    ),
  );
}

/// Xuất danh sách đang xem ra file CSV.
Future<void> exportAdminContent(BuildContext context,
    {required String selectedContentType,
    required List<Map<String, dynamic>> Function(AdminProvider provider)
        contentOf}) async {
  final hostContext = context;
  final rows = contentOf(context.read<AdminProvider>());
  if (rows.isEmpty) {
    showAdminContentMessage(context, 'Không có dữ liệu để xuất.',
        success: false);
    return;
  }
  try {
    final now = DateTime.now();
    final stamp =
        '${now.year}${_two(now.month)}${_two(now.day)}_${_two(now.hour)}${_two(now.minute)}';
    final bytes = AdminContentCsv.encode(selectedContentType, rows);
    final saved = await saveBytes(
      fileName: '${selectedContentType}_$stamp.csv',
      bytes: bytes,
      mimeType: 'text/csv;charset=utf-8',
    );
    if (hostContext.mounted) {
      showAdminContentMessage(context,
          saved ? 'Đã xuất ${rows.length} dòng dữ liệu.' : 'Đã hủy xuất tệp.',
          success: saved);
    }
  } catch (error) {
    if (hostContext.mounted) {
      showAdminContentMessage(
          context, 'Không thể xuất dữ liệu: ${userMessageOf(error)}',
          success: false);
    }
  }
}

String _two(int value) => value.toString().padLeft(2, '0');
