import 'package:audioplayers/audioplayers.dart';

/// Nguồn phát cho một URL audio.
///
/// Nền tảng không xác định thì phát thẳng từ URL: đây là cách chạy được ở mọi
/// nơi, chỉ mất phần bộ nhớ đệm tệp.
Future<Source> resolveAudioSource({
  required String url,
  required String fileName,
}) async {
  return UrlSource(url);
}
