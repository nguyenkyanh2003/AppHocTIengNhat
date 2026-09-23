import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../core/state/view_state.dart';
import '../models/srs_card.dart';
import '../models/srs_progress.dart';
import '../models/srs_tally.dart';

/// Kết thúc phiên ôn: số liệu của phiên, phân bố hộp và số thẻ còn đến hạn.
///
/// Phiên có thể dừng khi vẫn còn thẻ đến hạn (người học đã bỏ qua chúng),
/// nên số còn lại được nói rõ kèm nút mở phiên mới — phiên mới gặp lại thẻ đã
/// bỏ qua.
class SrsSessionSummary extends StatelessWidget {
  const SrsSessionSummary({
    super.key,
    required this.tally,
    required this.stats,
    required this.onRestart,
    required this.onDone,
  });

  final SrsTally tally;
  final ViewState<SrsStats> stats;
  final VoidCallback onRestart;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final remaining = stats.valueOrNull?.dueCount ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          tally.isEmpty ? Icons.event_available : Icons.celebration_outlined,
          size: 56,
          color: AppColors.success,
        ),
        AppGap.md,
        Text(
          tally.isEmpty ? 'Không có thẻ nào đến hạn' : 'Xong phiên ôn tập',
          style: textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        if (tally.isEmpty) ...[
          AppGap.sm,
          Text(
            'Đánh dấu "Đã học" ở một từ vựng để đưa từ đó vào lịch ôn.',
            style: textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ] else ...[
          AppGap.lg,
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _Count(label: 'Nhớ', value: tally.remembered, color: AppColors.success),
              _Count(label: 'Chưa nhớ', value: tally.forgotten, color: AppColors.error),
              _Count(label: 'Bỏ qua', value: tally.skipped, color: AppColors.textSecondary),
              if (tally.reset > 0) _Count(label: 'Đặt lại', value: tally.reset, color: AppColors.info),
              if (tally.removed > 0) _Count(label: 'Đã xoá', value: tally.removed, color: AppColors.warning),
            ],
          ),
        ],
        if (stats.valueOrNull case final value?) ...[
          AppGap.xl,
          Text('Thẻ theo hộp', style: textTheme.titleSmall),
          AppGap.sm,
          for (var box = 1; box <= SrsProgress.maxBox; box++)
            _BoxRow(box: box, count: value.byBox[box] ?? 0, total: value.totalCards),
        ],
        AppGap.xl,
        if (remaining > 0) ...[
          Text(
            'Còn $remaining thẻ đến hạn bạn đã bỏ qua.',
            style: textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          AppGap.sm,
          FilledButton.icon(
            onPressed: onRestart,
            icon: const Icon(Icons.replay),
            label: const Text('Mở phiên mới'),
          ),
          AppGap.sm,
        ],
        OutlinedButton(onPressed: onDone, child: const Text('Về trang ôn tập')),
      ],
    );
  }
}

class _Count extends StatelessWidget {
  const _Count({required this.label, required this.value, required this.color});

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: CircleAvatar(
        backgroundColor: color,
        child: Text(
          '$value',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white),
        ),
      ),
      label: Text(label),
    );
  }
}

class _BoxRow extends StatelessWidget {
  const _BoxRow({required this.box, required this.count, required this.total});

  final int box;
  final int count;
  final int total;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          SizedBox(width: 64, child: Text('Hộp $box', style: textTheme.bodySmall)),
          Expanded(
            child: ClipRRect(
              borderRadius: AppRadius.pillAll,
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : count / total,
                minHeight: AppSpacing.sm,
                backgroundColor: AppColors.surfaceVariant,
                color: AppColors.success,
              ),
            ),
          ),
          SizedBox(width: 40, child: Text('$count', textAlign: TextAlign.end, style: textTheme.bodySmall)),
        ],
      ),
    );
  }
}
