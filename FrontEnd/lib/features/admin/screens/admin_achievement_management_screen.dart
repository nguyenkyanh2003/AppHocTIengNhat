import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../shared/widgets/adaptive_table.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/content_pane.dart';
import '../../achievements/models/achievement_labels.dart';
import '../../achievements/widgets/achievement_rarity.dart';
import '../models/admin_achievement.dart';
import '../providers/admin_achievements_provider.dart';
import '../services/admin_service.dart';
import '../widgets/admin_achievement_card.dart';
import '../widgets/admin_achievement_dialogs.dart';
import '../widgets/admin_achievement_summary.dart';

/// Quản lý huy hiệu. [service] chỉ để test truyền service giả.
class AdminAchievementManagementScreen extends StatelessWidget {
  const AdminAchievementManagementScreen({super.key, this.service});

  final AdminService? service;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminAchievementsProvider(service: service)..load(),
      child: const _AchievementsView(),
    );
  }
}

class _AchievementsView extends StatefulWidget {
  const _AchievementsView();

  @override
  State<_AchievementsView> createState() => _AchievementsViewState();
}

class _AchievementsViewState extends State<_AchievementsView> {
  /// `null` là tất cả độ hiếm.
  String? _selectedRarity;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminAchievementsProvider>();
    final all = provider.achievements.valueOrNull ?? const <AdminAchievement>[];

    return AppScaffold(
      title: 'Quản lý thành tích',
      actions: [
        IconButton(tooltip: 'Tải lại', icon: const Icon(Icons.refresh), onPressed: provider.load),
      ],
      body: ContentWidthLimit(
        child: Column(
          children: [
            AdminAchievementSummary(achievements: all),
            _rarityFilter(),
            Expanded(
              child: AsyncView<List<AdminAchievement>>(
                state: provider.achievements.map(_visible),
                onRetry: provider.load,
                isEmpty: (items) => items.isEmpty,
                emptyTitle: 'Không có thành tích nào',
                emptyIcon: Icons.emoji_events_outlined,
                builder: (context, items) => AdaptiveTable<AdminAchievement>(
                  // Chừa chỗ để nút thêm không che dòng cuối.
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xxl * 3),
                  items: items,
                  onRefresh: provider.load,
                  rowKey: (a) => ValueKey(a.definition.id),
                  columns: _columns(),
                  cardBuilder: (context, achievement) => AdminAchievementCard(achievement: achievement),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAchievementFormDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Thêm thành tích'),
      ),
    );
  }

  List<AdminAchievement> _visible(List<AdminAchievement> items) => _selectedRarity == null
      ? items
      : [for (final item in items) if (item.definition.rarity == _selectedRarity) item];

  Widget _rarityFilter() {
    Widget chip(String label, String? rarity) => Padding(
          padding: const EdgeInsets.only(right: AppSpacing.sm),
          child: FilterChip(
            label: Text(label),
            selected: _selectedRarity == rarity,
            onSelected: (_) => setState(() => _selectedRarity = rarity),
          ),
        );

    return SingleChildScrollView(
      padding: AppSpacing.page,
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          chip('Tất cả', null),
          for (final MapEntry(:key, :value) in achievementRarityLabels.entries)
            chip(value, key),
        ],
      ),
    );
  }

  /// Cột bảng thành tích trên vùng rộng; cùng dữ liệu với thẻ ở màn hẹp.
  List<AdaptiveColumn<AdminAchievement>> _columns() {
    return [
      AdaptiveColumn(
        label: 'Huy hiệu',
        minWidth: 220,
        cell: (context, a) => Text(
          a.definition.isActive
              ? a.definition.displayName
              : '${a.definition.displayName} (đang ẩn)',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      AdaptiveColumn(
        label: 'Nhóm',
        width: 120,
        cell: (context, a) => Text(
          achievementCategoryLabels[a.definition.category] ??
              a.definition.category,
        ),
      ),
      AdaptiveColumn(
        label: 'Độ hiếm',
        width: 120,
        cell: (context, a) => Align(
          alignment: Alignment.centerLeft,
          child: AchievementRarityChip(a.definition.rarity),
        ),
      ),
      AdaptiveColumn(
        label: 'Cần đạt',
        width: 80,
        alignEnd: true,
        cell: (context, a) => Text('${a.definition.requirementValue}'),
      ),
      AdaptiveColumn(
        label: 'XP',
        width: 72,
        alignEnd: true,
        cell: (context, a) => Text('${a.definition.xpReward}'),
      ),
      AdaptiveColumn(
        label: 'Đã mở',
        width: 72,
        alignEnd: true,
        cell: (context, a) => Text('${a.unlocked}'),
      ),
      AdaptiveColumn(
        label: 'Thao tác',
        width: 96,
        alignEnd: true,
        cell: (context, a) => PopupMenuButton<String>(
          onSelected: (action) {
            if (action == 'edit') {
              showAchievementFormDialog(context, initial: a.definition);
            }
            if (action == 'duplicate') {
              showAchievementFormDialog(
                context,
                initial: a.definition,
                asCopy: true,
              );
            }
            if (action == 'delete') confirmDeleteAchievement(context, a);
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'edit', child: Text('Sửa')),
            PopupMenuItem(value: 'duplicate', child: Text('Nhân bản')),
            PopupMenuItem(value: 'delete', child: Text('Xoá')),
          ],
        ),
      ),
    ];
  }
}
