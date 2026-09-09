import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/content_pane.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../shared/widgets/adaptive_table.dart';

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
                  color: Colors.grey[100],
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm user...',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.white,
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
                  color: Colors.blue.shade50,
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
                  child: adminProvider.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : filteredUsers.isEmpty
                          ? const Center(child: Text('Không có users nào'))
                          : AdaptiveTable<Map<String, dynamic>>(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              items: filteredUsers,
                              rowKey: (user) =>
                                  ValueKey(user['_id'] ?? user['id']),
                              columns: _userColumns(),
                              cardBuilder: (context, user) =>
                                  _buildUserCard(user),
                              onRowTap: _showUserDetails,
                            ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Menu thao tác của một người dùng.
  ///
  /// Dùng chung cho thẻ ở màn hẹp và ô "Thao tác" của bảng ở màn rộng, để hai
  /// bố cục không bao giờ lệch nhau về những việc admin làm được.
  Widget _buildUserActionsMenu(Map<String, dynamic> user) {
    return PopupMenuButton(
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'view',
          child: Row(
            children: [
              Icon(Icons.visibility, size: 20),
              SizedBox(width: 8),
              Text('Xem chi tiết'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'promote',
          child: Row(
            children: [
              const Icon(Icons.admin_panel_settings, size: 20),
              const SizedBox(width: 8),
              Text(
                user['role'] == 'admin' ? 'Hạ quyền User' : 'Nâng quyền Admin',
              ),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'ban',
          child: Row(
            children: [
              Icon(Icons.block, size: 20, color: Colors.red),
              SizedBox(width: 8),
              Text('Khóa/Mở khóa', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 20, color: Colors.red),
              SizedBox(width: 8),
              Text('Xóa User', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
      onSelected: (value) => _handleUserAction(value.toString(), user),
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
                backgroundColor: _getRoleColor(user['role']),
                child: Text(
                  name.isEmpty ? '?' : name.characters.first.toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
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
        cell: (context, user) => _buildStatusBadge(user['status']),
      ),
      AdaptiveColumn(
        label: 'Thao tác',
        width: 72,
        alignEnd: true,
        cell: (context, user) => _buildUserActionsMenu(user),
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
        selectedColor: Colors.blue,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final displayName = user['name']?.toString().trim() ?? '';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _getRoleColor(user['role']),
          child: Text(
            displayName.isEmpty
                ? '?'
                : displayName.characters.first.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Row(
          children: [
            Text(
              displayName.isEmpty ? 'Chưa đặt tên' : displayName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            _buildStatusBadge(user['status']),
            if (user['role'] == 'admin') ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'ADMIN',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(user['email']),
        trailing: _buildUserActionsMenu(user),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        '📅 Tham gia',
                        user['joinDate'],
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        '🕐 Hoạt động',
                        user['lastActive'],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        '✨ Total XP',
                        user['totalXP'].toString(),
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        '🔥 Streak',
                        '${user['streak']} days',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;
    switch (status) {
      case 'active':
        color = Colors.green;
        text = 'Active';
        break;
      case 'banned':
        color = Colors.red;
        text = 'Banned';
        break;
      default:
        color = Colors.grey;
        text = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  void _handleUserAction(String action, Map<String, dynamic> user) async {
    final adminProvider = context.read<AdminProvider>();
    String message = '';

    switch (action) {
      case 'view':
        _showUserDetails(user);
        return;
      case 'promote':
        final isAdmin = user['role'] == 'admin';
        final success = isAdmin
            ? await adminProvider.demoteToUser(user['id'] ?? user['_id'])
            : await adminProvider.promoteToAdmin(user['id'] ?? user['_id']);
        message = success
            ? isAdmin
                ? 'Đã hạ quyền ${user['name']} xuống User'
                : 'Đã nâng quyền ${user['name']} lên Admin'
            : 'Không thể cập nhật quyền ${user['name']}';
        break;
      case 'ban':
        final isBanned = user['status'] == 'banned';
        final success = isBanned
            ? await adminProvider.unbanUser(user['id'] ?? user['_id'])
            : await adminProvider.banUser(user['id'] ?? user['_id']);
        message = success
            ? isBanned
                ? 'Đã mở khóa ${user['name']}'
                : 'Đã khóa ${user['name']}'
            : 'Không thể cập nhật ${user['name']}';
        break;
      case 'delete':
        final success =
            await adminProvider.deleteUser(user['id'] ?? user['_id']);
        message =
            success ? 'Đã xóa ${user['name']}' : 'Lỗi khi xóa ${user['name']}';
        break;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  void _showUserDetails(Map<String, dynamic> user) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user['name']?.toString() ?? 'Chi tiết người dùng'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.email_outlined),
              title: const Text('Email'),
              subtitle: Text(user['email']?.toString() ?? 'Chưa cập nhật'),
            ),
            ListTile(
              leading: const Icon(Icons.badge_outlined),
              title: const Text('Vai trò'),
              subtitle: Text(user['role']?.toString() ?? 'user'),
            ),
            ListTile(
              leading: const Icon(Icons.verified_user_outlined),
              title: const Text('Trạng thái'),
              subtitle: Text(user['status']?.toString() ?? 'unknown'),
            ),
            ListTile(
              leading: const Icon(Icons.star_outline),
              title: const Text('Tổng XP'),
              subtitle: Text(user['totalXP']?.toString() ?? '0'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
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
