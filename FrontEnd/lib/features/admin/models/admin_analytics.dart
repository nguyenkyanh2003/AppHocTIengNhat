/// Số liệu hoạt động toàn hệ thống trong một kỳ (7, 30 hoặc 90 ngày).
///
/// Các chuỗi theo ngày dài bằng [labels]; thiếu thì là danh sách rỗng chứ không
/// phải số mẫu.
class AdminAnalytics {
  const AdminAnalytics({
    required this.labels,
    required this.totalUsers,
    required this.activeToday,
    required this.lessonsCompleted,
    required this.studyMinutes,
    required this.dailyActiveUsers,
    required this.newRegistrations,
    required this.dailyLessonsCompleted,
    required this.dailyStudyMinutes,
    required this.levelDistribution,
  });

  factory AdminAnalytics.fromJson(Map<String, dynamic> json) {
    final metrics = json['metrics'] is Map ? json['metrics'] as Map : const {};
    final levels = json['level_distribution'] is Map ? json['level_distribution'] as Map : const {};
    return AdminAnalytics(
      labels: [for (final label in _list(json['labels'])) '$label'],
      totalUsers: _int(metrics['total_users']),
      activeToday: _int(metrics['active_today']),
      lessonsCompleted: _int(metrics['lessons_completed']),
      studyMinutes: _int(metrics['study_minutes']),
      dailyActiveUsers: _series(json['daily_active_users']),
      newRegistrations: _series(json['new_registrations']),
      dailyLessonsCompleted: _series(json['lessons_completed']),
      dailyStudyMinutes: _series(json['total_study_time']),
      levelDistribution: {for (final MapEntry(:key, :value) in levels.entries) '$key': _int(value)},
    );
  }

  final List<String> labels;
  final int totalUsers;
  final int activeToday;
  final int lessonsCompleted;
  final int studyMinutes;
  final List<num> dailyActiveUsers;
  final List<num> newRegistrations;
  final List<num> dailyLessonsCompleted;
  final List<num> dailyStudyMinutes;

  /// Số người theo trình độ (`N5`, `N4`…, `Chưa đặt`).
  final Map<String, int> levelDistribution;

  static List<Object?> _list(Object? value) => value is List ? value : const [];

  static int _int(Object? value) => value is num ? value.toInt() : 0;

  static List<num> _series(Object? value) => [for (final item in _list(value)) item is num ? item : 0];
}
