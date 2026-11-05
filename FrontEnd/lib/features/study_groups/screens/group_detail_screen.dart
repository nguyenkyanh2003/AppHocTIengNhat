import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/providers/auth_provider.dart';
import '../models/study_group.dart';
import '../providers/study_group_provider.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/content_pane.dart';
import '../../../app/theme/app_tokens.dart';
import '../widgets/group_settings_sheet.dart';
import '../widgets/group_detail_header.dart';
import '../widgets/group_info_tab.dart';
import '../widgets/group_members_tab.dart';
import '../widgets/group_bottom_bar.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../core/state/view_state.dart';

class GroupDetailScreen extends StatefulWidget {
  final String groupId;

  const GroupDetailScreen({Key? key, required this.groupId}) : super(key: key);

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final groupProvider =
          Provider.of<StudyGroupProvider>(context, listen: false);
      groupProvider.loadGroupDetail(widget.groupId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<StudyGroupProvider, AuthProvider>(
      builder: (context, groupProvider, authProvider, child) {
        final group = groupProvider.currentGroup;
        final currentUserId = authProvider.user?.id;

        if (group == null) {
          return AppScaffold(
            title: 'Chi tiết nhóm',
            body: ContentWidthLimit(
              child: AsyncView<StudyGroup>(
                state: ViewState.detail(
                  isLoading: groupProvider.isLoading,
                  error: groupProvider.error,
                  value: group,
                ),
                onRetry: () => groupProvider.loadGroupDetail(widget.groupId),
                builder: (context, _) => const SizedBox.shrink(),
              ),
            ),
          );
        }

        final isMember = currentUserId != null && group.isMember(currentUserId);
        final isAdmin = currentUserId != null && group.isAdmin(currentUserId);
        final isCreator =
            currentUserId != null && group.isCreator(currentUserId);

        return Scaffold(
          appBar: AppBar(
            title: Text(group.name),
            actions: [
              if (isAdmin)
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () => showGroupSettingsSheet(context, group),
                  tooltip: 'Cài đặt nhóm',
                ),
            ],
          ),
          body: ContentWidthLimit(
            child: Column(
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height / 2,
                  ),
                  child: SingleChildScrollView(
                    child: GroupDetailHeader(
                        group: group,
                        isMember: isMember,
                        isAdmin: isAdmin,
                        isCreator: isCreator),
                  ),
                ),
                Container(
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
                              Icon(Icons.info_outline, size: 22),
                              SizedBox(height: 4),
                              Text('Thông tin'),
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
                              Icon(Icons.people_outline, size: 22),
                              SizedBox(height: 4),
                              Text('Thành viên'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      GroupInfoTab(group: group, provider: groupProvider),
                      GroupMembersTab(
                          group: group,
                          currentUserId: currentUserId,
                          isAdmin: isAdmin,
                          isCreator: isCreator,
                          groupId: widget.groupId),
                    ],
                  ),
                ),
                // Thanh hành động của nhóm nằm trong thân trang, không phải
                // `bottomNavigationBar` — chỗ đó là của `AppShell`.
                SizedBox(
                  width: double.infinity,
                  child: GroupBottomBar(
                      group: group,
                      isMember: isMember,
                      isCreator: isCreator,
                      currentUserId: currentUserId ?? ''),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
