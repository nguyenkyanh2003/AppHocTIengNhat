import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../models/kanji.dart';

/// Cách đọc của chữ: Âm Hán (onyomi) và Âm Kun (kunyomi).
class KanjiReadingsCard extends StatelessWidget {
  const KanjiReadingsCard({super.key, required this.kanji});

  final Kanji kanji;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.volume_up_outlined, color: Color(0xFFFF6B6B), size: 20),
              SizedBox(width: 8),
              Text(
                'Cách đọc',
                style: TextStyle(
                  fontSize: AppTypography.body,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (kanji.onyomi.isNotEmpty) ...[
            _ReadingRow(label: 'Âm Hán', value: kanji.onyomi.join('、'), color: AppColors.primary),
            const SizedBox(height: 12),
          ],
          if (kanji.kunyomi.isNotEmpty)
            _ReadingRow(label: 'Âm Kun', value: kanji.kunyomi.join('、'), color: AppColors.success),
        ],
      ),
    );
  }
}

class _ReadingRow extends StatelessWidget {
  const _ReadingRow({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: AppTypography.bodySmall,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: AppTypography.subtitle,
              color: Color(0xFF2C3E50),
            ),
          ),
        ),
      ],
    );
  }
}
