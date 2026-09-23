import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';

/// Một khối nội dung của màn bài học: tiêu đề có biểu tượng, rồi nội dung.
class LessonSection extends StatelessWidget {
  const LessonSection({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.caption,
  });

  final IconData icon;
  final String title;
  final String? caption;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.lesson),
              AppGap.sm,
              Expanded(
                child: Text(title, style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          if (caption != null) ...[
            AppGap.xs,
            Text(caption!, style: textTheme.bodySmall),
          ],
          AppGap.lg,
          child,
        ],
      ),
    );
  }
}
