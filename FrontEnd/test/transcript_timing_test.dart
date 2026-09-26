import 'package:flutter_test/flutter_test.dart';

import 'package:apphoctiengnnhat/features/lessons/models/transcript_timing.dart';
import 'package:apphoctiengnnhat/features/lessons/providers/transcript_timing_session.dart';

const _pasted = '''
# câu mẫu tự soạn để test
Khách / Khách | すみません、駅はどこですか。 | Sumimasen, eki wa doko desu ka. | Xin lỗi, nhà ga ở đâu ạ?
                | まっすぐ行ってください。   |                               | Anh cứ đi thẳng.
00:09:00 | Khách | ありがとうございます。 | Arigatoo gozaimasu. | Cảm ơn anh.
''';

void main() {
  group('đọc câu thoại dán vào', () {
    test('bỏ dòng trống, ghi chú; nhận cả dòng đã có mốc (bỏ mốc để canh lại)', () {
      final (:lines, :errors) = parseTimingLines(_pasted);

      expect(errors, isEmpty);
      expect(lines.map((line) => line.textJa), ['すみません、駅はどこですか。', 'まっすぐ行ってください。', 'ありがとうございます。']);
      expect(lines[1].speaker, isEmpty);
      expect(lines[1].romaji, isEmpty);
      expect(lines[2].speaker, 'Khách');
    });

    test('thiếu ô, thiếu tiếng Nhật hay tiếng Việt đều báo đúng số dòng', () {
      final (:lines, :errors) = parseTimingLines('A | あ。\n | | | Thiếu tiếng Nhật.\nB | い。 | i. | ');

      expect(lines, isEmpty);
      expect(errors, [
        startsWith('Dòng 1: cần 4 ô'),
        'Dòng 2: thiếu câu tiếng Nhật.',
        'Dòng 3: thiếu nghĩa tiếng Việt.',
      ]);
    });
  });

  test('mốc thời gian dạng mm:ss:ff, 30 khung mỗi giây', () {
    expect(formatTimecode(Duration.zero), '00:00:00');
    expect(formatTimecode(const Duration(seconds: 4, milliseconds: 500)), '00:04:15');
    expect(formatTimecode(const Duration(minutes: 1, seconds: 2, milliseconds: 999)), '01:02:29');
  });

  group('phiên canh mốc', () {
    TranscriptTimingSession loaded() => TranscriptTimingSession()..load(_pasted);

    test('mỗi lần bấm ghi mốc cho câu kế tiếp, đủ câu thì xong', () {
      final session = loaded();
      expect(session.canStart, isTrue);

      session
        ..mark(const Duration(seconds: 2))
        ..mark(const Duration(seconds: 5))
        ..mark(const Duration(seconds: 9));

      expect(session.isComplete, isTrue);
      session.mark(const Duration(seconds: 12));
      expect(session.starts, hasLength(3), reason: 'đủ câu rồi thì bấm thêm không ghi');
    });

    test('bấm ở vị trí trước câu vừa đánh dấu thì không ghi mà báo', () {
      final session = loaded()..mark(const Duration(seconds: 5));

      session.mark(const Duration(seconds: 3));

      expect(session.starts, [const Duration(seconds: 5)]);
      expect(session.consumeMessage(), contains('00:05:00'));
      expect(session.consumeMessage(), isNull);
    });

    test('hoàn tác bỏ mốc cuối; dán lại câu thì canh lại từ đầu', () {
      final session = loaded()
        ..mark(const Duration(seconds: 2))
        ..mark(const Duration(seconds: 5))
        ..undo();

      expect(session.starts, [const Duration(seconds: 2)]);
      expect(session.nextIndex, 1);

      session.load(_pasted);
      expect(session.starts, isEmpty);
    });

    test('câu dán lỗi thì chưa cho bắt đầu', () {
      final session = TranscriptTimingSession()..load('chỉ một ô');
      expect(session.canStart, isFalse);
      expect(session.errors, isNotEmpty);
    });

    test('kết quả đúng định dạng file lời thoại của backend', () {
      final session = loaded()
        ..mark(const Duration(seconds: 2))
        ..mark(const Duration(seconds: 5, milliseconds: 500))
        ..mark(const Duration(seconds: 9));

      expect(
        session.output(fileName: 'scene-2.mp4', title: 'Hỏi đường tới nhà ga'),
        '## scene-2.mp4\n'
        '# Hỏi đường tới nhà ga\n'
        '00:02:00 | Khách / Khách | すみません、駅はどこですか。 | Sumimasen, eki wa doko desu ka. | Xin lỗi, nhà ga ở đâu ạ?\n'
        '00:05:15 |  | まっすぐ行ってください。 |  | Anh cứ đi thẳng.\n'
        '00:09:00 | Khách | ありがとうございます。 | Arigatoo gozaimasu. | Cảm ơn anh.',
      );
    });
  });
}
