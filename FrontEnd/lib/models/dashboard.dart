class DashboardStats {
  final int vocabularyLearned;
  final int kanjiLearned;
  final int exercisesCompleted;
  final int lessonsCompleted;
  final int totalStudyTime; // in seconds
  final int currentStreak;
  final int totalXP;
  final int level;

  DashboardStats({
    required this.vocabularyLearned,
    required this.kanjiLearned,
    required this.exercisesCompleted,
    required this.lessonsCompleted,
    required this.totalStudyTime,
    required this.currentStreak,
    required this.totalXP,
    required this.level,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      vocabularyLearned: json['vocabulary_learned'] ?? 0,
      kanjiLearned: json['kanji_learned'] ?? 0,
      exercisesCompleted: json['exercises_completed'] ?? 0,
      lessonsCompleted: json['lessons_completed'] ?? 0,
      totalStudyTime: json['total_study_time'] ?? 0,
      currentStreak: json['current_streak'] ?? 0,
      totalXP: json['total_xp'] ?? 0,
      level: json['level'] ?? 1,
    );
  }

  // Format study time to hours and minutes
  String get formattedStudyTime {
    final hours = totalStudyTime ~/ 3600;
    final minutes = (totalStudyTime % 3600) ~/ 60;
    if (hours > 0) {
      return '$hours giờ $minutes phút';
    }
    return '$minutes phút';
  }
}

class TimelineData {
  final String date;
  final int exercises;
  final int lessons;
  final int time; // in seconds
  final int xp;

  TimelineData({
    required this.date,
    required this.exercises,
    required this.lessons,
    required this.time,
    required this.xp,
  });

  factory TimelineData.fromJson(Map<String, dynamic> json) {
    return TimelineData(
      date: json['date'] ?? '',
      exercises: json['exercises'] ?? 0,
      lessons: json['lessons'] ?? 0,
      time: json['time'] ?? 0,
      xp: json['xp'] ?? 0,
    );
  }

  DateTime get dateTime => DateTime.parse(date);
}

class HeatmapData {
  final String date;
  final int count;
  final int time; // in seconds

  HeatmapData({
    required this.date,
    required this.count,
    required this.time,
  });

  factory HeatmapData.fromJson(Map<String, dynamic> json) {
    return HeatmapData(
      date: json['date'] ?? '',
      count: json['count'] ?? 0,
      time: json['time'] ?? 0,
    );
  }

  DateTime get dateTime => DateTime.parse(date);

  // Get intensity level for heatmap color (0-4)
  int get intensity {
    if (count == 0) return 0;
    if (count <= 2) return 1;
    if (count <= 5) return 2;
    if (count <= 10) return 3;
    return 4;
  }
}

class LessonBreakdown {
  final String level;
  final int completed;
  final int inProgress;

  LessonBreakdown({
    required this.level,
    required this.completed,
    required this.inProgress,
  });

  factory LessonBreakdown.fromJson(Map<String, dynamic> json) {
    return LessonBreakdown(
      level: json['_id'] ?? '',
      completed: json['completed'] ?? 0,
      inProgress: json['in_progress'] ?? 0,
    );
  }

  int get total => completed + inProgress;
  double get completionRate => total > 0 ? (completed / total) * 100 : 0;
}

class ExerciseBreakdown {
  final String type;
  final int count;
  final double averageScore;
  final int passed;

  ExerciseBreakdown({
    required this.type,
    required this.count,
    required this.averageScore,
    required this.passed,
  });

  factory ExerciseBreakdown.fromJson(Map<String, dynamic> json) {
    return ExerciseBreakdown(
      type: json['_id'] ?? '',
      count: json['count'] ?? 0,
      averageScore: (json['average_score'] ?? 0).toDouble(),
      passed: json['passed'] ?? 0,
    );
  }

  double get passRate => count > 0 ? (passed / count) * 100 : 0;
}

class DashboardBreakdown {
  final List<LessonBreakdown> lessonsByLevel;
  final List<ExerciseBreakdown> exercisesByType;

  DashboardBreakdown({
    required this.lessonsByLevel,
    required this.exercisesByType,
  });

  factory DashboardBreakdown.fromJson(Map<String, dynamic> json) {
    return DashboardBreakdown(
      lessonsByLevel: (json['lessons_by_level'] as List?)
              ?.map((item) => LessonBreakdown.fromJson(item))
              .toList() ??
          [],
      exercisesByType: (json['exercises_by_type'] as List?)
              ?.map((item) => ExerciseBreakdown.fromJson(item))
              .toList() ??
          [],
    );
  }
}
