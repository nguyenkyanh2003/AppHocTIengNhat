/// Cài đặt mục tiêu ngày và nhắc học (`GET/PUT /streak/settings`).
///
/// [dailyGoalXp] là mục tiêu **đang tính hôm nay**. Đổi mục tiêu chỉ có hiệu
/// lực từ ngày Việt Nam kế tiếp, nên lựa chọn mới nằm ở [nextDailyGoalXp] cho
/// tới ngày [nextGoalFrom].
class StreakSettings {
  const StreakSettings({
    this.dailyGoalXp = 20,
    this.nextDailyGoalXp,
    this.nextGoalFrom,
    this.goalOptions = const [10, 20, 30, 50],
    this.reminderEnabled = false,
    this.reminderTime = '20:00',
    this.reminderWindowStart = '08:00',
    this.reminderWindowEnd = '21:59',
    this.revision = 0,
  });

  factory StreakSettings.fromJson(Map<String, dynamic> json) {
    final window = json['reminder_window'] is Map
        ? Map<String, dynamic>.from(json['reminder_window'] as Map)
        : const <String, dynamic>{};
    final options = (json['goal_options'] as List?)
        ?.whereType<num>()
        .map((value) => value.toInt())
        .toList();

    return StreakSettings(
      dailyGoalXp: (json['daily_goal_xp'] as num?)?.toInt() ?? 20,
      nextDailyGoalXp: (json['next_daily_goal_xp'] as num?)?.toInt(),
      nextGoalFrom: json['next_goal_from'] as String?,
      goalOptions: options == null || options.isEmpty ? const [10, 20, 30, 50] : options,
      reminderEnabled: json['reminder_enabled'] as bool? ?? false,
      reminderTime: json['reminder_time'] as String? ?? '20:00',
      reminderWindowStart: window['start'] as String? ?? '08:00',
      reminderWindowEnd: window['end'] as String? ?? '21:59',
      revision: (json['revision'] as num?)?.toInt() ?? 0,
    );
  }

  final int dailyGoalXp;
  final int? nextDailyGoalXp;
  final String? nextGoalFrom;
  final List<int> goalOptions;
  final bool reminderEnabled;

  /// `HH:MM`, giờ Việt Nam.
  final String reminderTime;
  final String reminderWindowStart;
  final String reminderWindowEnd;
  final int revision;

  /// Mức người dùng chọn gần nhất — thứ màn cài đặt đánh dấu là đang chọn.
  int get chosenGoalXp => nextDailyGoalXp ?? dailyGoalXp;

  /// Các giờ chọn được: mỗi 30 phút trong khung cho phép, cộng giờ đang đặt
  /// nếu nó lệch mốc (đặt từ thiết bị khác). Chọn từ danh sách thì không thể
  /// gửi lên một giờ ngoài khung.
  List<String> get reminderTimeOptions {
    final start = _minutes(reminderWindowStart);
    final end = _minutes(reminderWindowEnd);
    final options = <String>{
      for (var minute = start; minute <= end; minute += 30) _format(minute),
      if (_minutes(reminderTime) >= start && _minutes(reminderTime) <= end) reminderTime,
    }.toList()
      ..sort();
    return options;
  }

  static int _minutes(String time) {
    final parts = time.split(':');
    if (parts.length != 2) return -1;
    return (int.tryParse(parts[0]) ?? -1) * 60 + (int.tryParse(parts[1]) ?? 0);
  }

  static String _format(int minutes) =>
      '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';
}
