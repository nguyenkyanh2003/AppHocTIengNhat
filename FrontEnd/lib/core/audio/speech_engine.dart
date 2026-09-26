/// Đọc tiếng Nhật bằng giọng tổng hợp của nền tảng: Web Speech API trên web,
/// flutter_tts trên Android / iOS. Không có giọng tiếng Nhật thì ném
/// `SpeechUnavailableException` để màn hình báo cho người học.
export 'speech_engine_stub.dart'
    if (dart.library.io) 'speech_engine_io.dart'
    if (dart.library.js_interop) 'speech_engine_web.dart';
