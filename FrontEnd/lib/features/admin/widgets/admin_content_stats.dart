import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/network/api_envelope.dart';

/// Số mục theo cấp độ, đếm trên các mục đang hiện.
class AdminContentStats extends StatelessWidget {
  const AdminContentStats({super.key, required this.content});

  final List<JsonObject> content;

  @override
  Widget build(BuildContext context) {
    final n5 = content.where((item) => item['level'] == 'N5').length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      child: Row(
        children: [
          _Stat('${content.length}', 'Đang hiện', AppColors.primary),
          _Stat('$n5', 'N5', AppColors.success),
          _Stat('${content.length - n5}', 'N4–N1', AppColors.warning),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.value, this.label, this.color);

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: AppTypography.title,
              fontWeight: FontWeight.bold,
              color: context.colors.readable(color),
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: AppTypography.caption, color: context.colors.textSecondary),
          ),
        ],
      ),
    );
  }
}
