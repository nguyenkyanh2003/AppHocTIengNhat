import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../widgets/send_notification_dialog.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/content_pane.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../shared/widgets/adaptive_table.dart';
import '../../../app/theme/app_typography.dart';
import '../widgets/admin_user_style.dart';
import '../widgets/admin_user_actions.dart';
import '../widgets/admin_user_actions_menu.dart';
import '../widgets/admin_user_status_badge.dart';
import '../widgets/admin_user_card.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../core/state/view_state.dart';

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({Key? key}) : super(key: key);

  @override
  State<AdminUserManagementScreen> createState() =>
      _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Quản Lý Users',
      actions: [
        IconButton(
          tooltip: 'Gửi thông báo cho tất cả',
          icon: const Icon(Icons.campaign_outlined),
          onPressed: () => openSendNotificationForm(context),
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => context.read<AdminProvider>().loadUsers(),
        ),
      ],
      body: ContentWidthLimit(
        child: Consumer<AdminProvider>(
          builder: (context, adminProvider, child) {
            final allUsers = adminProvider.users;

            // Filter users based on search and selected filter
            final filteredUsers = allUsers.where((user) {
              final matchesSearch = _searchController.text.isEmpty ||
                  (user['name']
                          ?.toString()
                          .toLowerCase()
                          .contains(_searchController.text.toLowerCase()) ??
                      false) ||
                  (user['email']
                          ?.toString()
                          .toLowerCase()
                          .contains(_searchController.text.toLowerCase()) ??
                      false);

              final matchesFilter = _selectedFilter == 'all' ||
                  user['status'] == _selectedFilter ||
                  user['role'] == _selectedFilter;

              return matchesSearch && matchesFilter;
            }).toList();

            return Column(
              children: [
                // Search & Filter
                Container(
                  padding: const EdgeInsets.all(16),
                  color: context.colors.surfaceVariant,
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm user...',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: context.colors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (value) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('Tất cả', 'all'),
                            _buildFilterChip('Active', 'active'),
                            _buildFilterChip('Admin', 'admin'),
                            _buildFilterChip('Banned', 'banned'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Stats Bar
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  color: context.colors.primarySoft,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('${allUsers.length}', 'Tổng Users'),
                      _buildStatItem(
                          '${allUsers.where((u) => u['status'] == 'active').length}',
                          'Active'),
                      _buildStatItem(
                          '${allUsers.where((u) => u['role'] == 'admin').length}',
                          'Admin'),
                      _buildStatItem(
                          '${allUsers.where((u) => u['status'] == 'banned').length}',
                          'Banned'),
                    ],
                  ),
                ),

                // Users List
                Expanded(
                  child: AsyncView<List<Map<String, dynamic>>>(
                    state: ViewState.fromLegacy(
                      isLoading: adminProvider.isLoadingUsers,
                      error: allUsers.isEmpty ? adminProvider.error : null,
                      value: filteredUsers,
                      isEmpty: filteredUsers.isEmpty,
                    ),
                    onRetry: () => adminProvider.loadUsers(),
                    isEmpty: (users) => users.isEmpty,
                    emptyTitle: 'Không có người dùng nào',
                    emptyIcon: Icons.people_outline,
                    builder: (context, filteredUsers) =>
                        AdaptiveTable<Map<String, dynamic>>(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      items: filteredUsers,
                      rowKey: (user) => ValueKey(user['_id'] ?? user['id']),
                      columns: _userColumns(),
                      cardBuilder: (context, user) => AdminUserCard(user: user),
                      onRowTap: (user) => showAdminUserDetails(context, user),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Cột của bảng quản trị trên vùng rộng.
  ///
  /// Cùng dữ liệu với thẻ ở màn hẹp, chỉ khác cách bày: tên, email, vai trò,
  /// trạng thái và cùng một menu thao tác.
  List<AdaptiveColumn<Map<String, dynamic>>> _userColumns() {
    return [
      AdaptiveColumn(
        label: 'Người dùng',
        minWidth: 200,
        cell: (context, user) {
          final name = user['name']?.toString().trim() ?? '';
          return Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: adminUserRoleColor(user['role']),
                child: Text(
                  name.isEmpty ? '?' : name.characters.first.toUpperCase(),
                  style: const TextStyle(
                      color: Colors.white, fontSize: AppTypography.caption),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  name.isEmpty ? 'Chưa đặt tên' : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
        },
      ),
      AdaptiveColumn(
        label: 'Email',
        minWidth: 220,
        cell: (context, user) => Text(
          user['email']?.toString() ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      AdaptiveColumn(
        label: 'Vai trò',
        width: 110,
        cell: (context, user) => Text(user['role']?.toString() ?? 'user'),
      ),
      AdaptiveColumn(
        label: 'Trạng thái',
        width: 120,
        cell: (context, user) => AdminUserStatusBadge(status: user['status']),
      ),
      AdaptiveColumn(
        label: 'Thao tác',
        width: 72,
        alignEnd: true,
        cell: (context, user) => AdminUserActionsMenu(user: user),
      ),
    ];
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _selectedFilter = value);
        },
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : context.colors.textPrimary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: AppTypography.subtitle,
              fontWeight: FontWeight.bold,
              color: context.colors.primary,
            ),
          ),
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
