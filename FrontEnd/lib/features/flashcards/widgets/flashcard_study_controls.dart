import 'package:flutter/material.dart';
import '../../../app/theme/app_tokens.dart';

/// Nút chuyển thẻ trước và sau.
///
/// Khổ hẹp (điện thoại nhỏ, chữ phóng to) thì nút chỉ còn mũi tên kèm chú thích
/// khi giữ, để số thứ tự thẻ ở giữa không bị ép tràn.
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

  /// Dưới bề rộng này, hai nút có chữ cộng số thứ tự không còn vừa một hàng.
  static const double labelledMinWidth = 420;

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
    final back = canGoBack ? goToPrevious : null;
    final next = canGoForward ? goToNext : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < labelledMinWidth;
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              compact
                  ? IconButton.outlined(onPressed: back, icon: const Icon(Icons.chevron_left), tooltip: 'Thẻ trước')
                  : OutlinedButton.icon(
                      onPressed: back,
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
              compact
                  ? IconButton.filled(onPressed: next, icon: const Icon(Icons.chevron_right), tooltip: 'Thẻ sau')
                  : FilledButton.icon(
                      onPressed: next,
                      icon: const Icon(Icons.chevron_right),
                      label: const Text('Thẻ sau'),
                    ),
            ],
          );
        },
      ),
    );
  }
}
