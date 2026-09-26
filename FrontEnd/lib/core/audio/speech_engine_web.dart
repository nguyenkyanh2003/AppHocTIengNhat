import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'speech_voice.dart';

/// Đọc bằng Web Speech API của trình duyệt.
///
/// Không đi qua flutter_tts: bản web của thư viện đó chọn giọng một lần lúc
/// khởi tạo, mà trình duyệt nạp danh sách giọng **bất đồng bộ** — lần đầu
/// `getVoices()` trả về rỗng, câu đọc giữ ngôn ngữ của trang (`vi`) và giọng
/// Việt đọc chữ kana thì im lặng. Ở đây mỗi lần đọc tạo câu đọc mới, luôn gắn
/// `ja-JP` và chỉ chọn giọng sau khi danh sách giọng đã có.

/// Giữ tham chiếu câu đang đọc: Chrome có thể thu gom một câu đọc chưa đọc
/// xong nếu không còn ai giữ nó, làm tiếng tắt giữa chừng.
web.SpeechSynthesisUtterance? _current;

Future<List<web.SpeechSynthesisVoice>> _voices(web.SpeechSynthesis synth) async {
  final voices = synth.getVoices().toDart;
  if (voices.isNotEmpty) return voices;

  final loaded = Completer<void>();
  final listener = ((web.Event _) {
    if (!loaded.isCompleted) loaded.complete();
  }).toJS;
  synth.addEventListener('voiceschanged', listener);
  await loaded.future.timeout(const Duration(seconds: 2), onTimeout: () {});
  synth.removeEventListener('voiceschanged', listener);
  return synth.getVoices().toDart;
}

Future<void> speakJapanese(String text, {required double rate}) async {
  final synth = web.window.speechSynthesis;
  final voices = await _voices(synth);
  final index = pickJapaneseVoice([
    for (final voice in voices) (lang: voice.lang, isLocal: voice.localService),
  ]);
  if (index == null) throw const SpeechUnavailableException();

  if (synth.speaking || synth.pending) {
    synth.cancel();
    // Chrome bỏ qua câu đọc gọi ngay sau `cancel()` trong cùng nhịp.
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }

  final utterance = web.SpeechSynthesisUtterance(text)
    ..lang = 'ja-JP'
    ..voice = voices[index]
    ..rate = rate;
  utterance.onend = ((web.Event _) {
    if (identical(_current, utterance)) _current = null;
  }).toJS;
  _current = utterance;
  synth.speak(utterance);
}

Future<void> stopSpeaking() async {
  web.window.speechSynthesis.cancel();
  _current = null;
}
