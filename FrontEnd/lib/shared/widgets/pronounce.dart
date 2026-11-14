import 'package:flutter/material.dart';

import '../../core/audio/audio_service.dart';
import '../../core/audio/speech_service.dart';

/// Đọc to một từ hay câu tiếng Nhật: file âm thanh thật nếu có [audioUrl],
/// không thì giọng đọc của thiết bị đọc [text].
///
/// Không đọc được thì báo bằng SnackBar; [hint] nối sau câu báo khi thiết bị
/// không có giọng tiếng Nhật (vd "Thẻ vẫn học được bằng mắt."). [quiet] bỏ qua
/// lỗi — dùng cho câu ví dụ, nơi chữ vẫn đọc được và một SnackBar là thừa.
///
/// Mọi nút phát âm trong app đi qua đây, để màn hình và widget không phải tự
/// gọi `AudioService` hay `SpeechService`.
Future<void> pronounce(
  BuildContext context, {
  String? audioUrl,
  required String text,
  String? hint,
  bool quiet = false,
}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  String? problem;
  try {
    if (audioUrl != null && audioUrl.isNotEmpty) {
      await AudioService().playAudio(audioUrl);
    } else {
      await SpeechService.instance.speak(text);
    }
  } on SpeechUnavailableException catch (error) {
    problem = hint == null ? '$error' : '$error $hint';
  } catch (_) {
    problem = 'Không phát được âm thanh.';
  }
  if (problem != null && !quiet) {
    messenger?.showSnackBar(SnackBar(content: Text(problem)));
  }
}
