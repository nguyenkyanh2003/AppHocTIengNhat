import '../../achievements/models/achievement.dart';

/// Một huy hiệu ở màn quản trị, kèm số người đã mở do server đếm.
class AdminAchievement {
  const AdminAchievement({required this.definition, required this.unlocked});

  final Achievement definition;
  final int unlocked;

  factory AdminAchievement.fromJson(Map<String, dynamic> json) {
    return AdminAchievement(
      definition: Achievement.fromJson(json),
      unlocked: (json['unlocked'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Nội dung form thêm/sửa huy hiệu.
///
/// Tiếng Anh là tuỳ chọn: bỏ trống thì lấy theo tiếng Việt. Tiêu chí suy ra từ nhóm
/// để không tạo được huy hiệu Kanji mà lại đếm XP.
class AchievementDraft {
  const AchievementDraft({
    required this.nameVi,
    required this.name,
    required this.descriptionVi,
    required this.description,
    required this.icon,
    required this.category,
    required this.requirementValue,
    required this.xpReward,
    required this.rarity,
    required this.isActive,
  });

  final String nameVi;
  final String name;
  final String descriptionVi;
  final String description;
  final String icon;
  final String category;
  final int requirementValue;
  final int xpReward;
  final String rarity;
  final bool isActive;

  String get _requirementType => switch (category) {
        'streak' => 'streak',
        'xp' => 'xp',
        _ => 'count',
      };

  Map<String, dynamic> toJson() {
    final vietnameseName = nameVi.trim();
    final vietnameseDescription = descriptionVi.trim();
    return {
      'name': name.trim().isEmpty ? vietnameseName : name.trim(),
      'name_vi': vietnameseName,
      'description': description.trim().isEmpty
          ? vietnameseDescription
          : description.trim(),
      'description_vi': vietnameseDescription,
      'icon': icon.trim(),
      'category': category,
      'requirement_type': _requirementType,
      'requirement_value': requirementValue,
      'xp_reward': xpReward,
      'rarity': rarity,
      'is_active': isActive,
    };
  }
}
