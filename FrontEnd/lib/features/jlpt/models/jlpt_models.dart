import '../../../core/network/api_client.dart';

class JLPTExamBrief {
  final String id;
  final String title;
  final String? description;
  final String level;
  final int? year;
  final int? month;
  final int timeLimit;
  final int passScore;
  final int totalScore;
  final int totalQuestions;
  final int totalViews;
  final DateTime createdAt;
  final String? status; // TrangThaiLamBai
  final JLPTResult? lastResult; // KetQuaGannhat

  JLPTExamBrief({
    required this.id,
    required this.title,
    this.description,
    required this.level,
    this.year,
    this.month,
    required this.timeLimit,
    required this.passScore,
    required this.totalScore,
    required this.totalQuestions,
    required this.totalViews,
    required this.createdAt,
    this.status,
    this.lastResult,
  });

  factory JLPTExamBrief.fromJson(Map<String, dynamic> json) {
    return JLPTExamBrief(
      id: json['id'] ?? json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      level: json['level'] ?? '',
      year: json['year'],
      month: json['month'],
      timeLimit: json['time_limit'] ?? 0,
      passScore: json['pass_score'] ?? 0,
      totalScore: json['total_score'] ?? 0,
      totalQuestions: json['total_questions'] ?? 0,
      totalViews: json['total_views'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      status: json['TrangThaiLamBai'],
      lastResult: json['KetQuaGannhat'] != null
          ? JLPTResult.fromJson(json['KetQuaGannhat'])
          : null,
    );
  }
}

class JLPTResult {
  final int score;
  final bool isPassed;
  final DateTime? completedAt;

  JLPTResult({required this.score, required this.isPassed, this.completedAt});

  factory JLPTResult.fromJson(Map<String, dynamic> json) {
    return JLPTResult(
      score: json['score'] ?? 0,
      isPassed: json['is_passed'] ?? false,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
    );
  }
}

class JLPTQuestion {
  final int mondai;
  final String questionText;
  final String? image;
  final String? audio;
  final List<String> choices;
  final int? correctAnswer;
  final String? explanation;

  JLPTQuestion({
    required this.mondai,
    required this.questionText,
    this.image,
    this.audio,
    required this.choices,
    this.correctAnswer,
    this.explanation,
  });

  factory JLPTQuestion.fromJson(Map<String, dynamic> json) {
    String? normalize(String? raw) {
      if (raw == null || raw.isEmpty) return null;
      if (raw.startsWith('http')) return raw;
      final host = ApiClient.baseUrl.replaceFirst('/api', '');
      return raw.startsWith('/') ? '$host$raw' : '$host/$raw';
    }

    return JLPTQuestion(
      mondai: json['mondai'] ?? 0,
      questionText: json['question_text'] ?? '',
      image: normalize(json['image'] as String?),
      audio: normalize(json['audio'] as String?),
      choices: (json['choices'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      correctAnswer: json['correct_answer'],
      explanation: json['explanation'],
    );
  }
}

class JLPTGroupQuestion {
  final int mondai;
  final String? groupContent;
  final String? groupImage;
  final String? groupAudio;
  final String? transcript;
  final List<JLPTQuestion> questions;

  JLPTGroupQuestion({
    required this.mondai,
    this.groupContent,
    this.groupImage,
    this.groupAudio,
    this.transcript,
    required this.questions,
  });

  factory JLPTGroupQuestion.fromJson(Map<String, dynamic> json) {
    String? normalize(String? raw) {
      if (raw == null || raw.isEmpty) return null;
      if (raw.startsWith('http')) return raw;
      final host = ApiClient.baseUrl.replaceFirst('/api', '');
      return raw.startsWith('/') ? '$host$raw' : '$host/$raw';
    }

    return JLPTGroupQuestion(
      mondai: json['mondai'] ?? 0,
      groupContent: json['group_content'],
      groupImage: normalize(json['group_image'] as String?),
      groupAudio: normalize(json['group_audio'] as String?),
      transcript: json['transcript'],
      questions: (json['questions'] as List<dynamic>? ?? [])
          .map((e) => JLPTQuestion.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class JLPTExamDetail {
  final String id;
  final String title;
  final String level;
  final int timeLimit;
  final int passScore;
  final int totalScore;
  final List<JLPTQuestion> mojiGoi;
  final List<JLPTQuestion> bunpou;
  final List<JLPTGroupQuestion> dokkai;
  final List<JLPTGroupQuestion> choukai;

  JLPTExamDetail({
    required this.id,
    required this.title,
    required this.level,
    required this.timeLimit,
    required this.passScore,
    required this.totalScore,
    required this.mojiGoi,
    required this.bunpou,
    required this.dokkai,
    required this.choukai,
  });

  factory JLPTExamDetail.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json; // endpoint wraps in data
    final sections = data['sections'] ?? {};
    return JLPTExamDetail(
      id: data['id'] ?? data['_id'] ?? '',
      title: data['title'] ?? '',
      level: data['level'] ?? '',
      timeLimit: data['time_limit'] ?? 0,
      passScore: data['pass_score'] ?? 0,
      totalScore: data['total_score'] ?? 0,
      mojiGoi: (sections['moji_goi'] as List<dynamic>? ?? [])
          .map((e) => JLPTQuestion.fromJson(e as Map<String, dynamic>))
          .toList(),
      bunpou: (sections['bunpou'] as List<dynamic>? ?? [])
          .map((e) => JLPTQuestion.fromJson(e as Map<String, dynamic>))
          .toList(),
      dokkai: (sections['dokkai'] as List<dynamic>? ?? [])
          .map((e) => JLPTGroupQuestion.fromJson(e as Map<String, dynamic>))
          .toList(),
      choukai: (sections['choukai'] as List<dynamic>? ?? [])
          .map((e) => JLPTGroupQuestion.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class JLPTSubmitResult {
  final int totalScore;
  final int vocabScore;
  final int grammarScore;
  final int readingScore;
  final int listeningScore;
  final bool passed;
  final int duration;

  JLPTSubmitResult({
    required this.totalScore,
    required this.vocabScore,
    required this.grammarScore,
    required this.readingScore,
    required this.listeningScore,
    required this.passed,
    required this.duration,
  });

  factory JLPTSubmitResult.fromJson(Map<String, dynamic> json) {
    final data = json['ketQua'] ?? json;
    return JLPTSubmitResult(
      totalScore: data['TongDiemDatDuoc'] ?? 0,
      vocabScore: data['DiemTuVung'] ?? 0,
      grammarScore: data['DiemNguPhap'] ?? 0,
      readingScore: data['DiemDocHieu'] ?? 0,
      listeningScore: data['DiemNgheHieu'] ?? 0,
      passed: (data['KetQuaCuoiCung'] ?? '').toString().contains('Đỗ'),
      duration: data['TongThoiGian'] ?? 0,
    );
  }
}
