import '../../lessons/models/lesson.dart';

/// Một dòng tiến độ học bài, rút gọn từ `/lesson-progress/lessons` — chỉ những
/// gì Trang chủ cần để biết người học đang ở đâu.
class LessonProgressSummary {
  const LessonProgressSummary({
    required this.lessonId,
    required this.isCompleted,
    required this.lastStudiedAt,
  });

  /// `null` khi bài gắn với tiến độ đã bị xoá (API trả `lesson: null`).
  static LessonProgressSummary? tryParse(Map<String, dynamic> json) {
    final lesson = json['lesson'];
    final lessonId =
        lesson is Map ? lesson['_id']?.toString() : lesson?.toString();
    if (lessonId == null || lessonId.isEmpty) return null;
    return LessonProgressSummary(
      lessonId: lessonId,
      isCompleted: json['is_completed'] == true,
      lastStudiedAt:
          DateTime.tryParse(json['last_studied_at']?.toString() ?? '') ??
              DateTime(1970),
    );
  }

  final String lessonId;
  final bool isCompleted;
  final DateTime lastStudiedAt;
}

/// Thẻ "Bài học tiếp theo" của Trang chủ.
class NextLesson {
  const NextLesson({
    required this.level,
    required this.lesson,
    required this.inProgress,
    required this.completedInLevel,
    required this.totalInLevel,
  });

  final String level;

  /// Bài nên học tiếp; `null` khi đã học xong mọi bài của [level].
  final Lesson? lesson;

  /// Bài đang học dở (có tiến độ nhưng chưa hoàn thành).
  final bool inProgress;

  final int completedInLevel;
  final int totalInLevel;

  bool get levelFinished => lesson == null;

  double get levelProgress =>
      totalInLevel == 0 ? 0 : completedInLevel / totalInLevel;
}

/// Chọn bài học tiếp theo trong một trình độ.
///
/// 1. Bài học gần nhất chưa xong → học tiếp chính bài đó.
/// 2. Bài gần nhất đã xong → bài chưa xong đầu tiên đứng sau nó.
/// 3. Chưa học bài nào / không còn bài phía sau → bài chưa xong đầu tiên.
///
/// `null` khi trình độ không có bài nào. [progress] có thể chứa bài của trình
/// độ khác; chỉ tiến độ của bài trong [lessons] được tính.
NextLesson? pickNextLesson({
  required String level,
  required List<Lesson> lessons,
  required List<LessonProgressSummary> progress,
}) {
  if (lessons.isEmpty) return null;
  final ordered = [...lessons]..sort((a, b) => a.order.compareTo(b.order));
  final ids = {for (final lesson in ordered) lesson.id};
  final inLevel = progress.where((p) => ids.contains(p.lessonId)).toList()
    ..sort((a, b) => b.lastStudiedAt.compareTo(a.lastStudiedAt));
  final completedIds = {
    for (final p in inLevel)
      if (p.isCompleted) p.lessonId
  };

  Lesson? next;
  var inProgress = false;
  final recent = inLevel.isEmpty ? null : inLevel.first;
  if (recent != null && !recent.isCompleted) {
    next = ordered.firstWhere((lesson) => lesson.id == recent.lessonId);
    inProgress = true;
  } else {
    bool open(Lesson lesson) => !completedIds.contains(lesson.id);
    final recentOrder = recent == null
        ? null
        : ordered.firstWhere((l) => l.id == recent.lessonId).order;
    next = ordered
            .where((l) => recentOrder == null || l.order > recentOrder)
            .where(open)
            .firstOrNull ??
        ordered.where(open).firstOrNull;
  }

  return NextLesson(
    level: level,
    lesson: next,
    inProgress: inProgress,
    completedInLevel: completedIds.length,
    totalInLevel: ordered.length,
  );
}
