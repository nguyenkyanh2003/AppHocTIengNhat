import '../../../core/network/api_client.dart';

/// Một dòng lời thoại của video, kèm mốc thời gian để chạy theo video.
class TranscriptLine {
  const TranscriptLine({
    required this.start,
    required this.textJa,
    required this.textVi,
    this.end,
    this.speakerJa,
    this.speakerVi,
    this.romaji,
  });

  factory TranscriptLine.fromJson(Map<String, dynamic> json) {
    Duration? seconds(dynamic value) {
      final number = value is num ? value.toDouble() : null;
      if (number == null) return null;
      return Duration(milliseconds: (number * 1000).round());
    }

    return TranscriptLine(
      start: seconds(json['start_seconds']) ?? Duration.zero,
      end: seconds(json['end_seconds']),
      speakerJa: json['speaker_ja']?.toString(),
      speakerVi: json['speaker_vi']?.toString(),
      textJa: json['text_ja']?.toString() ?? '',
      romaji: json['romaji']?.toString(),
      textVi: json['text_vi']?.toString() ?? '',
    );
  }

  final Duration start;
  final Duration? end;
  final String? speakerJa;
  final String? speakerVi;
  final String textJa;
  final String? romaji;
  final String textVi;

  /// `mm:ss` để hiện ở cột trái, giống bản gốc.
  String get label {
    final total = start.inSeconds;
    final minutes = (total ~/ 60).toString().padLeft(2, '0');
    final seconds = (total % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

/// Video của bài học kèm lời thoại.
class LessonVideo {
  const LessonVideo({
    required this.title,
    required this.url,
    this.description,
    this.source,
    this.duration,
    this.transcript = const [],
  });

  factory LessonVideo.fromJson(Map<String, dynamic> json) {
    final seconds = json['duration_seconds'];
    return LessonVideo(
      title: json['title']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      description: json['description']?.toString(),
      source: json['source']?.toString(),
      duration: seconds is num
          ? Duration(milliseconds: (seconds * 1000).round())
          : null,
      transcript: (json['transcript'] as List? ?? const [])
          .whereType<Map>()
          .map((line) =>
              TranscriptLine.fromJson(Map<String, dynamic>.from(line)))
          .toList(),
    );
  }

  final String title;

  /// Đường dẫn do backend trả về: tương đối (`/uploads/...`) hoặc tuyệt đối.
  final String url;

  final String? description;

  /// Nguồn của video, hiện dưới trình phát để ghi công.
  final String? source;

  /// Thời lượng backend đọc sẵn từ file, để khung chờ hiện được trước khi tải
  /// video; `null` với video nhập từ trước khi có trường này.
  final Duration? duration;

  final List<TranscriptLine> transcript;

  /// URL đầy đủ để trình phát mở được trên cả web lẫn thiết bị: đường dẫn
  /// tương đối được ghép với địa chỉ máy chủ đang dùng.
  String get playbackUrl => ApiClient.resolveAssetUrl(url) ?? url;

  static List<LessonVideo> listFromJson(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => LessonVideo.fromJson(Map<String, dynamic>.from(item)))
        .where((video) => video.url.isNotEmpty)
        .toList();
  }
}

/// Dòng lời thoại đang được nói tại [position], hoặc `null` nếu chưa tới dòng
/// nào. Dùng chung cho việc tô sáng và cuộn theo video.
///
/// Quét từ cuối lên để dòng cuối cùng đã bắt đầu thắng, kể cả khi người dùng
/// tua nhảy giữa chừng.
int? activeTranscriptIndex(List<TranscriptLine> lines, Duration position) {
  for (var index = lines.length - 1; index >= 0; index--) {
    final line = lines[index];
    if (position < line.start) continue;
    // Có `end` thì chỉ sáng trong khoảng của chính dòng đó; không có `end`
    // thì sáng cho tới khi dòng sau bắt đầu.
    final end =
        line.end ?? (index + 1 < lines.length ? lines[index + 1].start : null);
    if (end != null && position >= end) return null;
    return index;
  }
  return null;
}
