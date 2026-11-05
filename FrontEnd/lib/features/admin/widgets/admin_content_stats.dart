import 'package:flutter/material.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';

/// Số mục theo cấp độ của loại đang xem.
class AdminContentStats extends StatelessWidget {
  const AdminContentStats({
    super.key,
    required this.content,
  });

  final List<Map<String, dynamic>> content;

  @override
  Widget build(BuildContext context) {
    int countLevel(String level) =>
        content.where((item) => item['level'] == level).length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _stat(context, content.length.toString(), 'Tổng', AppColors.primary),
          _stat(context, countLevel('N5').toString(), 'N5', AppColors.success),
          _stat(
            context,
            (content.length - countLevel('N5')).toString(),
            'N4–N1',
            AppColors.warning,
          ),
        ],
      ),
    );
  }

  Widget _stat(BuildContext context, String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: AppTypography.title,
            fontWeight: FontWeight.bold,
            color: context.colors.readable(color),
          ),
        ),
        Text(label,
            style: TextStyle(
                fontSize: AppTypography.caption,
                color: context.colors.textSecondary)),
      ],
    );
  }
}
