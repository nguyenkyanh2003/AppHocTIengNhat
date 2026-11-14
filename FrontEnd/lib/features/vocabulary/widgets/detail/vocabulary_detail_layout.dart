import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../shared/widgets/content_pane.dart';

/// Bố cục màn chi tiết từ: hai cột trên màn rộng (thẻ từ và mức ghi nhớ bên
/// trái, phần còn lại bên phải), một cột trên màn hẹp theo đúng thứ tự đó. Nội
/// dung luôn giới hạn bề rộng [AppContentWidth.detail] và nằm giữa trang.
class VocabularyDetailLayout extends StatelessWidget {
  const VocabularyDetailLayout({super.key, required this.primary, required this.secondary});

  /// Từ bề rộng này (vùng nội dung, không tính thanh điều hướng) thì chia
  /// hai cột; hẹp hơn thì cột phải bị ép dưới ~480px, đọc câu ví dụ rất chật.
  static const double twoColumnMinWidth = 840;

  final List<Widget> primary;
  final List<Widget> secondary;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= twoColumnMinWidth;
        final padding = EdgeInsets.all(wide ? AppSpacing.xl : AppSpacing.lg);

        if (!wide) {
          return ListView(
            padding: ContentPane.paddingFor(
              constraints.maxWidth,
              maxWidth: AppContentWidth.reading,
              base: padding,
            ),
            children: [...primary, ...secondary],
          );
        }

        return SingleChildScrollView(
          padding: padding,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppContentWidth.detail),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: Column(children: primary)),
                  AppGap.xl,
                  Expanded(flex: 7, child: Column(children: secondary)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
