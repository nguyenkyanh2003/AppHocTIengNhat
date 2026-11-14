import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/widgets/level_badge.dart';
import '../models/grammar.dart';

/// Một dòng trong danh sách ngữ pháp: cấp độ, tiêu đề, nghĩa và lượt xem.
class GrammarCard extends StatelessWidget {
  const GrammarCard({super.key, required this.grammar, required this.onTap});

  final Grammar grammar;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: ListTile(
        onTap: onTap,
        leading: LevelBadge(grammar.level),
        title: Text(
          grammar.title.isNotEmpty ? grammar.title : grammar.pattern,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(grammar.meaning, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.visibility_outlined, size: 18, color: context.colors.textSecondary),
            AppGap.xs,
            Text(
              '${grammar.viewCount}',
              style: TextStyle(fontSize: AppTypography.caption, color: context.colors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
