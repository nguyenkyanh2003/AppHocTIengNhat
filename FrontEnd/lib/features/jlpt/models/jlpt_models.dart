import '../../../core/network/api_client.dart';
import '../../../core/network/api_envelope.dart';
import '../../../shared/models/xp_reward.dart';

/// Một đề trong danh sách luyện thi.
class JLPTExamBrief {
  const JLPTExamBrief({
    required this.id,
    required this.title,
    required this.level,
    this.description,
    this.year,
    this.month,
    this.timeLimit = 0,
    this.passScore = 0,
    this.totalScore = 0,
    this.totalQuestions = 0,
    this.lastResult,
  });

  final String id;
  final String title;
  final String level;
  final String? description;
  final int? year;
  final int? month;

  /// Phút.
  final int timeLimit;
  final int passScore;
  final int totalScore;
  final int totalQuestions;

  /// Kết quả gần nhất của người đang xem; `null` khi chưa thi đề này.
  final JLPTResult? lastResult;

  factory JLPTExamBrief.fromJson(JsonObject json) {
    final last = json['last_result'];
    return JLPTExamBrief(
      id: json['_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      level: json['level'] as String? ?? '',
      description: json['description'] as String?,
      year: (json['year'] as num?)?.toInt(),
      month: (json['month'] as num?)?.toInt(),
      timeLimit: _int(json['time_limit']),
      passScore: _int(json['pass_score']),
      totalScore: _int(json['total_score']),
      totalQuestions: _int(json['total_questions']),
      lastResult: last is Map ? JLPTResult.fromJson(Map<String, dynamic>.from(last)) : null,
    );
  }
}

class JLPTResult {
  const JLPTResult({required this.score, required this.isPassed, this.completedAt});

  final int score;
  final bool isPassed;
  final DateTime? completedAt;

  factory JLPTResult.fromJson(JsonObject json) => JLPTResult(
        score: _int(json['score']),
        isPassed: json['is_passed'] as bool? ?? false,
        completedAt: DateTime.tryParse(json['completed_at'] as String? ?? ''),
      );
}

class JLPTQuestion {
  const JLPTQuestion({
    required this.mondai,
    required this.questionText,
    required this.choices,
    this.image,
    this.audio,
    this.correctAnswer,
    this.explanation,
  });

  final int mondai;
  final String questionText;
  final String? image;
  final String? audio;
  final List<String> choices;

  /// Chỉ có ở đáp án sau khi nộp; đề đang thi không gửi.
  final int? correctAnswer;
  final String? explanation;

  factory JLPTQuestion.fromJson(JsonObject json) => JLPTQuestion(
        mondai: _int(json['mondai']),
        questionText: json['question_text'] as String? ?? '',
        image: _asset(json['image']),
        audio: _asset(json['audio']),
        choices: [for (final choice in json['choices'] as List? ?? const []) '$choice'],
        correctAnswer: (json['correct_answer'] as num?)?.toInt(),
        explanation: json['explanation'] as String?,
      );
}

/// Nhóm câu dùng chung một đoạn đọc hoặc một bài nghe.
class JLPTGroupQuestion {
  const JLPTGroupQuestion({
    required this.mondai,
    required this.questions,
    this.groupContent,
    this.groupImage,
    this.groupAudio,
    this.transcript,
  });

  final int mondai;
  final String? groupContent;
  final String? groupImage;
  final String? groupAudio;
  final String? transcript;
  final List<JLPTQuestion> questions;

  factory JLPTGroupQuestion.fromJson(JsonObject json) => JLPTGroupQuestion(
        mondai: _int(json['mondai']),
        groupContent: json['group_content'] as String?,
        groupImage: _asset(json['group_image']),
        groupAudio: _asset(json['group_audio']),
        transcript: json['transcript'] as String?,
        questions: _listOf(json['questions'], JLPTQuestion.fromJson),
      );
}

/// Một đề đầy đủ bốn phần. Khi thi thì câu không kèm đáp án; khi xem đáp án
/// sau khi nộp thì có.
class JLPTExamDetail {
  const JLPTExamDetail({
    required this.id,
    required this.title,
    required this.level,
    this.timeLimit = 0,
    this.passScore = 0,
    this.totalScore = 0,
    this.mojiGoi = const [],
    this.bunpou = const [],
    this.dokkai = const [],
    this.choukai = const [],
  });

  final String id;
  final String title;
  final String level;

  /// Phút.
  final int timeLimit;
  final int passScore;
  final int totalScore;
  final List<JLPTQuestion> mojiGoi;
  final List<JLPTQuestion> bunpou;
  final List<JLPTGroupQuestion> dokkai;
  final List<JLPTGroupQuestion> choukai;

  /// Mọi câu theo đúng thứ tự trong đề: hai phần câu lẻ rồi câu trong từng nhóm.
  List<JLPTQuestion> get allQuestions => [
        ...mojiGoi,
        ...bunpou,
        for (final group in [...dokkai, ...choukai]) ...group.questions,
      ];

  factory JLPTExamDetail.fromJson(JsonObject json) {
    final sections = json['sections'] is Map ? Map<String, dynamic>.from(json['sections'] as Map) : const <String, dynamic>{};
    return JLPTExamDetail(
      id: json['_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      level: json['level'] as String? ?? '',
      timeLimit: _int(json['time_limit']),
      passScore: _int(json['pass_score']),
      totalScore: _int(json['total_score']),
      mojiGoi: _listOf(sections['moji_goi'], JLPTQuestion.fromJson),
      bunpou: _listOf(sections['bunpou'], JLPTQuestion.fromJson),
      dokkai: _listOf(sections['dokkai'], JLPTGroupQuestion.fromJson),
      choukai: _listOf(sections['choukai'], JLPTGroupQuestion.fromJson),
    );
  }
}

/// Điểm một lượt thi do server chấm.
class JLPTSubmitResult {
  const JLPTSubmitResult({
    required this.totalScore,
    required this.vocabScore,
    required this.grammarScore,
    required this.readingScore,
    required this.listeningScore,
    required this.passed,
    required this.duration,
    this.xp,
  });

  final int totalScore;
  final int vocabScore;
  final int grammarScore;
  final int readingScore;
  final int listeningScore;
  final bool passed;

  /// Giây.
  final int duration;

  /// XP lượt thi này nhận; `null` khi phản hồi không kèm.
  final XpReward? xp;

  factory JLPTSubmitResult.fromJson(JsonObject json) {
    final sections = json['section_scores'] as Map? ?? const {};
    return JLPTSubmitResult(
      totalScore: _int(json['total_score']),
      vocabScore: _int(sections['moji_goi']),
      grammarScore: _int(sections['bunpou']),
      readingScore: _int(sections['dokkai']),
      listeningScore: _int(sections['choukai']),
      passed: json['passed'] as bool? ?? false,
      duration: _int(json['duration']),
      xp: XpReward.fromJson(json['xp']),
    );
  }
}

int _int(Object? value) => (value as num?)?.toInt() ?? 0;

String? _asset(Object? value) => value is String && value.isNotEmpty ? ApiClient.resolveAssetUrl(value) : null;

List<T> _listOf<T>(Object? value, T Function(JsonObject json) fromJson) => [
      for (final item in value as List? ?? const [])
        if (item is Map) fromJson(Map<String, dynamic>.from(item)),
    ];
