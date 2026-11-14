import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:apphoctiengnnhat/features/settings/models/export_document.dart';

void main() {
  final now = DateTime(2026, 3, 7, 9, 30);
  final data = <String, dynamic>{
    'notebook': [
      {'title': 'Ghi chú "khó"', 'tags': ['N5']},
    ],
  };

  test('tệp JSON mang tên theo loại và ngày, kèm thời điểm và loại dữ liệu', () {
    final document = ExportDocument.build(type: ExportType.notebook, format: ExportFormat.json, data: data, now: now);

    expect(document.fileName, 'notebook_20260307.json');
    expect(document.mimeType, startsWith('application/json'));
    final decoded = jsonDecode(utf8.decode(document.bytes)) as Map<String, dynamic>;
    expect(decoded['type'], ExportType.notebook);
    expect(decoded['exported_at'], now.toIso8601String());
    expect(decoded['data'], data);
  });

  test('tệp CSV có BOM cho Excel, hai cột, dữ liệu lồng nhau giữ nguyên dưới dạng JSON', () {
    final document = ExportDocument.build(type: ExportType.notebook, format: ExportFormat.csv, data: data, now: now);

    expect(document.fileName, 'notebook_20260307.csv');
    expect(document.bytes.take(3), [0xEF, 0xBB, 0xBF]);
    final lines = utf8.decode(document.bytes.sublist(3)).trim().split('\n');
    expect(lines.first, '"section","data"');
    expect(lines[1], startsWith('"notebook",'));

    // Dấu nháy trong ô được nhân đôi; bỏ nháy bao ngoài và gộp lại thì ra đúng JSON ban đầu.
    final cell = lines[1].substring('"notebook",'.length);
    final unquoted = cell.substring(1, cell.length - 1).replaceAll('""', '"');
    expect(jsonDecode(unquoted), data['notebook']);
  });
}
