import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Giới hạn trong `docs/architecture/conventions.md`: màn hình dưới 250 dòng. Chạm
/// mốc thì tách phần trình bày sang `widgets/` trước khi thêm tính năng.
const _maxScreenLines = 250;

/// Dấu hiệu của giao diện chưa làm xong: nút không làm gì, thông báo "sắp có", số
/// liệu mẫu nằm lẫn trong màn hình thật.
const _unfinished = <String, String>{
  r'on(Tap|Pressed):\s*\(\)\s*\{\s*\}': 'nút bấm không làm gì',
  r'Tính năng sắp có': 'thông báo tính năng chưa làm',
  r'Placeholder height': 'cột biểu đồ giả',
  r"stats\['\w+'\]\s*\?\?\s*'?[1-9][0-9.,%]*": 'số mẫu thay cho số liệu thật',
  r'nguyenvana@example\.com': 'dữ liệu mẫu',
};

Iterable<File> _dartFiles(String root) => Directory(root)
    .listSync(recursive: true)
    .whereType<File>()
    .where((file) => file.path.endsWith('.dart'));

String _path(File file) => file.path.replaceAll(r'\', '/');

void main() {
  test('mọi màn hình dưới $_maxScreenLines dòng', () {
    final tooLong = <String>[];
    for (final file in _dartFiles('lib/features')) {
      if (!_path(file).contains('/screens/')) continue;
      final lines = file.readAsLinesSync().length;
      if (lines >= _maxScreenLines) tooLong.add('${_path(file)}: $lines dòng');
    }

    expect(tooLong, isEmpty,
        reason: 'Tách phần trình bày sang widgets/:\n${tooLong.join('\n')}');
  });

  test('màn hình không còn nút chết, thông báo "sắp có" hay số liệu mẫu', () {
    final found = <String>[];
    for (final file in _dartFiles('lib/features')) {
      final source = file.readAsStringSync();
      _unfinished.forEach((pattern, reason) {
        if (RegExp(pattern).hasMatch(source)) {
          found.add('${_path(file)}: $reason');
        }
      });
    }

    expect(found, isEmpty, reason: found.join('\n'));
  });

  test('màn hình dùng AsyncView thay vì tự viết nhánh lỗi kèm nút thử lại', () {
    final found = <String>[];
    for (final file in _dartFiles('lib/features')) {
      if (!_path(file).contains('/screens/')) continue;
      final source = file.readAsStringSync();
      if (source.contains("Text('Thử lại')")) {
        found.add(_path(file));
      }
    }

    expect(found, isEmpty, reason: 'Dùng AsyncView:\n${found.join('\n')}');
  });

  test('màn hình và widget không tự gọi service hay ApiClient', () {
    // Gọi dữ liệu đi qua provider; phát âm đi qua `shared/widgets/pronounce.dart`.
    // Màn hình vẫn được nhận một service để truyền vào provider nó tạo (seam cho test).
    final direct = RegExp(r'\b[A-Z]\w*Service\(\)|\b[A-Z]\w*Service\.instance\b|\bApiClient\b');
    final found = <String>[];
    for (final file in _dartFiles('lib/features')) {
      final path = _path(file);
      if (!path.contains('/screens/') && !path.contains('/widgets/')) continue;
      final lines = file.readAsLinesSync();
      for (var index = 0; index < lines.length; index++) {
        if (direct.hasMatch(lines[index])) found.add('$path:${index + 1}: ${lines[index].trim()}');
      }
    }

    expect(found, isEmpty, reason: 'Chuyển lời gọi vào provider:\n${found.join('\n')}');
  });
}
