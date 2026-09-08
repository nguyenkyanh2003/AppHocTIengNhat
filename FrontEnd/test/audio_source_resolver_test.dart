import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:apphoctiengnnhat/core/audio/audio_source_resolver.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('không ghi được bộ nhớ đệm thì vẫn phát được từ URL', () async {
    // Trong môi trường test không có plugin thư mục tạm, đúng như trên web nơi
    // không có hệ thống tệp. Adapter phải lùi về nguồn URL thay vì ném lỗi.
    final source = await resolveAudioSource(
      url: 'http://localhost:3000/uploads/audio/n5-01.mp3',
      fileName: 'n5-01.mp3',
    );

    expect(source, isA<UrlSource>());
    expect(
      (source as UrlSource).url,
      'http://localhost:3000/uploads/audio/n5-01.mp3',
    );
  });
}
