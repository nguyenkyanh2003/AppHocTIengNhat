import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../app/theme/app_typography.dart';
import '../../models/transcript_timing.dart';

/// Danh sách câu đang canh mốc: câu đã có mốc hiện mốc, câu kế tiếp được tô
/// sáng để biết lần bấm sau sẽ ghi cho câu nào.
class TimingLineList extends StatelessWidget {
  const TimingLineList({
    super.key,
    required this.lines,
    required this.starts,
  });

  final List<TimingLine> lines;
  final List<Duration> starts;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < lines.length; index++)
          Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.xs),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: index == starts.length ? AppColors.primaryLight : Colors.transparent,
              borderRadius: AppRadius.mdAll,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 72,
                  child: Text(
                    index < starts.length ? formatTimecode(starts[index]) : '—',
                    style: textTheme.labelMedium?.copyWith(
                      color: index < starts.length ? AppColors.primary : AppColors.textDisabled,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (lines[index].speaker.isNotEmpty) Text(lines[index].speaker, style: textTheme.labelSmall),
                      Text(
                        lines[index].textJa,
                        style: AppTypography.japaneseReading(color: AppColors.textPrimary)
                            .copyWith(fontSize: AppTypography.body),
                      ),
                      Text(lines[index].textVi, style: textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
