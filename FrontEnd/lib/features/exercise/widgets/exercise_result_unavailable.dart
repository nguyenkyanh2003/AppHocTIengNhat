import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../shared/widgets/content_pane.dart';

/// Trạng thái khi không lấy được kết quả — thay cho một dòng chữ cụt.
class ExerciseResultUnavailable extends StatelessWidget {
  const ExerciseResultUnavailable({super.key, required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ContentPane(
        maxWidth: AppContentWidth.form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.assignment_late_outlined,
              size: 64,
              color: context.colors.textSecondary,
            ),
            AppGap.lg,
            Text(
              'Không mở được kết quả này',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            AppGap.sm,
            const Text(
              'Kết quả có thể đã bị xoá, hoặc không thuộc về tài khoản này.',
              textAlign: TextAlign.center,
            ),
            AppGap.xl,
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.sm,
              alignment: WrapAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Thử lại'),
                ),
                FilledButton.icon(
                  onPressed: () => context.go('/exercise-history'),
                  icon: const Icon(Icons.history),
                  label: const Text('Lịch sử làm bài'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
