import 'package:flutter/foundation.dart';

import 'speech_engine.dart' as engine;

export 'speech_voice.dart' show SpeechUnavailableException;

/// Đọc tiếng Nhật bằng giọng tổng hợp của trình duyệt / hệ điều hành.
///
/// Dữ liệu từ vựng chưa có file âm thanh nào (`audio_url` trống ở mọi từ), nên
/// đây là đường phát âm chính. Khi một từ có `audio_url` thật thì màn hình vẫn
/// ưu tiên file đó qua `AudioService`.
///
/// Thiết bị không có giọng tiếng Nhật thì [speak] ném
/// [SpeechUnavailableException] — màn hình nên báo cho người học thay vì im
/// lặng, để họ biết cần cài giọng đọc chứ không phải nút hỏng.
class SpeechService {
  SpeechService._();
  static final SpeechService instance = SpeechService._();

  /// Chậm hơn tốc độ nói thường một chút cho người mới học. Thang tốc độ của
  /// trình duyệt và của flutter_tts trên điện thoại khác nhau.
  static const double _rate = kIsWeb ? 0.8 : 0.45;

  /// Bỏ phần chú thích trong cách đọc trước khi đọc:
  /// `すいます(たばこを~)` → `すいます`, `じょうず[な]` → `じょうず`.
  static String cleanForSpeech(String text) => text
      .replaceAll(RegExp(r'[\(（\[「].*?[\)）\]」]'), '')
      .replaceAll(RegExp('[~〜]'), '')
      .trim();

  Future<void> speak(String text) async {
    final cleaned = cleanForSpeech(text);
    if (cleaned.isEmpty) return;
    await engine.speakJapanese(cleaned, rate: _rate);
  }

  Future<void> stop() => engine.stopSpeaking();
}
