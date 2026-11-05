import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/study_group_provider.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/content_pane.dart';
import '../../../app/theme/app_tokens.dart';
import '../widgets/study_group_dialogs.dart';
import '../widgets/study_group_card.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../core/state/view_state.dart';
import '../models/study_group.dart';

class StudyGroupListScreen extends StatefulWidget {
  const StudyGroupListScreen({Key? key}) : super(key: key);

  @override
  State<StudyGroupListScreen> createState() => _StudyGroupListScreenState();
}

class _StudyGroupListScreenState extends State<StudyGroupListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<StudyGroupProvider>(context, listen: false);
      provider.loadMyGroups();
      provider.loadAllGroups(refresh: true);
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (_tabController.index == 1) {
        final provider =
            Provider.of<StudyGroupProvider>(context, listen: false);
        if (!provider.isLoading && provider.hasMore) {
          provider.loadAllGroups();
        }
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Nhóm học',
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () => showStudyGroupSearchDialog(context,
              searchController: _searchController,
              performSearch: _performSearch),
        ),
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: () => showStudyGroupFilterDialog(context,
              tabController: _tabController),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: BoxDecoration(
            color: context.colors.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: context.colors.readable(Colors.blue[700]!),
            unselectedLabelColor: context.colors.textSecondary,
            indicatorColor: context.colors.readable(Colors.blue[700]!),
            indicatorWeight: 3,
            labelStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.normal,
            ),
            indicator: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.12),
              border: Border(
                bottom: BorderSide(
                  color: context.colors.readable(Colors.blue[700]!),
                  width: 3,
                ),
              ),
            ),
            tabs: const [
              Tab(
                height: 60,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.group, size: 22),
                      SizedBox(height: 4),
                      Text('Nhóm của tôi'),
                    ],
                  ),
                ),
              ),
              Tab(
                height: 60,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.explore, size: 22),
                      SizedBox(height: 4),
                      Text('Khám phá'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: ContentWidthLimit(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildMyGroupsTab(),
            _buildAllGroupsTab(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/study-groups/new').then((created) {
            if (!mounted) return;
            if (created == true) {
              final provider = this.context.read<StudyGroupProvider>();
              provider.loadMyGroups();
            }
          });
        },
        icon: const Icon(Icons.add),
        label: const Text('Tạo nhóm'),
      ),
    );
  }

  Widget _buildMyGroupsTab() {
    return Consumer<StudyGroupProvider>(
      builder: (context, provider, child) {
        return AsyncView<List<StudyGroup>>(
          state: ViewState.fromLegacy(
            isLoading: provider.isLoading,
            error: provider.error,
            value: provider.myGroups,
            isEmpty: provider.myGroups.isEmpty,
          ),
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
              padding: const EdgeInsets.all(8),
              itemCount: groups.length,
              itemBuilder: (context, index) =>
                  StudyGroupCard(group: groups[index], isMyGroup: true),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAllGroupsTab() {
    return Consumer<StudyGroupProvider>(
      builder: (context, provider, child) => AsyncView<List<StudyGroup>>(
        state: ViewState.fromLegacy(
          isLoading: provider.isLoading,
          error: provider.error,
          value: provider.allGroups,
          isEmpty: provider.allGroups.isEmpty,
        ),
        onRetry: () => provider.loadAllGroups(refresh: true),
        isEmpty: (groups) => groups.isEmpty,
        emptyTitle: provider.searchQuery != null
            ? 'Không tìm thấy nhóm phù hợp'
            : 'Chưa có nhóm nào',
        emptyIcon: Icons.search_off,
        builder: (context, groups) => RefreshIndicator(
          onRefresh: () => provider.loadAllGroups(refresh: true),
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(8),
            itemCount: groups.length + (provider.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == groups.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              return StudyGroupCard(group: groups[index], isMyGroup: false);
            },
          ),
        ),
      ),
    );
  }

  void _performSearch(String query) {
    final provider = Provider.of<StudyGroupProvider>(context, listen: false);
    provider.setSearchQuery(query.isEmpty ? null : query);
    _tabController.animateTo(1);
  }
}
