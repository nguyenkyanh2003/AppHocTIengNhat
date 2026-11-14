import 'dart:convert';
import 'dart:typed_data';

/// Các nhóm dữ liệu xuất được, theo khoá màn xuất dữ liệu dùng.
abstract final class ExportType {
  static const fullStats = 'full_stats';
  static const lessonProgress = 'lesson_progress';
  static const notebook = 'notebook';
  static const achievements = 'achievements';
  static const streaks = 'streaks';
  static const allData = 'all_data';
}

/// Định dạng tệp xuất.
abstract final class ExportFormat {
  static const json = 'json';
  static const csv = 'csv';
}

/// Một tệp xuất dựng từ dữ liệu đã gom: tên tệp, nội dung và kiểu MIME.
class ExportDocument {
  const ExportDocument._({required this.fileName, required this.bytes, required this.mimeType});

  factory ExportDocument.build({
    required String type,
    required String format,
    required Map<String, dynamic> data,
    required DateTime now,
  }) {
    final isCsv = format == ExportFormat.csv;
    final encoded = utf8.encode(isCsv ? csvOf(data) : jsonOf(type, data, now));
    String two(int value) => value.toString().padLeft(2, '0');
    return ExportDocument._(
      fileName: '${type}_${now.year}${two(now.month)}${two(now.day)}.$format',
      // BOM để Excel đọc đúng tiếng Việt trong tệp CSV.
      bytes: Uint8List.fromList(isCsv ? [0xEF, 0xBB, 0xBF, ...encoded] : encoded),
      mimeType: isCsv ? 'text/csv;charset=utf-8' : 'application/json;charset=utf-8',
    );
  }

  final String fileName;
  final Uint8List bytes;
  final String mimeType;

  /// Bản JSON có kèm thời điểm và loại dữ liệu xuất.
  static String jsonOf(String type, Map<String, dynamic> data, DateTime now) =>
      const JsonEncoder.withIndent('  ').convert({
        'exported_at': now.toIso8601String(),
        'type': type,
        'data': data,
      });

  /// Hai cột `section` và `data`; dữ liệu lồng nhau giữ dưới dạng JSON để không mất trường.
  static String csvOf(Map<String, dynamic> data) {
    String cell(String value) => '"${value.replaceAll('"', '""')}"';
    final buffer = StringBuffer()..writeln('"section","data"');
    for (final entry in data.entries) {
      buffer.writeln('${cell(entry.key)},${cell(jsonEncode(entry.value))}');
    }
    return buffer.toString();
  }
}
