/// Canh mốc thời gian cho lời thoại video: nội dung câu gõ sẵn, mốc bắt đầu
/// ghi lại trong lúc xem video.
///
/// Định dạng dòng khớp với file `data/lesson-videos/<bài>.txt` ở backend
/// (`scripts/transcript-text.js`), chỉ thiếu ô mốc thời gian ở đầu:
///
///   người nói JA / VI | câu tiếng Nhật | roma-ji | nghĩa tiếng Việt
///
/// Dòng đã có mốc (năm ô) cũng nhận — ô mốc bị bỏ để canh lại từ đầu.
library;

/// Một câu chờ canh mốc.
class TimingLine {
  const TimingLine({
    required this.speaker,
    required this.textJa,
    required this.romaji,
    required this.textVi,
  });

  /// Ô người nói nguyên văn (`オウ / Ou`), có thể rỗng.
  final String speaker;
  final String textJa;
  final String romaji;
  final String textVi;
}

/// Kết quả đọc phần câu thoại dán vào: các câu hợp lệ và lỗi kèm số dòng.
typedef TimingLinesParse = ({List<TimingLine> lines, List<String> errors});

TimingLinesParse parseTimingLines(String text) {
  final lines = <TimingLine>[];
  final errors = <String>[];
  final rows = text.split(RegExp(r'\r?\n'));

  for (var index = 0; index < rows.length; index++) {
    final content = rows[index].trim();
    // Dòng trống, ghi chú và tiêu đề cảnh (`## scene-1.mp4`) không phải câu.
    if (content.isEmpty || content.startsWith('#')) continue;

    var cells = content.split('|').map((cell) => cell.trim()).toList();
    if (cells.length == 5) cells = cells.sublist(1);
    if (cells.length != 4) {
      errors.add('Dòng ${index + 1}: cần 4 ô "người nói | tiếng Nhật | roma-ji | tiếng Việt", đang có ${cells.length}.');
      continue;
    }

    final [speaker, textJa, romaji, textVi] = cells;
    if (textJa.isEmpty) {
      errors.add('Dòng ${index + 1}: thiếu câu tiếng Nhật.');
    } else if (textVi.isEmpty) {
      errors.add('Dòng ${index + 1}: thiếu nghĩa tiếng Việt.');
    } else {
      lines.add(TimingLine(speaker: speaker, textJa: textJa, romaji: romaji, textVi: textVi));
    }
  }
  return (lines: lines, errors: errors);
}

/// `mm:ss:ff` — `ff` là số khung hình ở 30 khung/giây, đúng định dạng backend
/// đọc (`parseTimecode`) và đủ mịn để câu sáng lên đúng lúc bắt đầu nói.
String formatTimecode(Duration position) {
  final minutes = position.inMinutes.toString().padLeft(2, '0');
  final seconds = position.inSeconds.remainder(60).toString().padLeft(2, '0');
  final frames = (position.inMilliseconds.remainder(1000) * 30 ~/ 1000).toString().padLeft(2, '0');
  return '$minutes:$seconds:$frames';
}

/// Phần lời thoại của một cảnh, dán thẳng vào file `.txt` của bài để thay
/// phần cũ dưới cùng tiêu đề `## <tên file video>`.
///
/// Chỉ ghi mốc bắt đầu: câu sáng cho tới khi câu sau bắt đầu, đúng như bảng
/// lời thoại trong app đang hiểu.
String buildTranscriptSection({
  required String fileName,
  required String title,
  required List<TimingLine> lines,
  required List<Duration> starts,
}) {
  assert(starts.length == lines.length, 'mỗi câu cần đúng một mốc bắt đầu');
  return [
    '## $fileName',
    '# $title',
    for (var index = 0; index < lines.length; index++)
      [
        formatTimecode(starts[index]),
        lines[index].speaker,
        lines[index].textJa,
        lines[index].romaji,
        lines[index].textVi,
      ].join(' | '),
  ].join('\n');
}
