import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/app_tokens.dart';
import '../../app/theme/app_typography.dart';

/// Nhãn cấp độ JLPT (N5..N1). Mọi màn dùng widget này để cùng một cấp độ có cùng một
/// màu, và chữ luôn đạt 4,5:1 ở cả hai chế độ.
class LevelBadge extends StatelessWidget {
  const LevelBadge(this.level, {super.key, this.compact = false});

  final String level;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = AppTheme.getJlptLevelColor(level);
    final background = color.withValues(alpha: 0.15);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.sm : AppSpacing.md,
        vertical: compact ? 2 : AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.pillAll,
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        level.toUpperCase(),
        style: TextStyle(
          color: colors.readable(
            color,
            on: Color.alphaBlend(background, colors.surface),
          ),
          fontSize: compact ? 11 : AppTypography.caption,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
