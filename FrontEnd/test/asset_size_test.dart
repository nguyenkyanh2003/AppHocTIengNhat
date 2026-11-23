import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Ảnh trong `assets/` được tải về ngay lần đầu mở bản web và nằm trong mọi
/// bản cài. Logo 5 MB từng làm màn đăng nhập trên web tải thêm 5 MB chỉ để vẽ
/// một hình tròn 160 px.
const _maxImageBytes = 300 * 1024;

void main() {
  test('ảnh trong assets đủ nhẹ cho lần mở đầu tiên', () {
    final heavy = [
      for (final file in Directory('assets').listSync(recursive: true).whereType<File>())
        if (RegExp(r'\.(png|jpe?g|webp|gif)$', caseSensitive: false).hasMatch(file.path) &&
            file.lengthSync() > _maxImageBytes)
          '${file.path}: ${(file.lengthSync() / 1024).round()} KB',
    ];

    expect(heavy, isEmpty, reason: 'Thu nhỏ ảnh về đúng cỡ hiển thị (×3 cho màn mật độ cao):\n${heavy.join('\n')}');
  });
}
