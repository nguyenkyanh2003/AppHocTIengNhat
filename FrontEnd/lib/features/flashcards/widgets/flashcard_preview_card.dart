import 'package:flutter/material.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/app_tokens.dart';

/// Xem trước hai mặt của thẻ đang nhập.
class FlashcardPreviewCard extends StatelessWidget {
  const FlashcardPreviewCard({
    super.key,
    required this.frontController,
    required this.backController,
    required this.frontSubtextController,
    required this.backSubtextController,
  });

  final TextEditingController frontController;
  final TextEditingController backController;
  final TextEditingController frontSubtextController;
  final TextEditingController backSubtextController;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Xem trước:',
              style: TextStyle(
                fontSize: AppTypography.bodySmall,
                fontWeight: FontWeight.bold,
                color: context.colors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Mặt trước:',
              style: TextStyle(
                  fontSize: AppTypography.caption,
                  color: context.colors.textSecondary),
            ),
            Text(
              frontController.text.isEmpty ? '(Trống)' : frontController.text,
              style: const TextStyle(
                fontSize: AppTypography.title,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (frontSubtextController.text.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                frontSubtextController.text,
                style: TextStyle(
                    fontSize: AppTypography.bodySmall,
                    color: context.colors.textSecondary),
              ),
            ],
            const Divider(height: 24),
            Text(
              'Mặt sau:',
              style: TextStyle(
                  fontSize: AppTypography.caption,
                  color: context.colors.textSecondary),
            ),
            Text(
              backController.text.isEmpty ? '(Trống)' : backController.text,
              style: const TextStyle(
                fontSize: AppTypography.subtitle,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (backSubtextController.text.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                backSubtextController.text,
                style: TextStyle(
                    fontSize: AppTypography.bodySmall,
                    color: context.colors.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
