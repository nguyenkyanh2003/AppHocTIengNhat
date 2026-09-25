import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../models/user_streak.dart';

/// Mười lần nhận XP gần nhất.
class XpHistoryCard extends StatelessWidget {
  const XpHistoryCard({super.key, required this.history, this.now});

  final List<XPHistory> history;

  /// Mốc "bây giờ" để tính "x phút trước"; test truyền vào cho ổn định.
  final DateTime? now;

  static const _shown = 10;

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return Card(
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Lịch sử XP', style: theme.textTheme.titleMedium),
            AppGap.sm,
            for (final entry in history.take(_shown))
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(entry.reason),
                subtitle: Text(_relative(entry.earnedAt)),
                trailing: Text(
                  '+${entry.amount}',
                  style: theme.textTheme.titleSmall?.copyWith(color: AppColors.success),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _relative(DateTime at) {
    final local = at.toLocal();
    final diff = (now ?? DateTime.now()).difference(local);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    return '${local.day}/${local.month}/${local.year}';
  }
}
