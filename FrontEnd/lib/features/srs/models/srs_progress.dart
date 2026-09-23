/// Tiến độ ôn một từ, đúng như server trả (spec SRS §3.3).
///
/// Client không tự tính lịch: [nextReview] là giá trị nguyên vẹn của server,
/// và được gửi lại nguyên vẹn làm `expected_next_review` khi trả lời hay đặt
/// lại — để một request cũ gửi muộn không áp vào kỳ ôn mới.
class SrsProgress {
  const SrsProgress({
    required this.id,
    required this.itemId,
    required this.itemType,
    required this.box,
    required this.nextReview,
    required this.streak,
  });

  factory SrsProgress.fromJson(Map<String, dynamic> json) => SrsProgress(
        id: json['_id'] as String? ?? '',
        itemId: json['item_id'] as String? ?? '',
        itemType: json['item_type'] as String? ?? itemTypeVocabulary,
        box: json['box'] as int? ?? 1,
        nextReview: DateTime.parse(json['next_review'] as String).toUtc(),
        streak: json['streak'] as int? ?? 0,
      );

  /// Mốc 1 chỉ nghiệm thu từ vựng; server từ chối mọi loại khác.
  static const itemTypeVocabulary = 'Vocabulary';

  static const int maxBox = 5;

  final String id;
  final String itemId;
  final String itemType;

  /// Hộp Leitner 1–5.
  final int box;

  /// Luôn ở UTC, để khi gửi lại ra đúng chuỗi server đã phát.
  final DateTime nextReview;

  /// Số lần nhớ liên tiếp của riêng thẻ này (khác chuỗi ngày học).
  final int streak;

  bool isDueAt(DateTime now) => !nextReview.isAfter(now.toUtc());
}
