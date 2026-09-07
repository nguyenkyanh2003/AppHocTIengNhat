import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/app_tokens.dart';
import '../../app/theme/app_typography.dart';

/// Nhãn cấp độ JLPT (N5..N1) với màu thống nhất toàn app.
class LevelBadge extends StatelessWidget {
  const LevelBadge(this.level, {super.key, this.compact = false});

  final String level;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.getJlptLevelColor(level);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.sm : AppSpacing.md,
        vertical: compact ? 2 : AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: AppRadius.pillAll,
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        level.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: compact ? 11 : AppTypography.caption,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
