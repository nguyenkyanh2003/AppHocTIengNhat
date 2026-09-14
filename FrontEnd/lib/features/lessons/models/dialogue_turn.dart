/// Một lượt thoại trong hội thoại của bài học tình huống.
///
/// `reading` là cách đọc cả câu bằng hiragana/katakana, không phải ruby text
/// theo từng kanji.
class DialogueTurn {
  final String speaker;
  final String textJa;
  final String reading;
  final String textVi;
  final String? audioUrl;

  const DialogueTurn({
    required this.speaker,
    required this.textJa,
    required this.reading,
    required this.textVi,
    this.audioUrl,
  });

  factory DialogueTurn.fromJson(Map<String, dynamic> json) {
    return DialogueTurn(
      speaker: json['speaker']?.toString() ?? '',
      textJa: json['text_ja']?.toString() ?? '',
      reading: json['reading']?.toString() ?? '',
      textVi: json['text_vi']?.toString() ?? '',
      audioUrl: json['audio_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'speaker': speaker,
        'text_ja': textJa,
        'reading': reading,
        'text_vi': textVi,
        'audio_url': audioUrl,
      };

  /// Bỏ qua phần tử không phải map thay vì ném lỗi: bài học cũ không có
  /// `dialogue`, và dữ liệu lỗi thời không được làm sập màn hình.
  static List<DialogueTurn> listFromJson(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => DialogueTurn.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}
