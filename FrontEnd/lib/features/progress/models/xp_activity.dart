/// Nhóm hoạt động của một dòng lịch sử XP, dùng để lọc và chọn biểu tượng.
enum XpActivityKind {
  lesson('Bài học'),
  exercise('Bài tập'),
  review('Ôn tập'),
  reward('Thưởng'),
  other('Khác');

  const XpActivityKind(this.label);

  final String label;
}

/// Suy nhóm từ nhãn server gửi (`REASON_LABELS` ở backend) và nhãn tự do của dữ
/// liệu cũ. Không nhận ra thì xếp vào [XpActivityKind.other], vẫn hiện ở "Tất cả".
XpActivityKind xpActivityKindOf(String reason) {
  final text = reason.toLowerCase();
  if (_hasAny(
      text, const ['thưởng', 'thành tích', 'chuỗi', 'streak', 'achievement'])) {
    return XpActivityKind.reward;
  }
  if (_hasAny(text, const ['ôn tập', 'srs', 'review'])) {
    return XpActivityKind.review;
  }
  if (_hasAny(text, const ['bài tập', 'jlpt', 'exercise'])) {
    return XpActivityKind.exercise;
  }
  if (_hasAny(
      text, const ['bài học', 'trong bài', 'lesson', 'từ vựng', 'kanji'])) {
    return XpActivityKind.lesson;
  }
  return XpActivityKind.other;
}

bool _hasAny(String text, List<String> words) => words.any(text.contains);
