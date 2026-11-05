import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/widgets/async_view.dart';
import '../../streaks/models/user_streak.dart';
import '../../streaks/providers/streak_provider.dart';
import '../models/xp_activity.dart';

/// Tab Hoạt động: các lần nhận XP, lọc theo nhóm hoạt động.
class HistoryActivityTab extends StatefulWidget {
  const HistoryActivityTab({super.key, required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  State<HistoryActivityTab> createState() => _HistoryActivityTabState();
}

class _HistoryActivityTabState extends State<HistoryActivityTab> {
  /// `null` là "Tất cả".
  XpActivityKind? _filter;

  static const _filters = [
    XpActivityKind.lesson,
    XpActivityKind.exercise,
    XpActivityKind.review,
    XpActivityKind.reward,
  ];

  Widget _chip(String label, XpActivityKind? value) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: ChoiceChip(
        label: Text(label),
        selected: _filter == value,
        onSelected: (_) => setState(() => _filter = value),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              _chip('Tất cả', null),
              for (final kind in _filters) _chip(kind.label, kind),
            ],
          ),
        ),
        Expanded(
          child: AsyncView<List<XPHistory>>(
            state: context.watch<StreakProvider>().xpHistoryState,
            onRetry: widget.onRefresh,
            isEmpty: (items) => items.isEmpty,
            emptyTitle: 'Chưa có hoạt động nào',
            emptyMessage: 'Bắt đầu học để ghi lại hoạt động!',
            emptyIcon: Icons.history,
            builder: (context, items) {
              final filter = _filter;
              final shown = filter == null
                  ? items
                  : items
                      .where((item) => xpActivityKindOf(item.reason) == filter)
                      .toList();
              if (shown.isEmpty) {
                return EmptyStateView(
                  title:
                      'Không có hoạt động nhóm ${filter?.label.toLowerCase()}',
                  icon: Icons.filter_alt_off_outlined,
                );
              }
              return RefreshIndicator(
                onRefresh: widget.onRefresh,
                child: ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  itemCount: shown.length,
                  itemBuilder: (context, index) =>
                      _ActivityTile(item: shown[index]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.item});

  final XPHistory item;

  static final _format = DateFormat("dd/MM/yyyy 'lúc' HH:mm");

  (IconData, Color) get _style => switch (xpActivityKindOf(item.reason)) {
        XpActivityKind.lesson => (Icons.menu_book, AppColors.primary),
        XpActivityKind.exercise => (Icons.quiz, AppColors.success),
        XpActivityKind.review => (Icons.replay, AppColors.warning),
        XpActivityKind.reward => (Icons.emoji_events, Colors.deepOrange),
        XpActivityKind.other => (Icons.star, Colors.purple),
      };

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _style;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  Icon(icon, color: context.colors.readable(color), size: 24),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.reason,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: AppTypography.bodySmall,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _format.format(item.earnedAt.toLocal()),
                    style: TextStyle(
                      fontSize: AppTypography.caption,
                      color: context.colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '+${item.amount} XP',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: context.colors.readable(AppColors.warning),
                fontSize: AppTypography.caption,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
