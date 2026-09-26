/// Một giọng đọc của thiết bị, rút gọn về đúng những gì cần để chọn giọng.
typedef SpeechVoiceInfo = ({String lang, bool isLocal});

/// Vị trí giọng tiếng Nhật nên dùng trong [voices], hoặc `null` nếu không có.
///
/// Ưu tiên giọng cài trên máy (đọc ngay, không cần mạng) hơn giọng trực tuyến
/// của trình duyệt. Mã ngôn ngữ nhận cả `ja-JP`, `ja_JP` lẫn `ja`.
int? pickJapaneseVoice(List<SpeechVoiceInfo> voices) {
  bool isJapanese(SpeechVoiceInfo voice) => voice.lang.toLowerCase().replaceAll('_', '-').split('-').first == 'ja';

  int? fallback;
  for (var index = 0; index < voices.length; index++) {
    if (!isJapanese(voices[index])) continue;
    if (voices[index].isLocal) return index;
    fallback ??= index;
  }
  return fallback;
}

/// Thiết bị không có giọng đọc tiếng Nhật nào.
class SpeechUnavailableException implements Exception {
  const SpeechUnavailableException();

  @override
  String toString() => 'Thiết bị chưa có giọng đọc tiếng Nhật.';
}
