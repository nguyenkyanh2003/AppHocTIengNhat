class UserStreak {
  final String id;
  final String userId;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastActivityDate; // Đổi từ lastLoginDate
  final int totalXP;
  final int level;
  final List<DateTime> activityDates; // Đổi từ loginDates
  final List<XPHistory> xpHistory;
  final int xpToNextLevel;

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
  });

  factory UserStreak.fromJson(Map<String, dynamic> json) {
    return UserStreak(
      id: json['_id'] ?? '',
      userId: json['user'] ?? '',
      currentStreak: json['current_streak'] ?? 0,
      longestStreak: json['longest_streak'] ?? 0,
      lastActivityDate: json['last_activity_date'] != null
          ? DateTime.parse(json['last_activity_date'])
          : null,
      totalXP: json['total_xp'] ?? 0,
      level: json['level'] ?? 1,
      activityDates: (json['activity_dates'] as List<dynamic>?)
              ?.map((date) => DateTime.parse(date))
              .toList() ??
          [],
      xpHistory: (json['xp_history'] as List<dynamic>?)
              ?.map((item) => XPHistory.fromJson(item))
              .toList() ??
          [],
      xpToNextLevel: json['xp_to_next_level'] ?? 100,
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
    };
  }

  double get xpProgress {
    final currentLevelXP = (level - 1) * 100;
    final xpInCurrentLevel = totalXP - currentLevelXP;
    return (xpInCurrentLevel / 100).clamp(0.0, 1.0);
  }

  UserStreak copyWith({
    String? id,
    String? userId,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastActivityDate,
    int? totalXP,
    int? level,
    List<DateTime>? activityDates,
    List<XPHistory>? xpHistory,
    int? xpToNextLevel,
  }) {
    return UserStreak(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastActivityDate: lastActivityDate ?? this.lastActivityDate,
      totalXP: totalXP ?? this.totalXP,
      level: level ?? this.level,
      activityDates: activityDates ?? this.activityDates,
      xpHistory: xpHistory ?? this.xpHistory,
      xpToNextLevel: xpToNextLevel ?? this.xpToNextLevel,
    );
  }
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
