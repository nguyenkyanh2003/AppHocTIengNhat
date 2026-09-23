import '../../vocabulary/models/vocabulary.dart';
import 'srs_progress.dart';

/// Một thẻ đến hạn: tiến độ kèm nội dung để vẽ hai mặt.
///
/// Nội dung đã bị xoá thì [item] là `null` và [unavailable] là `true`: thẻ vẫn
/// hiện để người học bỏ qua hoặc xoá tiến độ, nhưng không trả lời được.
class SrsCard {
  const SrsCard({
    required this.progress,
    required this.item,
    required this.unavailable,
  });

  factory SrsCard.fromJson(Map<String, dynamic> json) {
    final item = json['item'];
    return SrsCard(
      progress: SrsProgress.fromJson(json),
      item: item is Map
          ? Vocabulary.fromJson(Map<String, dynamic>.from(item))
          : null,
      unavailable: json['unavailable'] as bool? ?? item == null,
    );
  }

  final SrsProgress progress;
  final Vocabulary? item;
  final bool unavailable;

  String get itemId => progress.itemId;

  SrsCard copyWith({SrsProgress? progress, bool? unavailable}) => SrsCard(
        progress: progress ?? this.progress,
        item: item,
        unavailable: unavailable ?? this.unavailable,
      );
}

/// Một đợt thẻ đến hạn. Không có `page`: luồng ôn lấy lại đợt đầu kèm danh
/// sách loại trừ thay vì lật trang (spec SRS §3.4).
class SrsBatch {
  const SrsBatch({required this.cards, required this.limit});

  final List<SrsCard> cards;
  final int limit;
}

/// Phân bố thẻ theo hộp; [byBox] luôn đủ khoá 1–5.
class SrsStats {
  const SrsStats({
    required this.totalCards,
    required this.dueCount,
    required this.byBox,
  });

  factory SrsStats.fromJson(Map<String, dynamic> json) {
    final raw = Map<String, dynamic>.from(json['by_box'] as Map? ?? const {});
    return SrsStats(
      totalCards: json['total_cards'] as int? ?? 0,
      dueCount: json['due_count'] as int? ?? 0,
      byBox: {
        for (var box = 1; box <= SrsProgress.maxBox; box++)
          box: raw['$box'] as int? ?? 0,
      },
    );
  }

  final int totalCards;
  final int dueCount;
  final Map<int, int> byBox;
}
