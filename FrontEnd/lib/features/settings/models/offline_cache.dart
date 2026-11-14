/// Trạng thái bộ nhớ đệm ngoại tuyến trên máy.
class OfflineCacheStatus {
  const OfflineCacheStatus({
    required this.enabled,
    required this.items,
    required this.bytes,
    this.lastSync,
  });

  /// Có dùng nội dung đã tải khi máy chủ không truy cập được hay không.
  final bool enabled;

  /// Số gói nội dung (mỗi endpoint đã tải là một gói).
  final int items;
  final int bytes;
  final DateTime? lastSync;

  bool get isEmpty => items == 0;
}

/// Nhóm nội dung người dùng chọn tải về để học ngoại tuyến.
class OfflineContentSelection {
  const OfflineContentSelection({
    this.lessons = true,
    this.vocabulary = true,
    this.kanji = true,
    this.grammar = true,
  });

  final bool lessons;
  final bool vocabulary;
  final bool kanji;
  final bool grammar;

  bool get isEmpty => !lessons && !vocabulary && !kanji && !grammar;

  OfflineContentSelection copyWith({bool? lessons, bool? vocabulary, bool? kanji, bool? grammar}) =>
      OfflineContentSelection(
        lessons: lessons ?? this.lessons,
        vocabulary: vocabulary ?? this.vocabulary,
        kanji: kanji ?? this.kanji,
        grammar: grammar ?? this.grammar,
      );
}
