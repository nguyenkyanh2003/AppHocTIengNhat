import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../shared/widgets/chunky_card.dart';
import '../models/vocabulary_set.dart';

/// Thẻ một bộ từ vựng: biểu tượng chủ đề, tên bộ và tiến độ đã học.
class VocabularySetCard extends StatelessWidget {
  const VocabularySetCard({super.key, required this.set, this.onTap});

  final VocabularySet set;
  final VoidCallback? onTap;

  /// Biểu tượng theo nhóm trong mã bộ (`N5.food.1` → `food`,
  /// `N3.1.v.2` → `v`). Nhóm lạ dùng biểu tượng chung.
  static const Map<String, IconData> _icons = {
    'greet': Icons.waving_hand_outlined,
    'people': Icons.people_outline,
    'body': Icons.favorite_outline,
    'food': Icons.restaurant_outlined,
    'home': Icons.home_outlined,
    'clothes': Icons.checkroom_outlined,
    'school': Icons.school_outlined,
    'work': Icons.work_outline,
    'shop': Icons.shopping_bag_outlined,
    'travel': Icons.directions_transit_outlined,
    'time': Icons.schedule_outlined,
    'number': Icons.pin_outlined,
    'nature': Icons.wb_sunny_outlined,
    'hobby': Icons.sports_esports_outlined,
    'comm': Icons.mail_outline,
    'country': Icons.public_outlined,
    'society': Icons.gavel_outlined,
    'action': Icons.directions_run_outlined,
    'quality': Icons.tune_outlined,
    'feeling': Icons.sentiment_satisfied_outlined,
    'function': Icons.link_outlined,
    'n': Icons.label_outline,
    'v': Icons.bolt_outlined,
    'adj': Icons.palette_outlined,
    'adv': Icons.speed_outlined,
    'other': Icons.link_outlined,
  };

  IconData get _icon {
    final segments = set.id.split('.');
    // Mã ở N3–N1 có thêm độ khó: `N3.1.v.2` → nhóm là đoạn áp chót.
    final group = segments.length > 3 ? segments[2] : segments[1];
    return _icons[group] ?? Icons.menu_book_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final levelColor = AppColors.jlptLevels[set.level] ?? AppColors.vocabulary;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ChunkyCard(
        onTap: onTap,
        padding: AppSpacing.page,
        child: Row(
          children: [
            CircleAvatar(
              radius: AppSpacing.xl,
              backgroundColor: levelColor.withValues(alpha: 0.15),
              foregroundColor: levelColor,
              child: Icon(set.isCompleted ? Icons.check_rounded : _icon),
            ),
            AppGap.lg,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    set.displayTitle,
                    style: textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  AppGap.xs,
                  Text(
                    '${set.learnedCount}/${set.wordCount} từ đã học',
                    style: textTheme.bodySmall,
                  ),
                  AppGap.sm,
                  ClipRRect(
                    borderRadius: AppRadius.pillAll,
                    child: LinearProgressIndicator(
                      value: set.progress,
                      minHeight: AppSpacing.sm,
                      color: set.isCompleted
                          ? AppColors.success
                          : AppColors.accent,
                      backgroundColor: AppColors.surfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            AppGap.sm,
            const Icon(Icons.chevron_right, color: AppColors.textDisabled),
          ],
        ),
      ),
    );
  }
}
