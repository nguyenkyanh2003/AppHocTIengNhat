@TestOn('browser')
library;

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:web/web.dart' as web;

import 'package:apphoctiengnnhat/core/audio/audio_source_resolver.dart';
import 'package:apphoctiengnnhat/core/files/file_saver.dart';

/// Kiểm chứng các nhánh code **chỉ tồn tại trên web**.
///
/// `flutter build web` chỉ chứng minh chúng biên dịch được. Những hàm này gọi
/// thẳng API trình duyệt (`Blob`, `URL.createObjectURL`, thẻ `<a download>`),
/// nên chỉ chạy thật trong Chrome mới biết chúng có ném lỗi hay không.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('tải file xuống trên web', () {
    testWidgets('lưu bytes bằng Blob và thẻ tải xuống, không ném lỗi', (
      tester,
    ) async {
      final bytes = Uint8List.fromList('tu,nghia\n犬,con chó\n'.codeUnits);

      final ok = await saveBytes(
        fileName: 'e2e-kiem-thu.csv',
        bytes: bytes,
        mimeType: 'text/csv',
      );

      expect(ok, isTrue);
      // Thẻ `<a>` tạm phải được gỡ khỏi DOM sau khi bấm, không để rác lại.
      expect(web.document.querySelectorAll('a[download]').length, 0);
    });
  });

  group('phát âm trên web', () {
    testWidgets('nguồn âm thanh là URL trực tiếp, không đụng hệ thống tệp', (
      tester,
    ) async {
      // Trên web không có thư mục tạm để ghi bộ nhớ đệm; nhánh io sẽ ném lỗi
      // ngay tại đây nếu conditional import bị nối nhầm.
      final source = await resolveAudioSource(
        url: 'https://example.test/inu.mp3',
        fileName: 'inu.mp3',
      );

      expect(source, isNotNull);
      expect(source.runtimeType.toString(), contains('UrlSource'));
    });
  });
}
