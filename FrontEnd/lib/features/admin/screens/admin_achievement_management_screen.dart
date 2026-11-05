import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/content_pane.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../shared/widgets/adaptive_table.dart';
import '../../../app/theme/app_typography.dart';
import '../widgets/admin_achievement_dialogs.dart';
import '../widgets/admin_achievement_card.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../core/state/view_state.dart';

class AdminAchievementManagementScreen extends StatefulWidget {
  const AdminAchievementManagementScreen({Key? key}) : super(key: key);

  @override
  State<AdminAchievementManagementScreen> createState() =>
      _AdminAchievementManagementScreenState();
}

class _AdminAchievementManagementScreenState
    extends State<AdminAchievementManagementScreen> {
  String _selectedRarity = 'all';

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
      title: 'Quản Lý Achievements',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => context.read<AdminProvider>().loadAchievements(),
        ),
      ],
      body: ContentWidthLimit(
        child: Consumer<AdminProvider>(
          builder: (context, adminProvider, child) {
            final allAchievements = adminProvider.achievements;

            final filteredAchievements = _selectedRarity == 'all'
                ? allAchievements
                : allAchievements
                    .where((a) => a['rarity'] == _selectedRarity)
                    .toList();

            return Column(
              children: [
                // Stats Bar
                Container(
                  padding: const EdgeInsets.all(16),
                  color: context.colors.surfaceVariant,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatCard('${allAchievements.length}', 'Tổng',
                          AppColors.primary),
                      _buildStatCard(
                        _getTotalUnlocked(allAchievements).toString(),
                        'Đã mở khóa',
                        AppColors.success,
                      ),
                      _buildStatCard(
                        _getTotalXP(allAchievements).toString(),
                        'XP thưởng',
                        Colors.purple,
                      ),
                    ],
                  ),
                ),

                // Rarity Filter
                Container(
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildRarityChip(
                            'Tất cả', 'all', context.colors.textSecondary),
                        _buildRarityChip(
                            'Common', 'common', context.colors.textSecondary),
                        _buildRarityChip('Rare', 'rare', AppColors.primary),
                        _buildRarityChip('Epic', 'epic', Colors.purple),
                        _buildRarityChip(
                            'Legendary', 'legendary', AppColors.warning),
                      ],
                    ),
                  ),
                ),

                // Achievements List
                Expanded(
                  child: AsyncView<List<Map<String, dynamic>>>(
                    state: ViewState.fromLegacy(
                      isLoading: adminProvider.isLoadingAchievements,
                      error:
                          allAchievements.isEmpty ? adminProvider.error : null,
                      value: filteredAchievements,
                      isEmpty: filteredAchievements.isEmpty,
                    ),
                    onRetry: () => adminProvider.loadAchievements(),
                    isEmpty: (items) => items.isEmpty,
                    emptyTitle: 'Không có thành tích nào',
                    emptyIcon: Icons.emoji_events_outlined,
                    builder: (context, filteredAchievements) =>
                        AdaptiveTable<Map<String, dynamic>>(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      items: filteredAchievements,
                      rowKey: (a) => ValueKey(a['_id'] ?? a['id']),
                      columns: _achievementColumns(),
                      cardBuilder: (context, achievement) =>
                          AdminAchievementCard(
                              achievement: achievement,
                              duplicateAchievement: _duplicateAchievement),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAchievementAddDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Thêm Achievement'),
      ),
    );
  }

  Widget _buildStatCard(String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: AppTypography.headline,
              fontWeight: FontWeight.bold,
              color: context.colors.readable(color),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: AppTypography.caption,
              color: context.colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRarityChip(String label, String value, Color color) {
    final isSelected = _selectedRarity == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _selectedRarity = value);
        },
        selectedColor: color.withValues(alpha: 0.3),
        backgroundColor: color.withValues(alpha: 0.1),
        labelStyle: TextStyle(
          color: context.colors.readable(color),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  int _getTotalUnlocked(List<Map<String, dynamic>> achievements) {
    return achievements.fold<int>(
      0,
      (sum, item) => sum + ((item['unlocked'] ?? 0) as int),
    );
  }

  int _getTotalXP(List<Map<String, dynamic>> achievements) {
    return achievements.fold<int>(
      0,
      (sum, item) => sum + ((item['xp'] ?? 0) as int),
    );
  }

  /// Cot bang thanh tich tren vung rong; cung du lieu voi the o man hep.
  List<AdaptiveColumn<Map<String, dynamic>>> _achievementColumns() {
    return [
      AdaptiveColumn(
        label: 'Huy hiệu',
        minWidth: 220,
        cell: (context, a) => Text(
          (a['name'] ?? '').toString(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      AdaptiveColumn(
        label: 'Nhóm',
        width: 140,
        cell: (context, a) => Text((a['category'] ?? '').toString()),
      ),
      AdaptiveColumn(
        label: 'Độ hiếm',
        width: 120,
        cell: (context, a) => Text((a['rarity'] ?? '').toString()),
      ),
      AdaptiveColumn(
        label: 'XP',
        width: 80,
        alignEnd: true,
        cell: (context, a) => Text((a['xp'] ?? 0).toString()),
      ),
      AdaptiveColumn(
        label: 'Thao tác',
        width: 96,
        alignEnd: true,
        cell: (context, a) => PopupMenuButton<String>(
          onSelected: (action) {
            if (action == 'edit') showAchievementEditDialog(context, a);
            if (action == 'duplicate') _duplicateAchievement(a);
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

  void _duplicateAchievement(Map<String, dynamic> achievement) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã nhân bản achievement!')),
    );
  }
}
