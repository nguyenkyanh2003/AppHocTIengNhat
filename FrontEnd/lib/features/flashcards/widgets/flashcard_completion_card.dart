import 'package:flutter/material.dart';
import '../../../app/theme/app_tokens.dart';

/// Thẻ chúc mừng khi học hết bộ.
class FlashcardCompletionCard extends StatelessWidget {
  const FlashcardCompletionCard({
    super.key,
    required this.restartStudy,
  });

  final VoidCallback restartStudy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 4,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_outline_rounded,
                  color: context.colors.readable(AppColors.success), size: 80),
              const SizedBox(height: 24),
              Text(
                'Hoàn thành!',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: 12),
              Text(
                'Bạn đã học hết bộ từ này.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: context.colors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Học lại từ đầu'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: restartStudy,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Thoát'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
