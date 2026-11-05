import 'package:flutter/material.dart';
import '../../../app/theme/app_tokens.dart';

/// Nút chuyển thẻ trước và sau.
class FlashcardNavigationControls extends StatelessWidget {
  const FlashcardNavigationControls({
    super.key,
    required this.currentIndex,
    required this.studyList,
    required this.canGoBack,
    required this.canGoForward,
    required this.goToPrevious,
    required this.goToNext,
  });

  final int currentIndex;
  final List<dynamic> studyList;
  final bool canGoBack;
  final bool canGoForward;
  final VoidCallback goToPrevious;
  final VoidCallback goToNext;

  @override
  Widget build(BuildContext context) {
    final total = studyList.length;
    final position = currentIndex >= total ? total : currentIndex + 1;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          OutlinedButton.icon(
            onPressed: canGoBack ? goToPrevious : null,
            icon: const Icon(Icons.chevron_left),
            label: const Text('Thẻ trước'),
          ),
          Flexible(
            child: Text(
              currentIndex >= total ? 'Đã hết thẻ' : '$position / $total',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          FilledButton.icon(
            onPressed: canGoForward ? goToNext : null,
            icon: const Icon(Icons.chevron_right),
            label: const Text('Thẻ sau'),
          ),
        ],
      ),
    );
  }
}
