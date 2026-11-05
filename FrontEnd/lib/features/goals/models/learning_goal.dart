/// Ba loại mục tiêu tích luỹ — cùng danh sách với `type` của backend.
///
/// [studyPath] phải là nơi **thật sự** làm tăng bộ đếm: Kanji chỉ tính là đã
/// học khi bấm "Đã nhớ" ở bước Chữ Hán trong bài, nên dẫn tới Bài học chứ không
/// tới màn tra Kanji (ở đó "Thêm vào ôn tập" chỉ tạo thẻ ôn).
enum GoalType {
  lessons('lessons', 'Bài học', 'bài học', '/lessons', 'Học bài tiếp',
      'Hoàn thành một bài học để tăng tiến độ.'),
  vocabulary('vocabulary', 'Từ vựng', 'từ vựng', '/vocabulary', 'Học từ vựng',
      'Bấm "Đã học" ở màn Từ vựng hoặc "Đã nhớ" trong bài để tăng tiến độ.'),
  kanji('kanji', 'Kanji', 'chữ Kanji', '/lessons', 'Học Kanji trong bài',
      'Bấm "Đã nhớ" ở bước Chữ Hán trong bài để tăng tiến độ.');

  const GoalType(this.key, this.label, this.unit, this.studyPath, this.studyLabel, this.howTo);

  /// Giá trị `type` gửi và nhận từ API.
  final String key;
  final String label;

  /// Đơn vị đếm: "120 từ vựng", "5 bài học".
  final String unit;

  /// Màn học làm tăng tiến độ của loại này.
  final String studyPath;
  final String studyLabel;

  /// Việc cần làm để tiến độ tăng.
  final String howTo;

  static GoalType fromKey(Object? key) =>
      values.firstWhere((type) => type.key == key, orElse: () => vocabulary);
}

/// "YYYY-MM-DD" ↔ ngày theo lịch (không giờ, không múi giờ).
DateTime? parseDateKey(Object? value) {
  if (value is! String) return null;
  final parts = value.split('-').map(int.tryParse).toList();
  if (parts.length != 3 || parts.contains(null)) return null;
  return DateTime(parts[0]!, parts[1]!, parts[2]!);
}

String dateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

/// Một mục tiêu "đạt tổng cộng N …". [current] là số đã học tính đến hiện
/// tại (server đếm, kể cả trước khi tạo mục tiêu).
class LearningGoal {
  const LearningGoal({
    required this.id,
    required this.type,
    required this.title,
    required this.target,
    required this.current,
    required this.isCompleted,
    required this.createdAt,
    this.completedAt,
    this.deadline,
  });

  factory LearningGoal.fromJson(Map<String, dynamic> json) {
    final completedAt = json['completed_at'] as String?;
    return LearningGoal(
      id: json['id'] as String? ?? '',
      type: GoalType.fromKey(json['type']),
      title: json['title'] as String? ?? '',
      target: json['target'] as int? ?? 1,
      current: json['current'] as int? ?? 0,
      isCompleted: json['is_completed'] as bool? ?? false,
      completedAt: completedAt == null ? null : DateTime.parse(completedAt),
      deadline: parseDateKey(json['deadline']),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final String id;
  final GoalType type;
  final String title;
  final int target;
  final int current;
  final bool isCompleted;
  final DateTime? completedAt;

  /// Ngày hạn theo lịch; hạn là **cả** ngày đó.
  final DateTime? deadline;
  final DateTime createdAt;

  double get progress => isCompleted ? 1 : (current / target).clamp(0, 1).toDouble();

  int get remaining => current >= target ? 0 : target - current;

  /// Quá hạn theo ngày trên máy người dùng; đã hoàn thành thì không còn quá hạn.
  bool isOverdue(DateTime now) {
    final due = deadline;
    if (isCompleted || due == null) return false;
    return due.isBefore(DateTime(now.year, now.month, now.day));
  }
}

/// Số đã học hiện tại của từng loại, để form tạo hiện "bạn đang có X".
class GoalCounts {
  const GoalCounts({this.lessons = 0, this.vocabulary = 0, this.kanji = 0});

  factory GoalCounts.fromJson(Map<String, dynamic> json) => GoalCounts(
        lessons: json['lessons'] as int? ?? 0,
        vocabulary: json['vocabulary'] as int? ?? 0,
        kanji: json['kanji'] as int? ?? 0,
      );

  final int lessons;
  final int vocabulary;
  final int kanji;

  int of(GoalType type) => switch (type) {
        GoalType.lessons => lessons,
        GoalType.vocabulary => vocabulary,
        GoalType.kanji => kanji,
      };
}

/// Nội dung đang có để đạt mục tiêu: số bài, và số chữ Kanji nằm trong bài.
/// Từ vựng không có trần — học được cả ở màn Từ vựng (hơn 5.000 từ).
class GoalAvailability {
  const GoalAvailability({this.lessons, this.kanji});

  factory GoalAvailability.fromJson(Map<String, dynamic> json) =>
      GoalAvailability(lessons: json['lessons'] as int?, kanji: json['kanji'] as int?);

  final int? lessons;
  final int? kanji;

  /// `null` khi không có trần.
  int? limitOf(GoalType type) => switch (type) {
        GoalType.lessons => lessons,
        GoalType.vocabulary => null,
        GoalType.kanji => kanji,
      };
}

class GoalsSnapshot {
  const GoalsSnapshot({
    required this.goals,
    required this.counts,
    this.available = const GoalAvailability(),
  });

  final List<LearningGoal> goals;
  final GoalCounts counts;
  final GoalAvailability available;
}

/// Mục tiêu mới. [title] trống thì server tự đặt "Đạt N …".
class GoalDraft {
  const GoalDraft({required this.type, required this.target, this.title, this.deadline});

  final GoalType type;
  final int target;
  final String? title;
  final DateTime? deadline;
}

/// Thay đổi của một mục tiêu. [deadline] `null` là bỏ hạn; [target] `null` là
/// giữ nguyên (mục tiêu đã hoàn thành không đổi được số cần đạt).
class GoalEdit {
  const GoalEdit({required this.title, required this.deadline, this.target});

  final String title;
  final DateTime? deadline;
  final int? target;
}
