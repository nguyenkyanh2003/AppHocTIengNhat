import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../core/state/view_state.dart';
import '../../../shared/widgets/adaptive_table.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/content_pane.dart';
import '../../achievements/models/achievement_labels.dart';
import '../../achievements/widgets/achievement_rarity.dart';
import '../models/admin_achievement.dart';
import '../providers/admin_provider.dart';
import '../widgets/admin_achievement_card.dart';
import '../widgets/admin_achievement_dialogs.dart';
import '../widgets/admin_achievement_summary.dart';

class AdminAchievementManagementScreen extends StatefulWidget {
  const AdminAchievementManagementScreen({super.key});

  @override
  State<AdminAchievementManagementScreen> createState() =>
      _AdminAchievementManagementScreenState();
}

class _AdminAchievementManagementScreenState
    extends State<AdminAchievementManagementScreen> {
  /// `null` là tất cả độ hiếm.
  String? _selectedRarity;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadAchievements();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Quản lý thành tích',
      actions: [
        IconButton(
          tooltip: 'Tải lại',
          icon: const Icon(Icons.refresh),
          onPressed: () => context.read<AdminProvider>().loadAchievements(),
        ),
      ],
      body: ContentWidthLimit(
        child: Consumer<AdminProvider>(
          builder: (context, adminProvider, child) {
            final all = adminProvider.achievements;
            final shown = _selectedRarity == null
                ? all
                : all
                    .where((a) => a.definition.rarity == _selectedRarity)
                    .toList();

            return Column(
              children: [
                AdminAchievementSummary(achievements: all),
                _rarityFilter(),
                Expanded(
                  child: AsyncView<List<AdminAchievement>>(
                    state: ViewState.fromLegacy(
                      isLoading: adminProvider.isLoadingAchievements,
                      error: all.isEmpty ? adminProvider.error : null,
                      value: shown,
                      isEmpty: shown.isEmpty,
                    ),
                    onRetry: () => adminProvider.loadAchievements(),
                    isEmpty: (items) => items.isEmpty,
                    emptyTitle: 'Không có thành tích nào',
                    emptyIcon: Icons.emoji_events_outlined,
                    builder: (context, items) =>
                        AdaptiveTable<AdminAchievement>(
                      // Chừa chỗ để nút thêm không che dòng cuối.
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.lg,
                        AppSpacing.lg,
                        AppSpacing.xxl * 3,
                      ),
                      items: items,
                      rowKey: (a) => ValueKey(a.definition.id),
                      columns: _columns(),
                      cardBuilder: (context, achievement) =>
                          AdminAchievementCard(achievement: achievement),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAchievementFormDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Thêm thành tích'),
      ),
    );
  }

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
