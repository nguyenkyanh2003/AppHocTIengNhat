import 'speech_voice.dart';

/// Nền tảng không có giọng đọc (ví dụ môi trường test không có trình duyệt).
Future<void> speakJapanese(String text, {required double rate}) async =>
    throw const SpeechUnavailableException();

Future<void> stopSpeaking() async {}
