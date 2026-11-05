import '../../../core/network/api_client.dart';

/// Một câu luyện nhanh, rút từ các đề đã xuất bản.
class JlptPracticeQuestion {
  const JlptPracticeQuestion({
    required this.questionText,
    required this.choices,
    required this.correctAnswer,
    this.explanation,
    this.passage,
    this.audioUrl,
    this.transcript,
    this.level,
    this.examTitle,
  });

  factory JlptPracticeQuestion.fromJson(Map<String, dynamic> json) {
    final audio = json['group_audio'] as String?;
    return JlptPracticeQuestion(
      questionText: (json['question_text'] ?? '').toString(),
      choices: (json['choices'] as List? ?? const [])
          .map((choice) => choice.toString())
          .toList(),
      correctAnswer: (json['correct_answer'] as num?)?.toInt() ?? -1,
      explanation: json['explanation'] as String?,
      passage: json['group_content'] as String?,
      audioUrl: audio == null || audio.isEmpty
          ? null
          : ApiClient.resolveAssetUrl(audio),
      transcript: json['transcript'] as String?,
      level: json['level'] as String?,
      examTitle: json['exam_title'] as String?,
    );
  }

  final String questionText;
  final List<String> choices;

  /// Vị trí đáp án đúng trong [choices].
  final int correctAnswer;
  final String? explanation;

  /// Đoạn văn của câu đọc hiểu.
  final String? passage;

  /// File nghe và lời thoại của câu nghe hiểu.
  final String? audioUrl;
  final String? transcript;
  final String? level;
  final String? examTitle;
}
