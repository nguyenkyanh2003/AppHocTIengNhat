import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/calm_colors.dart';

/// Nhịp khoảng cách của Trang chủ theo bản thiết kế 2026-09.
abstract final class HomeLayout {
  /// Lề ngang của màn.
  static const double gutter = 20;

  /// Giữa hai khối liền nhau (lời chào → chỉ số → thẻ bài học).
  static const double block = 20;

  /// Trước một mục có tiêu đề ("Góc học tập", "Từ mới hôm nay", "Tin tức mới").
  static const double section = 28;

  /// Vùng chạm tối thiểu của mọi nút.
  static const double minTap = 44;
}

/// Viền thẻ trắng dùng chung: phẳng, viền 1px, không đổ bóng.
BoxDecoration homeCardDecoration(CalmColors calm, {required double radius}) =>
    BoxDecoration(
      color: calm.card,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: calm.cardBorder),
    );

/// Tiêu đề một mục của Trang chủ, kèm liên kết "Xem tất cả" nếu có.
class HomeSectionHeader extends StatelessWidget {
  const HomeSectionHeader({super.key, required this.title, this.onSeeAll});

  final String title;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final calm = CalmColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTypography.ui(
                  size: 18, weight: FontWeight.w700, color: calm.textPrimary),
            ),
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              style: TextButton.styleFrom(
                foregroundColor: calm.accent,
                minimumSize: const Size(HomeLayout.minTap, HomeLayout.minTap),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                tapTargetSize: MaterialTapTargetSize.padded,
                textStyle: AppTypography.ui(size: 14, weight: FontWeight.w600),
              ),
              child: Text(AppLocalizations.of(context).viewAll),
            ),
        ],
      ),
    );
  }
}
