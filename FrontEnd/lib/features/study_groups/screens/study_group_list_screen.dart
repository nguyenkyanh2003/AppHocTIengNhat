import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/content_pane.dart';
import '../../../shared/widgets/paged_list_view.dart';
import '../models/study_group.dart';
import '../providers/study_group_provider.dart';
import '../widgets/study_group_card.dart';
import '../widgets/study_group_dialogs.dart';

class StudyGroupListScreen extends StatefulWidget {
  const StudyGroupListScreen({super.key});

  @override
  State<StudyGroupListScreen> createState() => _StudyGroupListScreenState();
}

class _StudyGroupListScreenState extends State<StudyGroupListScreen> with SingleTickerProviderStateMixin {
  late final _tabController = TabController(length: 2, vsync: this);
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<StudyGroupProvider>();
      provider.loadMyGroups();
      provider.loadAllGroups();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _search(String query) {
    context.read<StudyGroupProvider>().setSearchQuery(query);
    _tabController.animateTo(1);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudyGroupProvider>();
    return AppScaffold(
      title: 'Nhóm học',
      actions: [
        IconButton(
          tooltip: 'Tìm nhóm',
          icon: const Icon(Icons.search),
          onPressed: () =>
              showStudyGroupSearchDialog(context, searchController: _searchController, performSearch: _search),
        ),
        IconButton(
          tooltip: 'Lọc theo cấp độ',
          icon: const Icon(Icons.filter_list),
          onPressed: () => showStudyGroupFilterDialog(context, tabController: _tabController),
        ),
      ],
      bottom: _GroupTabs(controller: _tabController),
      body: ContentWidthLimit(
        child: TabBarView(
          controller: _tabController,
          children: [
            AsyncView<List<StudyGroup>>(
              state: provider.myGroups,
              onRetry: provider.loadMyGroups,
              isEmpty: (groups) => groups.isEmpty,
              emptyTitle: 'Bạn chưa tham gia nhóm nào',
              emptyIcon: Icons.group_off,
              emptyAction: ElevatedButton.icon(
                onPressed: () => _tabController.animateTo(1),
                icon: const Icon(Icons.explore),
                label: const Text('Khám phá nhóm'),
              ),
              builder: (context, groups) => RefreshIndicator(
                onRefresh: provider.loadMyGroups,
                child: ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  itemCount: groups.length,
                  itemBuilder: (context, index) => StudyGroupCard(group: groups[index], isMyGroup: true),
                ),
              ),
            ),
            AsyncView<List<StudyGroup>>(
              state: provider.allGroups,
              onRetry: provider.loadAllGroups,
              isEmpty: (groups) => groups.isEmpty,
              emptyTitle: provider.searchQuery != null ? 'Không tìm thấy nhóm phù hợp' : 'Chưa có nhóm nào',
              emptyIcon: Icons.search_off,
              builder: (context, groups) => RefreshIndicator(
                onRefresh: provider.loadAllGroups,
                child: PagedListView<StudyGroup>(
                  items: groups,
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  hasMore: provider.hasMore,
                  isLoadingMore: provider.isLoadingMore,
                  loadMoreError: provider.loadMoreError,
                  onLoadMore: provider.loadMore,
                  itemBuilder: (context, group) => StudyGroupCard(group: group, isMyGroup: false),
                ),
              ),
            ),
          ],
        ),
      ),
      // Tạo xong provider tự tải lại "Nhóm của tôi".
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/study-groups/new'),
        icon: const Icon(Icons.add),
        label: const Text('Tạo nhóm'),
      ),
    );
  }
}

class _GroupTabs extends StatelessWidget implements PreferredSizeWidget {
  const _GroupTabs({required this.controller});

  final TabController controller;

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    final accent = context.colors.readable(Colors.blue[700]!);
    Widget tab(IconData icon, String label) => Tab(
          height: 60,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [Icon(icon, size: 22), const SizedBox(height: AppSpacing.xs), Text(label)],
            ),
          ),
        );

    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: TabBar(
        controller: controller,
        labelColor: accent,
        unselectedLabelColor: context.colors.textSecondary,
        indicatorColor: accent,
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
        indicator: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.12),
          border: Border(bottom: BorderSide(color: accent, width: 3)),
        ),
        tabs: [tab(Icons.group, 'Nhóm của tôi'), tab(Icons.explore, 'Khám phá')],
      ),
    );
  }
}
