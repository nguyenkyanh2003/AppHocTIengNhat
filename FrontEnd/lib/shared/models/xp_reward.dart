/// XP một lượt làm bài tập hoặc đề JLPT nhận được, do server tính.
///
/// Mỗi bài/đề chỉ cho tới một mức trong đời tài khoản (bài tập 10, đề JLPT 20):
/// lượt làm nhận phần còn thiếu, làm lại khi đã đủ được 0. App không tự tính
/// luật này mà chỉ hiện đúng hai con số server trả về.
class XpReward {
  const XpReward({required this.awarded, required this.remaining});

  /// XP lượt này nhận.
  final int awarded;

  /// XP bài/đề đó còn cho được sau lượt này; 0 là đã nhận đủ.
  final int remaining;

  /// `null` khi phản hồi không kèm XP (đọc lại kết quả từ lịch sử, lượt nộp
  /// từ bản cũ): không có gì chắc chắn để báo thì không báo.
  static XpReward? fromJson(Object? json) {
    if (json is! Map) return null;
    final awarded = json['awarded'];
    if (awarded is! num) return null;
    final remaining = json['remaining'];
    return XpReward(awarded: awarded.toInt(), remaining: remaining is num ? remaining.toInt() : 0);
  }
}
