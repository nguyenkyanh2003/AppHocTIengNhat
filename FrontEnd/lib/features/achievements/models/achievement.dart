/// Định nghĩa một huy hiệu.
class Achievement {
  const Achievement({
    required this.id,
    required this.name,
    required this.nameVi,
    required this.description,
    required this.descriptionVi,
    required this.icon,
    required this.category,
    required this.requirementType,
    required this.requirementValue,
    required this.xpReward,
    required this.rarity,
    required this.isActive,
  });

  final String id;
  final String name;
  final String nameVi;
  final String description;
  final String descriptionVi;
  final String icon;
  final String category;
  final String requirementType;
  final int requirementValue;
  final int xpReward;
  final String rarity;
  final bool isActive;

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      nameVi: json['name_vi'] as String? ?? '',
      description: json['description'] as String? ?? '',
      descriptionVi: json['description_vi'] as String? ?? '',
      icon: json['icon'] as String? ?? '🏆',
      category: json['category'] as String? ?? 'practice',
      requirementType: json['requirement_type'] as String? ?? 'count',
      requirementValue: (json['requirement_value'] as num?)?.toInt() ?? 0,
      xpReward: (json['xp_reward'] as num?)?.toInt() ?? 0,
      rarity: json['rarity'] as String? ?? 'common',
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  String get displayName => nameVi.isNotEmpty ? nameVi : name;

  String get displayDescription =>
      descriptionVi.isNotEmpty ? descriptionVi : description;
}

/// Một huy hiệu cùng tiến độ của người học.
class UserAchievement {
  const UserAchievement({
    required this.achievement,
    required this.progress,
    required this.isCompleted,
    this.earnedAt,
  });

  final Achievement achievement;
  final int progress;
  final bool isCompleted;

  /// Huy hiệu còn khoá thì chưa có ngày đạt.
  final DateTime? earnedAt;

  factory UserAchievement.fromJson(Map<String, dynamic> json) {
    return UserAchievement(
      achievement: Achievement.fromJson(
        Map<String, dynamic>.from(json['achievement'] as Map),
      ),
      progress: (json['progress'] as num?)?.toInt() ?? 0,
      isCompleted: json['is_completed'] as bool? ?? false,
      earnedAt:
          DateTime.tryParse(json['earned_at'] as String? ?? '')?.toLocal(),
    );
  }

  double get completionRatio {
    final goal = achievement.requirementValue;
    return goal <= 0 ? 0 : (progress / goal).clamp(0.0, 1.0);
  }

  /// Đã đủ tiêu chí nhưng chưa được cấp: server chỉ xét huy hiệu khi có lượt học
  /// mới, và XP của huy hiệu vừa cấp không kéo theo huy hiệu XP khác trong cùng
  /// lần ghi.
  bool get isReadyToClaim =>
      !isCompleted &&
      achievement.requirementValue > 0 &&
      progress >= achievement.requirementValue;
}

/// Toàn bộ huy hiệu của người học, đúng như server đã đếm.
class MyAchievements {
  const MyAchievements({
    required this.earned,
    required this.locked,
    required this.total,
    required this.completed,
  });

  final List<UserAchievement> earned;
  final List<UserAchievement> locked;

  /// Số huy hiệu đang bật. Huy hiệu đã ngừng vẫn ở trong [earned] nhưng không tính.
  final int total;
  final int completed;

  factory MyAchievements.fromJson(Map<String, dynamic> json) {
    List<UserAchievement> rows(String key) => [
          for (final row in json[key] as List? ?? const [])
            UserAchievement.fromJson(Map<String, dynamic>.from(row as Map)),
        ];

    final earned = rows('earned');
    final locked = rows('locked');
    return MyAchievements(
      earned: earned,
      locked: locked,
      total: (json['total'] as num?)?.toInt() ?? earned.length + locked.length,
      completed: (json['completed'] as num?)?.toInt() ?? earned.length,
    );
  }

  double get completionRate => total == 0 ? 0 : completed / total;

  bool get isEmpty => earned.isEmpty && locked.isEmpty;

  /// Huy hiệu đã đạt, mới nhất trước.
  List<UserAchievement> get recentlyEarned => [...earned]..sort((a, b) {
      final first = a.earnedAt;
      final second = b.earnedAt;
      if (first == null || second == null) {
        return first == second ? 0 : (first == null ? 1 : -1);
      }
      return second.compareTo(first);
    });

  /// Một nhóm huy hiệu ([category] null là tất cả): đã đạt trước, rồi tới huy hiệu
  /// gần đạt nhất. So theo tỉ lệ vì 50/100 gần đích hơn 50/1000.
  List<UserAchievement> inCategory(String? category) {
    bool matches(UserAchievement item) =>
        category == null || item.achievement.category == category;

    final closestFirst = locked.where(matches).toList()
      ..sort((a, b) {
        final byRatio = b.completionRatio.compareTo(a.completionRatio);
        return byRatio != 0
            ? byRatio
            : a.achievement.requirementValue
                .compareTo(b.achievement.requirementValue);
      });
    return [...recentlyEarned.where(matches), ...closestFirst];
  }
}
