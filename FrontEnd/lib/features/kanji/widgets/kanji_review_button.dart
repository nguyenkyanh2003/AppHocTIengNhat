import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../../srs/models/srs_progress.dart';

/// Nút đưa chữ vào lịch ôn. Đã có thẻ thì hiện "Đã thêm" kèm lần ôn tới, và
/// bấm lại để gỡ.
class KanjiReviewButton extends StatelessWidget {
  const KanjiReviewButton({
    super.key,
    required this.progress,
    required this.saving,
    required this.onPressed,
  });

  /// Thẻ ôn của người đang xem; `null` khi chữ chưa có trong lịch ôn.
  final SrsProgress? progress;
  final bool saving;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final current = progress;
    final icon = saving
        ? const SizedBox.square(dimension: AppSpacing.lg, child: CircularProgressIndicator(strokeWidth: 2))
        : Icon(current == null ? Icons.add_task : Icons.check_circle);

    if (current == null) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: saving ? null : onPressed,
          icon: icon,
          label: const Text('Thêm vào ôn tập'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: saving ? null : onPressed,
          icon: icon,
          label: const Text('Đã thêm vào ôn tập'),
        ),
        AppGap.xs,
        Text(
          'Hộp ${current.box}/${SrsProgress.maxBox} · lần ôn tới ${_formatDate(current.nextReview)}',
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  static String _formatDate(DateTime value) {
    final local = value.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year} ${two(local.hour)}:${two(local.minute)}';
  }
}
