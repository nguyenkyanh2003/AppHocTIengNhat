import 'package:flutter_tts/flutter_tts.dart';

import 'speech_voice.dart';

/// Đọc bằng giọng tổng hợp của Android / iOS qua flutter_tts.
///
/// Hỏi lại "có giọng tiếng Nhật không" mỗi lần đọc: người dùng có thể vừa cài
/// thêm gói giọng trong lúc app đang mở.
FlutterTts? _tts;

Future<void> speakJapanese(String text, {required double rate}) async {
  final tts = _tts ??= FlutterTts();
  final available = await tts.isLanguageAvailable('ja-JP');
  if (available != true) throw const SpeechUnavailableException();

  await tts.setLanguage('ja-JP');
  await tts.setSpeechRate(rate);
  await tts.stop();
  await tts.speak(text);
}

Future<void> stopSpeaking() async => _tts?.stop();
