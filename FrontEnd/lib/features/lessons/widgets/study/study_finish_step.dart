import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/state/view_state.dart';
import '../../models/lesson_progress.dart';
import '../lesson_action_button.dart';

/// Kết quả phiên học — XP thật vừa nhận, số từ đã nhớ, điểm kiểm tra — và
/// hai lối đi tiếp: làm bài tập của bài, hoặc quay về trang bài học.
///
/// Chỉ ăn mừng sau khi server đã lưu xong; lưu lỗi thì nói rõ và cho thử lại,
/// không hiện "Chúc mừng" cho một bài chưa được ghi nhận.
class StudyFinishStep extends StatelessWidget {
  const StudyFinishStep({
    super.key,
    required this.completion,
    required this.xpEarned,
    required this.learnedWords,
    required this.totalWords,
    required this.quizCorrect,
    required this.quizTotal,
    required this.onRetry,
    required this.onExercises,
    required this.onDone,
  });

  final ViewState<LessonProgress> completion;

  /// XP nhận được trong phiên, `null` khi chưa đọc được số dư mới.
  final int? xpEarned;
  final int learnedWords;
  final int totalWords;
  final int quizCorrect;
  final int quizTotal;
  final VoidCallback onRetry;
  final VoidCallback onExercises;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return switch (completion) {
      ViewFailure(:final message) => Column(
          children: [
            const Icon(Icons.cloud_off, size: 56, color: AppColors.error),
            AppGap.lg,
            Text(message, style: textTheme.bodyLarge, textAlign: TextAlign.center),
            AppGap.xl,
            LessonActionButton(label: 'Lưu lại kết quả', icon: Icons.refresh, onPressed: onRetry),
          ],
        ),
      ViewData() => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.emoji_events, size: 88, color: AppColors.xp),
            AppGap.md,
            Text(
              'Hoàn thành bài học!',
              textAlign: TextAlign.center,
              style: AppTypography.heroDisplay(size: AppTypography.display, color: AppColors.textPrimary),
            ),
            AppGap.xl,
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: [
                if (xpEarned != null) _Stat(value: '+$xpEarned', label: 'XP', color: AppColors.xp),
                if (totalWords > 0) _Stat(value: '$learnedWords/$totalWords', label: 'từ đã nhớ', color: AppColors.success),
                if (quizTotal > 0) _Stat(value: '$quizCorrect/$quizTotal', label: 'câu đúng', color: AppColors.primary),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            LessonActionButton(label: 'Làm bài tập của bài này', icon: Icons.edit_note, onPressed: onExercises),
            AppGap.md,
            OutlinedButton(
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg)),
              onPressed: onDone,
              child: const Text('Về trang bài học'),
            ),
          ],
        ),
      _ => Column(
          children: [
            const CircularProgressIndicator(),
            AppGap.lg,
            Text('Đang lưu kết quả bài học…', style: textTheme.bodyMedium),
          ],
        ),
    };
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, required this.color});

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 132,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        children: [
          Text(value, style: AppTypography.heroDisplay(size: AppTypography.headline, color: AppColors.textPrimary)),
          Text(label, style: Theme.of(context).textTheme.labelLarge),
        ],
      ),
    );
  }
}
