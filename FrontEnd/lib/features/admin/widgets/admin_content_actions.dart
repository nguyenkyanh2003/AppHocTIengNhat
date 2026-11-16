import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../core/files/file_saver.dart';
import '../../../core/network/api_envelope.dart';
import '../../../core/state/view_state.dart';
import '../models/admin_content_type.dart';
import '../providers/admin_content_provider.dart';
import '../utils/admin_content_csv.dart';
import 'admin_content_format.dart';
import 'excel_import_options_dialog.dart';

// Mọi hàm dưới đây nhận `context` của màn quản lý nội dung, tức nằm dưới
// [AdminContentProvider]; hộp thoại là route riêng nên không tự đọc được nó.

/// Xác nhận rồi xoá một mục nội dung.
Future<void> confirmDeleteAdminContent(BuildContext context, JsonObject item) async {
  final provider = context.read<AdminContentProvider>();
  final id = adminContentItemId(item);
  if (id == null) {
    showAdminContentMessage(context, 'Nội dung không có ID hợp lệ.', success: false);
    return;
  }
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Xác nhận xóa'),
      content: Text('Xóa “${adminContentTitle(provider.type, item)}”?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.errorStrong, foregroundColor: Colors.white),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Xóa'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;

  final error = await provider.delete(id);
  if (!context.mounted) return;
  showAdminContentMessage(context, error ?? 'Đã xóa nội dung.', success: error == null);
}

/// Nhập nội dung từ file CSV.
Future<void> importAdminContentCsv(BuildContext context) async {
  final provider = context.read<AdminContentProvider>();
  final picked = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: const ['csv'],
    withData: true,
  );
  final bytes = picked?.files.single.bytes;
  if (bytes == null || !context.mounted) return;

  final List<JsonObject> rows;
  try {
    rows = AdminContentCsv.decode(provider.type.name, bytes);
  } on FormatException catch (error) {
    showAdminContentMessage(context, 'Không thể đọc CSV: ${error.message}', success: false);
    return;
  }

  final (:imported, :error) = await provider.importRows(rows);
  if (!context.mounted) return;
  showAdminContentMessage(
    context,
    error == null ? 'Đã import $imported dòng dữ liệu.' : 'Đã import $imported/${rows.length} dòng. $error',
    success: error == null,
  );
}

/// Nhập nội dung từ file Excel. Từ vựng hỏi trước bài học và cấp độ áp cho cả tệp.
Future<void> importAdminContentExcel(BuildContext context) async {
  final provider = context.read<AdminContentProvider>();
  ExcelImportOptions? options;

  if (provider.type == AdminContentType.vocabulary) {
    final lessons = await provider.lessonOptions();
    if (!context.mounted) return;
    if (lessons case ViewFailure(:final message)) {
      showAdminContentMessage(context, message, success: false);
      return;
    }
    options = await showDialog<ExcelImportOptions>(
      context: context,
      builder: (_) => ExcelImportOptionsDialog(lessons: lessons.valueOrNull ?? const []),
    );
    if (options == null || !context.mounted) return;
  }

  final picked = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: const ['xls', 'xlsx'],
    withData: true,
  );
  final file = picked?.files.single;
  final bytes = file?.bytes;
  if (file == null || bytes == null || !context.mounted) return;

  final error = await provider.importExcel(bytes, file.name, lesson: options?.lessonId, level: options?.level);
  if (!context.mounted) return;
  showAdminContentMessage(context, error ?? 'Đã import dữ liệu Excel.', success: error == null);
}

/// Hộp thoại chọn cách nhập dữ liệu.
void showAdminContentImportDialog(BuildContext context) {
  final type = context.read<AdminContentProvider>().type;
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('Import ${type.label}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.table_view),
            title: const Text('Import từ CSV'),
            subtitle: const Text('Dòng đầu tiên phải chứa tên các trường.'),
            onTap: () {
              Navigator.pop(dialogContext);
              importAdminContentCsv(context);
            },
          ),
          if (type.supportsExcel)
            ListTile(
              leading: const Icon(Icons.grid_on),
              title: const Text('Import từ Excel'),
              subtitle: const Text('Hỗ trợ định dạng .xls và .xlsx.'),
              onTap: () {
                Navigator.pop(dialogContext);
                importAdminContentExcel(context);
              },
            ),
          const Divider(),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Cột CSV: ${AdminContentCsv.columns(type.name).where((column) => column != '_id').join(', ')}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Đóng')),
      ],
    ),
  );
}

/// Xuất các mục đang hiện ra file CSV.
Future<void> exportAdminContent(BuildContext context) async {
  final provider = context.read<AdminContentProvider>();
  final rows = provider.items.valueOrNull ?? const <JsonObject>[];
  if (rows.isEmpty) {
    showAdminContentMessage(context, 'Không có dữ liệu để xuất.', success: false);
    return;
  }
  final type = provider.type.name;
  final now = DateTime.now();
  String two(int value) => value.toString().padLeft(2, '0');
  final stamp = '${now.year}${two(now.month)}${two(now.day)}_${two(now.hour)}${two(now.minute)}';

  final saved = await ViewState.guard(() => saveBytes(
        fileName: '${type}_$stamp.csv',
        bytes: AdminContentCsv.encode(type, rows),
        mimeType: 'text/csv;charset=utf-8',
      ));
  if (!context.mounted) return;
  switch (saved) {
    case ViewData(value: true):
      showAdminContentMessage(context, 'Đã xuất ${rows.length} dòng dữ liệu.', success: true);
    case ViewData():
      showAdminContentMessage(context, 'Đã hủy xuất tệp.', success: false);
    case ViewFailure(:final message):
      showAdminContentMessage(context, 'Không thể xuất dữ liệu: $message', success: false);
    case ViewIdle() || ViewLoading():
  }
}
