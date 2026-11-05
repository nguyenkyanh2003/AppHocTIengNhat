import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/app_tokens.dart';
import '../models/kanji.dart';
import '../../../shared/widgets/level_badge.dart';

/// Một chữ Kanji trong danh sách.
class KanjiListCard extends StatelessWidget {
  const KanjiListCard({
    super.key,
    required this.kanji,
  });

  final Kanji kanji;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () {
            context.push('/kanji/${kanji.id}');
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Kanji character với gradient background
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.kanjiCoral, AppColors.kanjiCoralEnd],
                    ),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.kanjiCoral.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      kanji.character,
                      style: const TextStyle(
                        fontSize: AppTypography.display,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Thông tin
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (kanji.hanviet != null)
                        Text(
                          kanji.hanviet!,
                          style: TextStyle(
                            fontSize: AppTypography.subtitle,
                            fontWeight: FontWeight.bold,
                            color: context.colors.textPrimary,
                          ),
                        ),
                      const SizedBox(height: 4),
                      if (kanji.meaning != null)
                        Text(
                          kanji.meaning!,
                          style: TextStyle(
                            fontSize: AppTypography.bodySmall,
                            color: context.colors.textSecondary,
                          ),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (kanji.onyomi.isNotEmpty)
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Âm Hán: ${kanji.onyomi.join(", ")}',
                                  style: TextStyle(
                                    fontSize: AppTypography.caption,
                                    color: context.colors.primary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          if (kanji.onyomi.isNotEmpty &&
                              kanji.kunyomi.isNotEmpty)
                            const SizedBox(width: 8),
                          if (kanji.kunyomi.isNotEmpty)
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.success.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Âm Kun: ${kanji.kunyomi.join(", ")}',
                                  style: TextStyle(
                                    fontSize: AppTypography.caption,
                                    color: context.colors
                                        .readable(AppColors.success),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Level badge
                if (kanji.level != null) LevelBadge(kanji.level!),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
