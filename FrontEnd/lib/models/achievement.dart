class Achievement {
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

  Achievement({
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

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      nameVi: json['name_vi'] ?? '',
      description: json['description'] ?? '',
      descriptionVi: json['description_vi'] ?? '',
      icon: json['icon'] ?? '🏆',
      category: json['category'] ?? 'practice',
      requirementType: json['requirement_type'] ?? 'count',
      requirementValue: json['requirement_value'] ?? 0,
      xpReward: json['xp_reward'] ?? 100,
      rarity: json['rarity'] ?? 'common',
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'name_vi': nameVi,
      'description': description,
      'description_vi': descriptionVi,
      'icon': icon,
      'category': category,
      'requirement_type': requirementType,
      'requirement_value': requirementValue,
      'xp_reward': xpReward,
      'rarity': rarity,
      'is_active': isActive,
    };
  }

  String get rarityColor {
    switch (rarity) {
      case 'legendary':
        return '#FFD700'; // Gold
      case 'epic':
        return '#9C27B0'; // Purple
      case 'rare':
        return '#2196F3'; // Blue
      default:
        return '#757575'; // Gray
    }
  }

  String get categoryIcon {
    switch (category) {
      case 'vocabulary':
        return '📚';
      case 'grammar':
        return '📝';
      case 'kanji':
        return '🈯';
      case 'lesson':
        return '📖';
      case 'streak':
        return '🔥';
      case 'xp':
        return '⭐';
      case 'practice':
        return '🎯';
      default:
        return '🏆';
    }
  }
}

class UserAchievement {
  final String id;
  final String userId;
  final Achievement achievement;
  final DateTime earnedAt;
  final int progress;
  final bool isCompleted;
  final bool isLocked;

  UserAchievement({
    required this.id,
    required this.userId,
    required this.achievement,
    required this.earnedAt,
    required this.progress,
    required this.isCompleted,
    this.isLocked = false,
  });

  factory UserAchievement.fromJson(Map<String, dynamic> json) {
    return UserAchievement(
      id: json['_id'] ?? '',
      userId: json['user'] ?? '',
      achievement: Achievement.fromJson(json['achievement']),
      earnedAt: DateTime.parse(json['earned_at'] ?? DateTime.now().toIso8601String()),
      progress: json['progress'] ?? 0,
      isCompleted: json['is_completed'] ?? false,
      isLocked: json['is_locked'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'user': userId,
      'achievement': achievement.toJson(),
      'earned_at': earnedAt.toIso8601String(),
      'progress': progress,
      'is_completed': isCompleted,
      'is_locked': isLocked,
    };
  }

  double get progressPercentage {
    if (achievement.requirementValue == 0) return 0.0;
    return (progress / achievement.requirementValue).clamp(0.0, 1.0);
  }
}
