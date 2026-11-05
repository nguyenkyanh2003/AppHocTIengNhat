import 'package:flutter/material.dart';
import '../../../app/theme/app_tokens.dart';

import '../../../app/theme/app_typography.dart';
import '../models/kanji.dart';

/// Đầu trang chi tiết: chữ Kanji cỡ lớn và cấp độ, thu lại khi cuộn.
class KanjiDetailHeader extends StatelessWidget {
  const KanjiDetailHeader({super.key, required this.kanji});

  final Kanji kanji;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      backgroundColor: AppColors.kanjiCoral,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.kanjiCoral, AppColors.kanjiCoralEnd],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      kanji.character,
                      style: AppTypography.japaneseDisplay(
                        color: Colors.white,
                        size: 100,
                      ),
                    ),
                    if (kanji.level != null)
                      Container(
                        margin: const EdgeInsets.only(top: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          kanji.level!,
                          style: const TextStyle(
                            fontSize: AppTypography.body,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
