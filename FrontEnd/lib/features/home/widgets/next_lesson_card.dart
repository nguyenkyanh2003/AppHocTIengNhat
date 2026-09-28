import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/calm_colors.dart';
import '../../../core/state/view_state.dart';
import '../../lessons/models/lesson_study_step.dart';
import '../models/next_lesson.dart';
import 'next_lesson_illustration.dart';

/// Thẻ "Bài học tiếp theo" — điểm nhấn chính của Trang chủ.
///
/// Mọi con số đều từ tiến độ thật của người học. Chưa nạp được tiến độ (đang
/// tải, lỗi mạng, trình độ chưa có bài) thì thẻ vẫn dẫn tới danh sách bài học
/// nhưng ẩn tên bài, thời lượng và thanh tiến độ thay vì hiện số giả.
class NextLessonCard extends StatelessWidget {
  const NextLessonCard({super.key, required this.state});

  final ViewState<NextLesson?> state;

  @override
  Widget build(BuildContext context) {
    final calm = CalmColors.of(context);
    final l10n = AppLocalizations.of(context);
    final next = state.valueOrNull;
    final lesson = next?.lesson;

    final String? title;
    final String? meta;
    if (lesson != null) {
      title = lessonDisplayTitle(lesson.title);
      meta =
          '${l10n.lessonNumber} ${lesson.order} · ${estimateLessonMinutes(lesson)} ${l10n.minutesShort}';
    } else if (next != null && next.levelFinished) {
      title = '${l10n.levelFinished} ${next.level}';
      meta = null;
    } else {
      title = state.isLoading ? null : l10n.continueTitle;
      meta = null;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: calm.green, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.nextLessonEyebrow.toUpperCase(),
                      style: AppTypography.ui(
                        size: 12,
                        weight: FontWeight.w600,
                        color: calm.onGreenEyebrow,
                        letterSpacing: 12 * 0.08,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (title == null)
                      _Placeholder(width: 160, height: 24, color: calm.onGreen)
                    else
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.ui(
                            size: 22,
                            weight: FontWeight.w700,
                            color: calm.onGreen,
                            height: 1.25),
                      ),
                    if (meta != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.schedule_rounded,
                              size: 14, color: calm.onGreenMuted),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              meta,
                              style: AppTypography.ui(
                                  size: 13.5,
                                  weight: FontWeight.w500,
                                  color: calm.onGreenMuted),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const NextLessonIllustration(),
            ],
          ),
          if (next != null && next.totalInLevel > 0) ...[
            const SizedBox(height: 16),
            _LevelProgress(next: next),
          ],
          const SizedBox(height: 16),
          _ContinueButton(
            label: lesson == null && next != null && next.levelFinished
                ? l10n.browseLessons
                : l10n.continueCta,
            onPressed: () => context
                .push(lesson == null ? '/lessons' : '/lessons/${lesson.id}'),
          ),
        ],
      ),
    );
  }
}

/// "Tình huống: Hỏi đường" → "Hỏi đường": thẻ đã có nhãn "Bài học tiếp theo".
String lessonDisplayTitle(String title) =>
    title.replaceFirst(RegExp(r'^Tình huống:\s*'), '');

class _LevelProgress extends StatelessWidget {
  const _LevelProgress({required this.next});

  final NextLesson next;

  @override
  Widget build(BuildContext context) {
    final calm = CalmColors.of(context);
    final l10n = AppLocalizations.of(context);
    final label = AppTypography.ui(
        size: 13, weight: FontWeight.w500, color: calm.onGreenMuted);

    return Semantics(
      label:
          '${l10n.levelProgress} ${next.level}: ${next.completedInLevel} / ${next.totalInLevel} ${l10n.lessonsUnit}',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                    child: Text('${l10n.levelProgress} ${next.level}',
                        style: label)),
                Text(
                    '${next.completedInLevel}/${next.totalInLevel} ${l10n.lessonsUnit}',
                    style: label),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: next.levelProgress,
                minHeight: 6,
                backgroundColor: calm.onGreen.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation(calm.warm),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContinueButton extends StatelessWidget {
  const _ContinueButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final calm = CalmColors.of(context);
    return SizedBox(
      height: 48,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: calm.green,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: AppTypography.ui(size: 16, weight: FontWeight.w700),
        ),
        child: Text('$label →'),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder(
      {required this.width, required this.height, required this.color});

  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(6)),
      );
}
