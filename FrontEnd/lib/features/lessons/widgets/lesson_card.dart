import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_tokens.dart';
import '../models/lesson.dart';
import '../models/situation_labels.dart';
import '../../../shared/widgets/level_badge.dart';

/// Thẻ một bài học trong danh sách: cấp độ, chủ đề, tên, mô tả và khối lượng.
class LessonCard extends StatelessWidget {
  const LessonCard({super.key, required this.lesson});

  final Lesson lesson;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      elevation: AppElevation.low,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      child: InkWell(
        onTap: () => context.push('/lessons/${lesson.id}'),
        borderRadius: AppRadius.mdAll,
        child: Padding(
          padding: AppSpacing.page,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LevelBadge(lesson.level),
              AppGap.lg,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (lesson.situation != null) ...[
                      Row(
                        children: [
                          Icon(situationIcon(lesson.situation!),
                              size: 14, color: context.colors.primary),
                          AppGap.xs,
                          Flexible(
                            child: Text(
                              situationLabel(lesson.situation!),
                              style: textTheme.labelMedium
                                  ?.copyWith(color: context.colors.primary),
                            ),
                          ),
                        ],
                      ),
                      AppGap.xs,
                    ],
                    Text(lesson.title, style: textTheme.titleSmall),
                    if (lesson.description != null) ...[
                      AppGap.xs,
                      Text(
                        lesson.description!,
                        style: textTheme.bodyMedium
                            ?.copyWith(color: context.colors.textSecondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    AppGap.sm,
                    // `Wrap` để khi thẻ hẹp các mẩu thông tin xuống dòng thay vì
                    // tràn ngang.
                    Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.xs,
                      children: [
                        if (lesson.videos.isNotEmpty)
                          _LessonMeta(Icons.play_circle_outline,
                              '${lesson.videos.length} video'),
                        if (lesson.hasDialogue)
                          _LessonMeta(Icons.forum_outlined,
                              '${lesson.dialogue.length} lượt thoại'),
                        if (lesson.vocabularies.isNotEmpty)
                          _LessonMeta(Icons.spellcheck,
                              '${lesson.vocabularies.length} từ'),
                        if (lesson.kanjis.isNotEmpty)
                          _LessonMeta(Icons.draw_outlined,
                              '${lesson.kanjis.length} kanji'),
                        if (lesson.grammars.isNotEmpty)
                          _LessonMeta(Icons.segment,
                              '${lesson.grammars.length} ngữ pháp'),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: context.colors.textDisabled),
            ],
          ),
        ),
      ),
    );
  }
}

/// Một mẩu thông tin phụ của bài học (số lượt thoại, số từ...).
class _LessonMeta extends StatelessWidget {
  const _LessonMeta(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: context.colors.textSecondary),
        AppGap.xs,
        Flexible(
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    );
  }
}
