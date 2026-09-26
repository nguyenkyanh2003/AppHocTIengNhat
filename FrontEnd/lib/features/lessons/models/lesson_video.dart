import '../../../core/network/api_client.dart';

/// Một dòng lời thoại của video, kèm mốc thời gian để chạy theo video.
class TranscriptLine {
  const TranscriptLine({
    required this.start,
    required this.textJa,
    required this.textVi,
    this.end,
    this.speakerJa,
    this.speakerRomaji,
    this.speakerVi,
    this.romaji,
    this.isKeyPhrase = false,
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
      speakerRomaji: json['speaker_romaji']?.toString(),
      speakerVi: json['speaker_vi']?.toString(),
      textJa: json['text_ja']?.toString() ?? '',
      romaji: json['romaji']?.toString(),
      textVi: json['text_vi']?.toString() ?? '',
      isKeyPhrase: json['key_phrase'] == true,
    );
  }

  final Duration start;
  final Duration? end;
  final String? speakerJa;
  final String? speakerRomaji;
  final String? speakerVi;
  final String textJa;
  final String? romaji;
  final String textVi;

  /// Câu then chốt của cảnh, hiện ở phần "Mẫu câu".
  final bool isKeyPhrase;

  /// `mm:ss` để hiện ở cột trái, giống bản gốc.
  String get label {
    final total = start.inSeconds;
    final minutes = (total ~/ 60).toString().padLeft(2, '0');
    final seconds = (total % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

/// Một từ trong bảng "Từ vựng" của video.
class VideoWord {
  const VideoWord({required this.word, required this.meaning, this.reading, this.romaji});

  factory VideoWord.fromJson(Map<String, dynamic> json) => VideoWord(
        word: json['word']?.toString() ?? '',
        reading: json['reading']?.toString(),
        romaji: json['romaji']?.toString(),
        meaning: json['meaning']?.toString() ?? '',
      );

  final String word;
  final String? reading;
  final String? romaji;
  final String meaning;
}

/// Video của bài học kèm lời thoại.
class LessonVideo {
  const LessonVideo({
    required this.title,
    required this.url,
    this.description,
    this.source,
    this.duration,
    this.isReview = false,
    this.transcript = const [],
    this.vocabulary = const [],
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
      isReview: json['kind'] == 'review',
      transcript: (json['transcript'] as List? ?? const [])
          .whereType<Map>()
          .map((line) =>
              TranscriptLine.fromJson(Map<String, dynamic>.from(line)))
          .toList(),
      vocabulary: (json['vocabulary'] as List? ?? const [])
          .whereType<Map>()
          .map((word) => VideoWord.fromJson(Map<String, dynamic>.from(word)))
          .where((word) => word.word.isNotEmpty)
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

  /// Video ôn tập cuối chủ đề, khác với các cảnh tình huống: không đánh số
  /// "Cảnh N" mà mang tên riêng.
  final bool isReview;

  final List<TranscriptLine> transcript;

  /// Bảng từ vựng của video; rỗng thì không hiện phần "Từ vựng".
  final List<VideoWord> vocabulary;

  /// Câu then chốt, theo thứ tự trong video.
  List<TranscriptLine> get keyPhrases => transcript.where((line) => line.isKeyPhrase).toList();

  /// Có gì để học cạnh video (lời thoại hay bảng từ) — không có thì video
  /// đứng một mình, không dựng khung trống bên cạnh.
  bool get hasStudyContent => transcript.isNotEmpty || vocabulary.isNotEmpty;

  /// Lúc câu [line] kết thúc: mốc `end` nếu có, không thì lúc câu sau bắt đầu;
  /// `null` với câu cuối không có `end` (phát tới hết video).
  Duration? endOf(TranscriptLine line) {
    if (line.end != null) return line.end;
    final index = transcript.indexOf(line);
    return index >= 0 && index + 1 < transcript.length ? transcript[index + 1].start : null;
  }

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

/// Số thứ tự cảnh (1, 2, 3…) của video tại [index], đếm riêng các cảnh tình
/// huống; `null` với video ôn tập. Dùng chung cho nhãn ở lộ trình học và ở
/// hàng chọn video, để hai nơi không bao giờ đánh số lệch nhau.
int? sceneNumber(List<LessonVideo> videos, int index) {
  if (videos[index].isReview) return null;
  return videos.take(index + 1).where((video) => !video.isReview).length;
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
