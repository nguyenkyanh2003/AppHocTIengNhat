import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

const Duration _downloadTimeout = Duration(seconds: 60);

/// Tên tệp an toàn cho hệ thống tệp, tránh ký tự lạ trong tên câu hỏi.
String _safeFileName(String fileName) {
  final normalized = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  return normalized.isEmpty ? 'audio' : normalized;
}

/// Nền tảng có hệ thống tệp: tải về thư mục tạm rồi phát từ tệp.
///
/// Giữ nguyên hành vi cũ của màn thi JLPT (nghe lại nhiều lần không tải lại),
/// nhưng nếu tải hỏng thì lùi về phát thẳng từ URL thay vì báo lỗi.
Future<Source> resolveAudioSource({
  required String url,
  required String fileName,
}) async {
  try {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/${_safeFileName(fileName)}');

    if (await file.exists()) {
      return DeviceFileSource(file.path);
    }

    final response = await http.get(Uri.parse(url)).timeout(_downloadTimeout);
    if (response.statusCode != 200) {
      throw http.ClientException('HTTP ${response.statusCode}', Uri.parse(url));
    }

    await file.writeAsBytes(response.bodyBytes);
    return DeviceFileSource(file.path);
  } catch (error) {
    debugPrint('Không tải được audio về bộ nhớ đệm, phát từ URL: $error');
    return UrlSource(url);
  }
}
