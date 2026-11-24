import '../../../core/network/api_envelope.dart';
import '../../../shared/models/xp_reward.dart';

/// Một bài tập trắc nghiệm. Ở danh sách thì [questions] rỗng và chỉ có
/// [questionCount]; ở đề làm bài thì câu trả lời chưa có cờ đúng/sai.
class Exercise {
  const Exercise({
    required this.id,
    required this.title,
    required this.type,
    required this.level,
    this.lessonId = '',
    this.description,
    this.questions = const [],
    this.timeLimit = 0,
    this.passScore = 60,
    this.totalAttempts = 0,
    int? questionCount,
  }) : _questionCount = questionCount;

  final String id;
  final String lessonId;
  final String title;
  final String type;
  final String level;
  final String? description;
  final List<Question> questions;

  /// Phút; `0` là không giới hạn.
  final int timeLimit;
  final int passScore;
  final int totalAttempts;
  final int? _questionCount;

  int get questionCount => _questionCount ?? questions.length;

  factory Exercise.fromJson(JsonObject json) {
    final lesson = json['lesson_id'];
    return Exercise(
      id: json['_id'] as String? ?? '',
      lessonId: lesson is Map ? lesson['_id'] as String? ?? '' : lesson as String? ?? '',
      title: json['title'] as String? ?? '',
      type: json['type'] as String? ?? 'Tổng hợp',
      level: json['level'] as String? ?? 'N5',
      description: json['description'] as String?,
      questions: _listOf(json['questions'], Question.fromJson),
      timeLimit: (json['time_limit'] as num?)?.toInt() ?? 0,
      passScore: (json['pass_score'] as num?)?.toInt() ?? 60,
      totalAttempts: (json['total_attempts'] as num?)?.toInt() ?? 0,
      questionCount: (json['question_count'] as num?)?.toInt(),
    );
  }
}

class Question {
  const Question({required this.id, required this.content, required this.answers, this.explanation});

  final String id;
  final String content;
  final List<Answer> answers;

  /// Chỉ có khi xem lại sau khi nộp.
  final String? explanation;

  factory Question.fromJson(JsonObject json) => Question(
        id: json['_id'] as String? ?? '',
        content: json['content'] as String? ?? '',
        answers: _listOf(json['answers'], Answer.fromJson),
        explanation: json['explanation'] as String?,
      );
}

class Answer {
  const Answer({required this.id, required this.content, this.isCorrect = false});

  final String id;
  final String content;

  /// Chỉ đúng nghĩa khi xem lại sau khi nộp; đề làm bài không gửi cờ này.
  final bool isCorrect;

  factory Answer.fromJson(JsonObject json) => Answer(
        id: json['_id'] as String? ?? '',
        content: json['content'] as String? ?? '',
        isCorrect: json['is_correct'] as bool? ?? false,
      );
}

/// Kết quả một lần làm bài: cùng một hình dạng cho lần nộp, lịch sử và xem lại.
class ExerciseResult {
  const ExerciseResult({
    required this.id,
    required this.exerciseId,
    required this.score,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.timeSpent,
    required this.passed,
    required this.createdAt,
    this.answers = const [],
    this.exercise,
    this.xp,
  });

  final String id;
  final String exerciseId;
  final double score;
  final int correctAnswers;
  final int totalQuestions;

  /// Giây.
  final int timeSpent;
  final bool passed;
  final DateTime createdAt;
  final List<UserAnswer> answers;

  /// Bài tập kèm theo: tóm tắt ở lịch sử, đề đầy đủ (đáp án, lời giải) khi xem
  /// lại; `null` khi bài đã bị xoá.
  final Exercise? exercise;

  /// XP lượt làm này nhận — chỉ có trong phản hồi nộp bài, không có khi đọc
  /// lại kết quả từ lịch sử.
  final XpReward? xp;

  factory ExerciseResult.fromJson(JsonObject json) {
    final exercise = json['exercise'];
    return ExerciseResult(
      id: json['_id'] as String? ?? '',
      exerciseId: json['exercise_id'] as String? ?? '',
      score: (json['score'] as num?)?.toDouble() ?? 0,
      correctAnswers: (json['correct_answers'] as num?)?.toInt() ?? 0,
      totalQuestions: (json['total_questions'] as num?)?.toInt() ?? 0,
      timeSpent: (json['time_spent'] as num?)?.toInt() ?? 0,
      passed: json['passed'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      answers: _listOf(json['answers'], UserAnswer.fromJson),
      exercise: exercise is Map ? Exercise.fromJson(Map<String, dynamic>.from(exercise)) : null,
      xp: XpReward.fromJson(json['xp']),
    );
  }
}

/// Đáp án người học chọn cho một câu, kèm đáp án đúng do server chấm.
class UserAnswer {
  const UserAnswer({required this.questionId, required this.answerId, required this.isCorrect, this.correctAnswerId});

  final String questionId;
  final String answerId;
  final bool isCorrect;
  final String? correctAnswerId;

  factory UserAnswer.fromJson(JsonObject json) => UserAnswer(
        questionId: json['question_id'] as String? ?? '',
        answerId: json['answer_id'] as String? ?? '',
        isCorrect: json['is_correct'] as bool? ?? false,
        correctAnswerId: json['correct_answer_id'] as String?,
      );
}

List<T> _listOf<T>(Object? value, T Function(JsonObject json) fromJson) => [
      for (final item in value as List? ?? const [])
        if (item is Map) fromJson(Map<String, dynamic>.from(item)),
    ];
