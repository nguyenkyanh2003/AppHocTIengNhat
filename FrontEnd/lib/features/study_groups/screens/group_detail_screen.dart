import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/providers/auth_provider.dart';
import '../providers/study_group_provider.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/content_pane.dart';

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

        if (groupProvider.isLoading && group == null) {
          return const AppScaffold(
            title: 'Chi tiết nhóm',
            body: ContentWidthLimit(
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (group == null) {
          return const AppScaffold(
            title: 'Chi tiết nhóm',
            body: ContentWidthLimit(
              child: Center(child: Text('Không tìm thấy nhóm')),
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
                  onPressed: () => _showGroupSettings(group),
                  tooltip: 'Cài đặt nhóm',
                ),
            ],
          ),
          body: ContentWidthLimit(
            child: Column(
              children: [
                _buildGroupHeader(group, isMember, isAdmin, isCreator),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
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
                    labelColor: Colors.blue[700],
                    unselectedLabelColor: Colors.grey[600],
                    indicatorColor: Colors.blue[700],
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
                      color: Colors.blue[50],
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.blue[700]!,
                          width: 3,
                        ),
                      ),
                    ),
                    tabs: const [
                      Tab(
                        height: 60,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.info_outline, size: 22),
                            SizedBox(height: 4),
                            Text('Thông tin'),
                          ],
                        ),
                      ),
                      Tab(
                        height: 60,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 22),
                            SizedBox(height: 4),
                            Text('Thành viên'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildInfoTab(group, groupProvider),
                      _buildMembersTab(
                          group, currentUserId, isAdmin, isCreator),
                    ],
                  ),
                ),
                // Thanh hành động của nhóm nằm trong thân trang, không phải
                // `bottomNavigationBar` — chỗ đó là của `AppShell`.
                // `_buildBottomBar` trả `null` khi không có hành động nào
                // hợp lệ với vai trò hiện tại.
                ...[
                  _buildBottomBar(
                    group,
                    isMember,
                    isCreator,
                    currentUserId ?? '',
                  ),
                ].whereType<Widget>(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGroupHeader(group, bool isMember, bool isAdmin, bool isCreator) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[50]!, Colors.blue[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(bottom: BorderSide(color: Colors.blue[200]!, width: 2)),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 38,
              backgroundImage: NetworkImage(group.avatar ?? ''),
              backgroundColor: Colors.grey[300],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        group.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    if (group.isPrivate)
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.lock,
                          size: 18,
                          color: Colors.orange[700],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[700],
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.school,
                              size: 14, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            group.levelDisplay,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue[300]!),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.people, size: 14, color: Colors.blue[700]),
                          const SizedBox(width: 4),
                          Text(
                            group.memberCountDisplay,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isCreator)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.amber[600]!, Colors.orange[600]!],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withValues(alpha: 0.4),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star, size: 14, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'Quản lý',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (isAdmin)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green[600],
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.shield, size: 14, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'Admin',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
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

  Widget _buildInfoTab(group, StudyGroupProvider provider) {
    final stats = provider.currentGroupStats;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (group.description != null && group.description!.isNotEmpty) ...[
          const Text(
            'Mô tả',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            group.description!,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 24),
        ],
        const Text(
          'Thông tin nhóm',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildInfoRow(
            Icons.calendar_today, 'Ngày tạo', _formatDate(group.createdAt)),
        _buildInfoRow(Icons.person, 'Người tạo',
            group.creatorName ?? group.creatorUsername ?? 'Unknown'),
        _buildInfoRow(Icons.people, 'Số thành viên',
            '${group.memberCount}/${group.maxMembers}'),
        if (stats != null) ...[
          const SizedBox(height: 24),
          const Text(
            'Thống kê hoạt động',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildStatsCard(stats),
        ],
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(stats) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                    'Tin nhắn', stats.totalMessages.toString(), Icons.message),
                _buildStatItem(
                    'Hôm nay', stats.todayMessages.toString(), Icons.today),
                _buildStatItem('Hoạt động', stats.activeMembers.toString(),
                    Icons.people_alt),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Colors.blue),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildMembersTab(
      group, String? currentUserId, bool isAdmin, bool isCreator) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: group.members.length,
      itemBuilder: (context, index) {
        final member = group.members[index];
        final isCurrentUser = member.userId == currentUserId;
        final isMemberAdmin = member.isAdmin;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage:
                  member.avatar != null ? NetworkImage(member.avatar!) : null,
              backgroundColor: Colors.grey[300],
              child: member.avatar == null
                  ? Text(
                      (member.fullName ?? member.username ?? 'U')[0]
                          .toUpperCase(),
                    )
                  : null,
            ),
            title: Text(
              member.fullName ?? member.username ?? 'User',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              member.email ?? '',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isMemberAdmin)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Admin',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                if (isAdmin && !isCurrentUser)
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      if (!isMemberAdmin)
                        const PopupMenuItem(
                          value: 'promote',
                          child: Row(
                            children: [
                              Icon(Icons.arrow_upward, size: 18),
                              SizedBox(width: 8),
                              Text('Promote lên Admin'),
                            ],
                          ),
                        ),
                      if (isMemberAdmin && isCreator)
                        const PopupMenuItem(
                          value: 'demote',
                          child: Row(
                            children: [
                              Icon(Icons.arrow_downward, size: 18),
                              SizedBox(width: 8),
                              Text('Demote về Member'),
                            ],
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'kick',
                        child: Row(
                          children: [
                            Icon(Icons.remove_circle,
                                size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Kick khỏi nhóm',
                                style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) => _handleMemberAction(
                      value.toString(),
                      member.userId,
                      member.fullName ?? 'thành viên',
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget? _buildBottomBar(
      group, bool isMember, bool isCreator, String currentUserId) {
    if (isMember) {
      if (isCreator) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: () => _confirmDeleteGroup(group.id),
            icon: const Icon(Icons.delete),
            label: const Text('Xóa nhóm'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        );
      } else {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: () => _confirmLeaveGroup(group.id),
            icon: const Icon(Icons.exit_to_app),
            label: const Text('Rời nhóm'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        );
      }
    } else {
      if (group.isFull()) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('Nhóm đã đầy'),
          ),
        );
      }
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: () => _joinGroup(group.id),
          icon: const Icon(Icons.add),
          label: const Text('Tham gia nhóm'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      );
    }
  }

  void _handleMemberAction(
      String action, String userId, String userName) async {
    final provider = Provider.of<StudyGroupProvider>(context, listen: false);
    bool success = false;

    switch (action) {
      case 'promote':
        success = await provider.promoteMember(widget.groupId, userId);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đã promote $userName lên Admin')),
          );
        }
        break;
      case 'demote':
        success = await provider.demoteMember(widget.groupId, userId);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đã demote $userName về Member')),
          );
        }
        break;
      case 'kick':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Xác nhận'),
            content: Text('Bạn có chắc muốn kick $userName khỏi nhóm?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Kick'),
              ),
            ],
          ),
        );
        if (confirm == true) {
          success = await provider.kickMember(widget.groupId, userId);
          if (success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Đã kick $userName khỏi nhóm')),
            );
          }
        }
        break;
    }
  }

  void _joinGroup(String groupId) async {
    final provider = Provider.of<StudyGroupProvider>(context, listen: false);
    final success = await provider.joinGroup(groupId);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã tham gia nhóm thành công!')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Lỗi khi tham gia nhóm')),
      );
    }
  }

  void _confirmLeaveGroup(String groupId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận rời nhóm'),
        content: const Text('Bạn có chắc muốn rời khỏi nhóm này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Rời nhóm'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (confirm == true) {
      final provider = context.read<StudyGroupProvider>();
      final navigator = Navigator.of(context);
      final messenger = ScaffoldMessenger.of(context);
      final success = await provider.leaveGroup(groupId);

      if (success && mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Đã rời nhóm')),
        );
        navigator.pop();
      }
    }
  }

  void _confirmDeleteGroup(String groupId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa nhóm'),
        content: const Text(
          'Bạn có chắc muốn xóa nhóm này? Hành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (confirm == true) {
      final provider = context.read<StudyGroupProvider>();
      final navigator = Navigator.of(context);
      final messenger = ScaffoldMessenger.of(context);
      final success = await provider.deleteGroup(groupId);

      if (success && mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Đã xóa nhóm')),
        );
        navigator.pop();
      }
    }
  }

  void _showGroupSettings(group) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Cài đặt nhóm',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.edit, color: Colors.blue[700]),
              ),
              title: const Text(
                'Chỉnh sửa thông tin',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: const Text('Sửa tên, mô tả, cấp độ nhóm'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(context);
                _showEditGroupDialog(group);
              },
            ),
            const Divider(),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.notifications, color: Colors.orange[700]),
              ),
              title: const Text(
                'Cài đặt thông báo',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: const Text('Quản lý thông báo từ nhóm'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(context);
                _showNotificationSettings(group);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showEditGroupDialog(group) {
    final nameController = TextEditingController(text: group.name);
    final descController = TextEditingController(text: group.description ?? '');
    String selectedLevel = group.level;
    int maxMembers = group.maxMembers;
    bool isPrivate = group.isPrivate;
    Uint8List? selectedImageBytes;
    String? selectedImageName;
    final ImagePicker picker = ImagePicker();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.edit, color: Colors.blue[700]),
              const SizedBox(width: 8),
              const Text('Chỉnh sửa thông tin nhóm'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar picker
                Center(
                  child: GestureDetector(
                    onTap: () async {
                      final XFile? image = await picker.pickImage(
                        source: ImageSource.gallery,
                        maxWidth: 512,
                        maxHeight: 512,
                        imageQuality: 80,
                      );
                      if (image != null) {
                        final bytes = await image.readAsBytes();
                        setState(() {
                          selectedImageBytes = bytes;
                          selectedImageName = image.name;
                        });
                      }
                    },
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: selectedImageBytes != null
                              ? MemoryImage(selectedImageBytes!)
                              : (group.avatar != null
                                  ? NetworkImage(group.avatar!)
                                  : null) as ImageProvider?,
                          backgroundColor: Colors.grey[300],
                          child:
                              selectedImageBytes == null && group.avatar == null
                                  ? Icon(Icons.group,
                                      size: 40, color: Colors.grey[600])
                                  : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.blue[700],
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Nhấn để thay đổi ảnh nhóm',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  autofocus: true,
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Tên nhóm *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.group),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  decoration: InputDecoration(
                    labelText: 'Mô tả',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.description),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedLevel,
                  decoration: InputDecoration(
                    labelText: 'Cấp độ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.school),
                  ),
                  items: ['ALL', 'N5', 'N4', 'N3', 'N2', 'N1']
                      .map((level) => DropdownMenuItem(
                            value: level,
                            child: Text(level == 'ALL'
                                ? 'Tất cả cấp độ'
                                : 'JLPT $level'),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedLevel = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: maxMembers.toString(),
                  decoration: InputDecoration(
                    labelText: 'Số thành viên tối đa',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.people),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final num = int.tryParse(value);
                    if (num != null && num >= 2 && num <= 500) {
                      maxMembers = num;
                    }
                  },
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Nhóm riêng tư'),
                  subtitle:
                      const Text('Chỉ thành viên được mời mới có thể tham gia'),
                  value: isPrivate,
                  onChanged: (value) {
                    setState(() => isPrivate = value);
                  },
                  secondary: const Icon(Icons.lock),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng nhập tên nhóm')),
                  );
                  return;
                }

                final provider = this.context.read<StudyGroupProvider>();

                // Upload avatar if selected
                if (selectedImageBytes != null) {
                  final avatarSuccess = await provider.uploadGroupAvatar(
                    group.id,
                    selectedImageBytes!,
                    selectedImageName!,
                  );

                  if (!mounted || !context.mounted) return;
                  if (!avatarSuccess) {
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(
                          content:
                              Text(provider.error ?? 'Lỗi khi upload avatar')),
                    );
                    return;
                  }
                }

                final success = await provider.updateGroup(
                  groupId: group.id,
                  name: nameController.text.trim(),
                  description: descController.text.trim(),
                  level: selectedLevel,
                  isPrivate: isPrivate,
                  maxMembers: maxMembers,
                );

                if (!mounted || !context.mounted) return;
                if (success) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(content: Text('Đã cập nhật thông tin nhóm')),
                  );
                  provider.loadGroupDetail(group.id);
                } else {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(
                        content:
                            Text(provider.error ?? 'Lỗi khi cập nhật nhóm')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
              ),
              child: const Text('Lưu thay đổi'),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotificationSettings(group) async {
    // Load settings from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final groupId = group.id;

    bool notifyNewMessage = prefs.getBool('notify_message_$groupId') ?? true;
    bool notifyMemberJoin = prefs.getBool('notify_join_$groupId') ?? true;
    bool notifyMemberLeave = prefs.getBool('notify_leave_$groupId') ?? false;

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.notifications, color: Colors.orange[700]),
              const SizedBox(width: 8),
              const Text('Cài đặt thông báo'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('Tin nhắn mới'),
                subtitle: const Text('Nhận thông báo khi có tin nhắn mới'),
                value: notifyNewMessage,
                onChanged: (value) {
                  setState(() => notifyNewMessage = value);
                },
                secondary: const Icon(Icons.message),
              ),
              const Divider(),
              SwitchListTile(
                title: const Text('Thành viên mới'),
                subtitle: const Text('Nhận thông báo khi có người tham gia'),
                value: notifyMemberJoin,
                onChanged: (value) {
                  setState(() => notifyMemberJoin = value);
                },
                secondary: const Icon(Icons.person_add),
              ),
              const Divider(),
              SwitchListTile(
                title: const Text('Thành viên rời nhóm'),
                subtitle: const Text('Nhận thông báo khi có người rời đi'),
                value: notifyMemberLeave,
                onChanged: (value) {
                  setState(() => notifyMemberLeave = value);
                },
                secondary: const Icon(Icons.person_remove),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Save to SharedPreferences
                final prefs = await SharedPreferences.getInstance();
                final groupId = group.id;

                await prefs.setBool(
                    'notify_message_$groupId', notifyNewMessage);
                await prefs.setBool('notify_join_$groupId', notifyMemberJoin);
                await prefs.setBool('notify_leave_$groupId', notifyMemberLeave);

                if (mounted && context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(content: Text('Đã lưu cài đặt thông báo')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[700],
              ),
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
