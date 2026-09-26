import 'package:flutter/foundation.dart';

import '../models/transcript_timing.dart';

/// Một lượt canh mốc lời thoại cho một video.
///
/// Hai giai đoạn: dán câu thoại ([load]), rồi vừa xem video vừa bấm [mark]
/// đúng lúc từng câu bắt đầu. Không giữ trình phát — màn hình đưa vị trí phát
/// hiện tại vào [mark], nên logic này test được mà không cần video thật.
class TranscriptTimingSession extends ChangeNotifier {
  List<TimingLine> _lines = const [];
  List<String> _errors = const [];
  final List<Duration> _starts = [];
  String? _message;

  List<TimingLine> get lines => _lines;
  List<String> get errors => _errors;
  List<Duration> get starts => List.unmodifiable(_starts);

  /// Có câu hợp lệ và không dòng nào lỗi thì mới bắt đầu canh được.
  bool get canStart => _lines.isNotEmpty && _errors.isEmpty;

  /// Câu đang chờ bấm mốc; bằng `lines.length` khi đã canh xong.
  int get nextIndex => _starts.length;
  bool get isComplete => _lines.isNotEmpty && _starts.length == _lines.length;

  /// Đọc phần câu thoại dán vào. Mốc đã canh bị bỏ vì danh sách câu đã đổi.
  void load(String text) {
    final parsed = parseTimingLines(text);
    _lines = parsed.lines;
    _errors = parsed.errors;
    _starts.clear();
    notifyListeners();
  }

  /// Ghi [position] làm mốc bắt đầu của câu kế tiếp.
  ///
  /// Mốc phải tăng dần: tua ngược rồi bấm thì câu sau sáng trước câu trước,
  /// bảng lời thoại tô sai dòng — báo ra để hoàn tác thay vì ghi.
  void mark(Duration position) {
    if (isComplete) return;
    if (_starts.isNotEmpty && position < _starts.last) {
      _message = 'Vị trí này trước câu vừa đánh dấu (${formatTimecode(_starts.last)}). '
          'Tua tới đúng chỗ hoặc bấm Hoàn tác.';
    } else {
      _starts.add(position);
    }
    notifyListeners();
  }

  void undo() {
    if (_starts.isEmpty) return;
    _starts.removeLast();
    notifyListeners();
  }

  /// Bắt đầu canh lại từ câu đầu, giữ nguyên các câu đã dán.
  void restart() {
    _starts.clear();
    notifyListeners();
  }

  /// Thông báo một lần cho màn hình hiện rồi xoá.
  String? consumeMessage() {
    final message = _message;
    _message = null;
    return message;
  }

  /// Phần lời thoại hoàn chỉnh của video, dán vào file `.txt` của bài.
  String output({required String fileName, required String title}) {
    assert(isComplete, 'chưa canh xong mọi câu');
    return buildTranscriptSection(fileName: fileName, title: title, lines: _lines, starts: _starts);
  }
}
