/// Tóm tắt streak (`GET /streak/my-streak`).
///
/// Mọi trường của Phần B đều có mặc định: server cũ không gửi chúng thì màn
/// hình vẫn dựng được, chỉ là không có gì để hiện.
class UserStreak {
  final String id;
  final String userId;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastActivityDate;
  final int totalXP;
  final int level;
  final List<DateTime> activityDates;
  final List<XPHistory> xpHistory;
  final int xpToNextLevel;

  /// Số ngày học đã xác minh theo luật mới (không gồm ngày legacy, ngày băng).
  final int totalActiveDays;

  /// Ngày học gần nhất, `YYYY-MM-DD` giờ Việt Nam.
  final String? lastActivityDay;

  /// Từ ngày này trở đi mới theo dõi chuỗi; trước đó để trống trên lịch chứ
  /// không tính là nghỉ.
  final String? trackingStartedDay;

  /// Ngày sớm nhất có trong lịch.
  final String? firstDay;
  final bool studiedToday;

  /// Kho băng **đã ghi**.
  final int freezesAvailable;
  final int maxFreezes;

  /// Những ngày băng **sẽ** che khi người học quay lại — dự kiến, chưa tiêu.
  final List<String> pendingFrozenDays;

  /// Kho còn lại sau lần tiêu dự kiến ở [pendingFrozenDays].
  final int freezesAfterPending;
  final DailyGoalProgress dailyGoal;

  UserStreak({
    required this.id,
    required this.userId,
    required this.currentStreak,
    required this.longestStreak,
    this.lastActivityDate,
    required this.totalXP,
    required this.level,
    required this.activityDates,
    required this.xpHistory,
    required this.xpToNextLevel,
    this.totalActiveDays = 0,
    this.lastActivityDay,
    this.trackingStartedDay,
    this.firstDay,
    this.studiedToday = false,
    this.freezesAvailable = 0,
    this.maxFreezes = 2,
    this.pendingFrozenDays = const [],
    this.freezesAfterPending = 0,
    this.dailyGoal = const DailyGoalProgress(),
  });

  factory UserStreak.fromJson(Map<String, dynamic> json) {
    final freezesAvailable = _int(json['freezes_available'], 0);
    return UserStreak(
      id: json['_id'] ?? '',
      userId: json['user'] ?? '',
      currentStreak: _int(json['current_streak'], 0),
      longestStreak: _int(json['longest_streak'], 0),
      lastActivityDate: json['last_activity_date'] != null
          ? DateTime.tryParse(json['last_activity_date'].toString())
          : null,
      totalXP: _int(json['total_xp'], 0),
      level: _int(json['level'], 1),
      activityDates: (json['activity_dates'] as List<dynamic>?)
              ?.map((date) => DateTime.tryParse(date.toString()))
              .whereType<DateTime>()
              .toList() ??
          [],
      xpHistory: (json['xp_history'] as List<dynamic>?)
              ?.map((item) => XPHistory.fromJson(item))
              .toList() ??
          [],
      xpToNextLevel: _int(json['xp_to_next_level'], 100),
      totalActiveDays: _int(json['total_active_days'], 0),
      lastActivityDay: json['last_activity_day'] as String?,
      trackingStartedDay: json['tracking_started_day'] as String?,
      firstDay: json['first_day'] as String?,
      studiedToday: json['studied_today'] as bool? ?? false,
      freezesAvailable: freezesAvailable,
      maxFreezes: _int(json['max_freezes'], 2),
      pendingFrozenDays: (json['pending_frozen_days'] as List<dynamic>?)
              ?.map((day) => day.toString())
              .toList() ??
          const [],
      freezesAfterPending: _int(json['freezes_after_pending'], freezesAvailable),
      dailyGoal: json['daily_goal'] is Map
          ? DailyGoalProgress.fromJson(Map<String, dynamic>.from(json['daily_goal'] as Map))
          : const DailyGoalProgress(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'user': userId,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'last_activity_date': lastActivityDate?.toIso8601String(),
      'total_xp': totalXP,
      'level': level,
      'activity_dates':
          activityDates.map((date) => date.toIso8601String()).toList(),
      'xp_history': xpHistory.map((item) => item.toJson()).toList(),
      'xp_to_next_level': xpToNextLevel,
      'total_active_days': totalActiveDays,
      'last_activity_day': lastActivityDay,
      'tracking_started_day': trackingStartedDay,
      'first_day': firstDay,
      'studied_today': studiedToday,
      'freezes_available': freezesAvailable,
      'max_freezes': maxFreezes,
      'pending_frozen_days': pendingFrozenDays,
      'freezes_after_pending': freezesAfterPending,
      'daily_goal': dailyGoal.toJson(),
    };
  }

  /// Số băng sẽ bị tiêu khi người học quay lại.
  int get pendingFreezes => pendingFrozenDays.length;

  double get xpProgress {
    final currentLevelXP = (level - 1) * 100;
    final xpInCurrentLevel = totalXP - currentLevelXP;
    return (xpInCurrentLevel / 100).clamp(0.0, 1.0);
  }
}

int _int(Object? value, int fallback) => value is num ? value.toInt() : fallback;

/// Tiến độ mục tiêu XP của hôm nay. Chỉ tính XP từ hoạt động học; không chặn
/// chuỗi ngày — chưa đạt mục tiêu mà đã học thì chuỗi vẫn giữ.
class DailyGoalProgress {
  const DailyGoalProgress({
    this.targetXp = 20,
    this.todayXp = 0,
    this.nextTargetXp,
    this.nextTargetFrom,
  });

  factory DailyGoalProgress.fromJson(Map<String, dynamic> json) => DailyGoalProgress(
        targetXp: _int(json['target_xp'], 20),
        todayXp: _int(json['today_xp'], 0),
        nextTargetXp: (json['next_target_xp'] as num?)?.toInt(),
        nextTargetFrom: json['next_target_from'] as String?,
      );

  final int targetXp;
  final int todayXp;

  /// Mục tiêu mới đã chọn, có hiệu lực từ [nextTargetFrom].
  final int? nextTargetXp;
  final String? nextTargetFrom;

  bool get reached => todayXp >= targetXp;
  int get remainingXp => reached ? 0 : targetXp - todayXp;
  double get ratio => targetXp <= 0 ? 1.0 : (todayXp / targetXp).clamp(0.0, 1.0);

  Map<String, dynamic> toJson() => {
        'target_xp': targetXp,
        'today_xp': todayXp,
        'reached': reached,
        'next_target_xp': nextTargetXp,
        'next_target_from': nextTargetFrom,
      };
}

class XPHistory {
  final int amount;
  final String reason;
  final DateTime earnedAt;

  /// `activity` (ghi qua đường mới) hoặc `legacy` (chép từ dữ liệu cũ, chưa
  /// xác minh). Chỉ có ở chế độ phân trang; đường mảng cũ không gửi trường này.
  final String? source;

  XPHistory({
    required this.amount,
    required this.reason,
    required this.earnedAt,
    this.source,
  });

  factory XPHistory.fromJson(Map<String, dynamic> json) {
    return XPHistory(
      amount: json['amount'] ?? 0,
      reason: json['reason'] ?? '',
      earnedAt: DateTime.parse(json['earned_at']),
      source: json['source'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'reason': reason,
      'earned_at': earnedAt.toIso8601String(),
      if (source != null) 'source': source,
    };
  }
}

/// Một trang lịch sử XP: `GET /streak/xp-history?mode=page`.
class XpHistoryPage {
  const XpHistoryPage({required this.items, required this.nextCursor});

  final List<XPHistory> items;

  /// `null` khi đây là trang cuối.
  final String? nextCursor;
}

/// Một ngày trong lịch học (`GET /streak/days`).
///
/// [status] là `studied`, `frozen` hoặc `legacy` — ngày cũ chưa chứng minh
/// được là có học, không được hiển thị như ngày học đã xác minh.
class StreakDay {
  const StreakDay({
    required this.dayKey,
    required this.status,
    required this.origin,
    required this.directXp,
    required this.reviewCount,
  });

  factory StreakDay.fromJson(Map<String, dynamic> json) => StreakDay(
        dayKey: json['day_key'] as String,
        status: json['status'] as String? ?? 'studied',
        origin: json['origin'] as String? ?? 'activity',
        directXp: json['direct_xp'] as int? ?? 0,
        reviewCount: json['review_count'] as int? ?? 0,
      );

  final String dayKey;
  final String status;
  final String origin;
  final int directXp;
  final int reviewCount;

  Map<String, dynamic> toJson() => {
        'day_key': dayKey,
        'status': status,
        'origin': origin,
        'direct_xp': directXp,
        'review_count': reviewCount,
      };
}

/// Một trang lịch học, kèm khoảng ngày server đã dùng.
class StreakDaysPage {
  const StreakDaysPage({
    required this.days,
    required this.nextCursor,
    required this.from,
    required this.to,
  });

  final List<StreakDay> days;
  final String? nextCursor;
  final String from;
  final String to;
}
