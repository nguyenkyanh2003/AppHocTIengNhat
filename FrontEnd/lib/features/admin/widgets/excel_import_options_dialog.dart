import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';

/// Bài học và cấp độ áp cho toàn bộ tệp Excel khi import từ vựng.
class ExcelImportOptions {
  const ExcelImportOptions({required this.lessonId, required this.level});

  final String lessonId;
  final String level;
}

/// Hỏi bài học và cấp độ trước khi import từ vựng bằng Excel.
///
/// Backend bắt buộc hai trường này trong multipart và áp cho mọi dòng của tệp,
/// nên chúng phải được chọn trước khi gửi thay vì đoán từ nội dung tệp.
///
/// Trả về `null` khi người dùng huỷ; nơi gọi phải dừng luôn, không mở file
/// picker và không gửi request nào.
class ExcelImportOptionsDialog extends StatefulWidget {
  const ExcelImportOptionsDialog({super.key, required this.lessons});

  static const List<String> levels = ['N5', 'N4', 'N3', 'N2', 'N1'];

  /// Danh sách bài học dạng `{ _id, title, level }`.
  final List<Map<String, dynamic>> lessons;

  @override
  State<ExcelImportOptionsDialog> createState() =>
      _ExcelImportOptionsDialogState();
}

class _ExcelImportOptionsDialogState extends State<ExcelImportOptionsDialog> {
  String? _lessonId;
  String? _level;

  List<Map<String, dynamic>> get _lessons => widget.lessons
      .where((lesson) => (lesson['_id'] ?? '').toString().isNotEmpty)
      .toList();

  void _selectLesson(String? lessonId) {
    setState(() {
      _lessonId = lessonId;

      // Cấp độ mặc định lấy theo bài học đã chọn để tránh gán nhầm từ N5 vào
      // một bài N4; admin vẫn đổi lại được.
      final lesson = _lessons.firstWhere(
        (item) => item['_id'].toString() == lessonId,
        orElse: () => const <String, dynamic>{},
      );
      final lessonLevel = lesson['level']?.toString();
      if (lessonLevel != null &&
          ExcelImportOptionsDialog.levels.contains(lessonLevel)) {
        _level = lessonLevel;
      }
    });
  }

  bool get _canSubmit => _lessonId != null && _level != null;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Import từ vựng từ Excel'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Bài học và cấp độ dưới đây sẽ được gán cho toàn bộ dòng trong tệp.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_lessons.isEmpty)
              const Text('Chưa có bài học nào để gán. Hãy tạo bài học trước.')
            else
              DropdownButtonFormField<String>(
                value: _lessonId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Bài học',
                  border: OutlineInputBorder(borderRadius: AppRadius.mdAll),
                ),
                items: [
                  for (final lesson in _lessons)
                    DropdownMenuItem(
                      value: lesson['_id'].toString(),
                      child: Text(
                        lesson['title']?.toString() ?? lesson['_id'].toString(),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: _selectLesson,
              ),
            const SizedBox(height: AppSpacing.lg),
            DropdownButtonFormField<String>(
              value: _level,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Cấp độ',
                border: OutlineInputBorder(borderRadius: AppRadius.mdAll),
              ),
              items: [
                for (final level in ExcelImportOptionsDialog.levels)
                  DropdownMenuItem(value: level, child: Text(level)),
              ],
              onChanged: (value) => setState(() => _level = value),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Huỷ'),
        ),
        FilledButton(
          onPressed: _canSubmit
              ? () => Navigator.of(context).pop(
                    ExcelImportOptions(lessonId: _lessonId!, level: _level!),
                  )
              : null,
          child: const Text('Chọn tệp'),
        ),
      ],
    );
  }
}
