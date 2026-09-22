import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Đọc tiếng Nhật bằng giọng tổng hợp của trình duyệt / hệ điều hành.
///
/// Dữ liệu từ vựng chưa có file âm thanh nào (`audio_url` trống ở mọi từ), nên
/// đây là đường phát âm chính. Khi một từ có `audio_url` thật thì màn hình vẫn
/// ưu tiên file đó qua [AudioService].
class SpeechService {
  SpeechService._();
  static final SpeechService instance = SpeechService._();

  FlutterTts? _tts;

  Future<FlutterTts> _engine() async {
    final existing = _tts;
    if (existing != null) return existing;

    final tts = FlutterTts();
    await tts.setLanguage('ja-JP');
    // Chậm hơn tốc độ nói thường một chút cho người mới học.
    await tts.setSpeechRate(kIsWeb ? 0.8 : 0.45);
    return _tts = tts;
  }

  /// Bỏ phần chú thích trong cách đọc trước khi đọc:
  /// `すいます(たばこを~)` → `すいます`, `じょうず[な]` → `じょうず`.
  static String cleanForSpeech(String text) => text
      .replaceAll(RegExp(r'[\(（\[「].*?[\)）\]」]'), '')
      .replaceAll(RegExp('[~〜]'), '')
      .trim();

  Future<void> speak(String text) async {
    final cleaned = cleanForSpeech(text);
    if (cleaned.isEmpty) return;

    final tts = await _engine();
    await tts.stop();
    await tts.speak(cleaned);
  }
}
