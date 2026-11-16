import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../shared/widgets/adaptive_table.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/content_pane.dart';
import '../models/admin_user.dart';
import '../providers/admin_users_provider.dart';
import '../services/admin_service.dart';
import '../widgets/admin_user_actions.dart';
import '../widgets/admin_user_card.dart';
import '../widgets/admin_user_table.dart';
import '../widgets/send_notification_dialog.dart';

/// Quản lý tài khoản: tìm và lọc phía server, tải thêm khi cuộn.
/// [service] chỉ để test truyền service giả.
class AdminUserManagementScreen extends StatelessWidget {
  const AdminUserManagementScreen({super.key, this.service});

  final AdminService? service;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminUsersProvider(service: service)..load(),
      child: const _UsersView(),
    );
  }
}

class _UsersView extends StatefulWidget {
  const _UsersView();

  @override
  State<_UsersView> createState() => _UsersViewState();
}

class _UsersViewState extends State<_UsersView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearch(AdminUsersProvider provider) {
    _searchController.clear();
    provider.searchUsers('');
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminUsersProvider>();

    return AppScaffold(
      title: 'Quản lý người dùng',
      actions: [
        IconButton(
          tooltip: 'Gửi thông báo cho tất cả',
          icon: const Icon(Icons.campaign_outlined),
          onPressed: () => openSendNotificationForm(context),
        ),
        IconButton(tooltip: 'Tải lại', icon: const Icon(Icons.refresh), onPressed: provider.load),
      ],
      body: ContentWidthLimit(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              color: context.colors.surfaceVariant,
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Tìm theo tên, tên đăng nhập hoặc email…',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: provider.search == null
                          ? null
                          : IconButton(
                              tooltip: 'Xoá tìm kiếm',
                              icon: const Icon(Icons.clear),
                              onPressed: () => _clearSearch(provider),
                            ),
                      filled: true,
                      fillColor: context.colors.surface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    onSubmitted: provider.searchUsers,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final filter in AdminUserFilter.values)
                          Padding(
                            padding: const EdgeInsets.only(right: AppSpacing.sm),
                            child: FilterChip(
                              label: Text(filter.label),
                              selected: provider.filter == filter,
                              onSelected: (_) => provider.selectFilter(filter),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            AsyncView<AdminUserStats>(
              state: provider.stats,
              compact: true,
              builder: (context, stats) => AdminUserStatsBar(stats: stats),
            ),
            if (provider.isRefreshing) const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: AsyncView<List<AdminUser>>(
                state: provider.users,
                onRetry: provider.load,
                isEmpty: (users) => users.isEmpty,
                emptyTitle: 'Không có người dùng nào',
                emptyIcon: Icons.people_outline,
                builder: (context, users) => AdaptiveTable<AdminUser>(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  items: users,
                  onRefresh: provider.load,
                  rowKey: (user) => ValueKey(user.id),
                  columns: adminUserColumns(),
                  cardBuilder: (context, user) => AdminUserCard(user: user),
                  onRowTap: (user) => showAdminUserDetails(context, user),
                  paging: TablePaging(
                    hasMore: provider.hasMore,
                    isLoadingMore: provider.isLoadingMore,
                    error: provider.loadMoreError,
                    onLoadMore: provider.loadMore,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
