import 'package:audioplayers/audioplayers.dart';

/// Trình duyệt phát trực tiếp từ URL.
///
/// Không đụng tới `dart:io`, `File`, thư mục tạm hay `DeviceFileSource`: trên
/// web không có hệ thống tệp để ghi bộ nhớ đệm, và trình duyệt vốn đã tự cache
/// theo header của response.
Future<Source> resolveAudioSource({
  required String url,
  required String fileName,
}) async {
  return UrlSource(url);
}
