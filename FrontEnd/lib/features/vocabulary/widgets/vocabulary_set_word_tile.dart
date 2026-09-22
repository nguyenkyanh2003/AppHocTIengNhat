import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../shared/widgets/chunky_card.dart';
import '../models/vocabulary.dart';

/// Một từ trong bộ học: số thứ tự, mặt chữ, cách đọc, âm Hán-Việt, nghĩa và
/// nút đánh dấu đã học ngay trên thẻ.
///
/// Khác [VocabularyCard] của màn tra cứu: trong một bộ mọi từ cùng cấp nên bỏ
/// nhãn cấp độ, và cách đọc chỉ hiện khi khác mặt chữ — từ viết bằng kana
/// (たいへんですね) không cần lặp lại chính nó ở dòng dưới.
class VocabularySetWordTile extends StatelessWidget {
  const VocabularySetWordTile({
    super.key,
    required this.index,
    required this.vocabulary,
    required this.onTap,
    required this.onToggleLearned,
    required this.onAddToFlashcard,
    this.busy = false,
  });

  /// Số thứ tự trong bộ, đếm từ 1.
  final int index;
  final Vocabulary vocabulary;
  final VoidCallback onTap;
  final VoidCallback onToggleLearned;
  final VoidCallback onAddToFlashcard;

  /// Đang có thao tác đánh dấu chạy — khoá nút để không gửi chồng lệnh.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final learned = vocabulary.isLearned;
    final reading = vocabulary.hiragana;
    final hanviet = vocabulary.hanviet;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ChunkyCard(
        onTap: onTap,
        padding: AppSpacing.page,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _IndexBadge(index: index, learned: learned),
            AppGap.lg,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(vocabulary.word, style: textTheme.headlineSmall),
                  if (reading.isNotEmpty && reading != vocabulary.word)
                    Text(
                      reading,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  if (hanviet != null && hanviet.isNotEmpty) ...[
                    AppGap.xs,
                    Text(
                      hanviet.toUpperCase(),
                      style: textTheme.labelMedium?.copyWith(
                        color: AppColors.vocabulary,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                  AppGap.sm,
                  Text(vocabulary.meaning, style: textTheme.bodyLarge),
                ],
              ),
            ),
            AppGap.sm,
            Column(
              children: [
                IconButton(
                  onPressed: busy ? null : onToggleLearned,
                  tooltip: learned ? 'Bỏ đánh dấu đã học' : 'Đánh dấu đã học',
                  icon: Icon(
                    learned
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: learned ? AppColors.success : AppColors.textDisabled,
                  ),
                ),
                IconButton(
                  onPressed: onAddToFlashcard,
                  tooltip: 'Thêm vào bộ thẻ của tôi',
                  icon: const Icon(
                    Icons.bookmark_add_outlined,
                    color: AppColors.vocabulary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _IndexBadge extends StatelessWidget {
  const _IndexBadge({required this.index, required this.learned});

  final int index;
  final bool learned;

  @override
  Widget build(BuildContext context) {
    final color = learned ? AppColors.success : AppColors.vocabulary;

    return CircleAvatar(
      radius: AppSpacing.lg,
      backgroundColor: color.withValues(alpha: 0.12),
      foregroundColor: color,
      child: Text(
        '$index',
        style: Theme.of(context)
            .textTheme
            .labelLarge
            ?.copyWith(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}
