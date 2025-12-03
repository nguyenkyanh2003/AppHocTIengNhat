class Exercise {
  final String id;
  final String lessonId;
  final String title;
  final String type; // Từ vựng, Ngữ pháp, Kanji, Tổng hợp
  final String level; // N5, N4, N3, N2, N1
  final String? description;
  final List<Question> questions;
  final int timeLimit; 
  final int passScore;
  final bool isActive;
  final int totalAttempts;
  final int questionCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Exercise({
    required this.id,
    required this.lessonId,
    required this.title,
    required this.type,
    required this.level,
    this.description,
    required this.questions,
    required this.timeLimit,
    required this.passScore,
    required this.isActive,
    required this.totalAttempts,
    required this.questionCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    // Handle lesson_id - can be String or Object
    String lessonIdStr = '';
    if (json['lesson_id'] != null) {
      if (json['lesson_id'] is String) {
        lessonIdStr = json['lesson_id'];
      } else if (json['lesson_id'] is Map) {
        lessonIdStr = json['lesson_id']['_id'] ?? '';
      }
    }
    
    return Exercise(
      id: json['_id'] ?? '',
      lessonId: lessonIdStr,
      title: json['title'] ?? '',
      type: json['type'] ?? 'Tổng hợp',
      level: json['level'] ?? 'N5',
      description: json['description'],
      questions: (json['questions'] as List?)
              ?.map((q) => Question.fromJson(q))
              .toList() ??
          [],
      timeLimit: json['time_limit'] ?? 0,
      passScore: json['pass_score'] ?? 60,
      isActive: json['is_active'] ?? true,
      totalAttempts: json['total_attempts'] ?? 0,
      questionCount: json['question_count'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'lesson_id': lessonId,
      'title': title,
      'type': type,
      'level': level,
      'description': description,
      'questions': questions.map((q) => q.toJson()).toList(),
      'time_limit': timeLimit,
      'pass_score': passScore,
      'is_active': isActive,
      'total_attempts': totalAttempts,
      'question_count': questionCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class Question {
  final String id;
  final String content;
  final List<Answer> answers;
  final String? explanation;

  Question({
    required this.id,
    required this.content,
    required this.answers,
    this.explanation,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['_id'] ?? '',
      content: json['content'] ?? '',
      answers: (json['answers'] as List?)
              ?.map((a) => Answer.fromJson(a))
              .toList() ??
          [],
      explanation: json['explanation'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'content': content,
      'answers': answers.map((a) => a.toJson()).toList(),
      'explanation': explanation,
    };
  }
}

class Answer {
  final String id;
  final String content;
  final bool isCorrect;

  Answer({
    required this.id,
    required this.content,
    required this.isCorrect,
  });

  factory Answer.fromJson(Map<String, dynamic> json) {
    return Answer(
      id: json['_id'] ?? '',
      content: json['content'] ?? '',
      isCorrect: json['is_correct'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'content': content,
      'is_correct': isCorrect,
    };
  }
}

// Model cho kết quả làm bài
class ExerciseResult {
  final String id;
  final String userId;
  final String exerciseId;
  final double score;
  final int correctAnswers;
  final int totalQuestions;
  final int timeSpent; // giây
  final bool passed;
  final List<UserAnswer> answers;
  final DateTime createdAt;
  
  // Optional exercise info when populated from API
  final String? exerciseTitle;
  final String? exerciseLevel;
  final String? exerciseType;

  ExerciseResult({
    required this.id,
    required this.userId,
    required this.exerciseId,
    required this.score,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.timeSpent,
    required this.passed,
    required this.answers,
    required this.createdAt,
    this.exerciseTitle,
    this.exerciseLevel,
    this.exerciseType,
  });

  factory ExerciseResult.fromJson(Map<String, dynamic> json) {
    // Handle exercise_id - can be String or Object
    String exerciseIdStr = '';
    String? exerciseTitle;
    String? exerciseLevel;
    String? exerciseType;
    
    if (json['exercise_id'] != null) {
      if (json['exercise_id'] is String) {
        exerciseIdStr = json['exercise_id'];
      } else if (json['exercise_id'] is Map) {
        final exerciseData = json['exercise_id'] as Map<String, dynamic>;
        exerciseIdStr = exerciseData['_id'] ?? '';
        exerciseTitle = exerciseData['title'];
        exerciseLevel = exerciseData['level'];
        exerciseType = exerciseData['type'];
      }
    }

    return ExerciseResult(
      id: json['_id'] ?? '',
      userId: json['user_id'] ?? '',
      exerciseId: exerciseIdStr,
      score: (json['score'] ?? 0).toDouble(),
      correctAnswers: json['correct_answers'] ?? json['correct_count'] ?? 0,
      totalQuestions: json['total_questions'] ?? 0,
      timeSpent: json['time_spent'] ?? 0,
      passed: json['passed'] ?? json['is_passed'] ?? false,
      answers: (json['answers'] as List?)
              ?.map((a) => UserAnswer.fromJson(a))
              .toList() ??
          (json['user_answers'] as List?)
              ?.map((a) => UserAnswer.fromJson(a))
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : (json['completed_at'] != null
              ? DateTime.parse(json['completed_at'])
              : DateTime.now()),
      exerciseTitle: exerciseTitle,
      exerciseLevel: exerciseLevel,
      exerciseType: exerciseType,
    );
  }

  String get timeSpentFormatted {
    final minutes = timeSpent ~/ 60;
    final seconds = timeSpent % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

class UserAnswer {
  final String questionId;
  final String answerId;
  final bool isCorrect;
  final String? correctAnswerId;

  UserAnswer({
    required this.questionId,
    required this.answerId,
    required this.isCorrect,
    this.correctAnswerId,
  });

  factory UserAnswer.fromJson(Map<String, dynamic> json) {
    return UserAnswer(
      questionId: json['question_id'] ?? '',
      answerId: json['answer_id'] ?? '',
      isCorrect: json['is_correct'] ?? false,
      correctAnswerId: json['correct_answer_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question_id': questionId,
      'answer_id': answerId,
    };
  }
}
