import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../providers/study_group_provider.dart';
import '../../providers/group_chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/group_message.dart';

class GroupDetailScreen extends StatefulWidget {
  final String groupId;

  const GroupDetailScreen({Key? key, required this.groupId}) : super(key: key);

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final groupProvider = Provider.of<StudyGroupProvider>(context, listen: false);
      final chatProvider = Provider.of<GroupChatProvider>(context, listen: false);
      groupProvider.loadGroupDetail(widget.groupId);
      chatProvider.setCurrentGroup(widget.groupId);
      chatProvider.loadMessages(groupId: widget.groupId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<StudyGroupProvider, AuthProvider, GroupChatProvider>(
      builder: (context, groupProvider, authProvider, chatProvider, child) {
        final group = groupProvider.currentGroup;
        final currentUserId = authProvider.user?.id;

        if (groupProvider.isLoading && group == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Chi tiết nhóm')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (group == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Chi tiết nhóm')),
            body: const Center(child: Text('Không tìm thấy nhóm')),
          );
        }

        final isMember = currentUserId != null && group.isMember(currentUserId);
        final isAdmin = currentUserId != null && group.isAdmin(currentUserId);
        final isCreator = currentUserId != null && group.isCreator(currentUserId);

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
          body: Column(
            children: [
              _buildGroupHeader(group, isMember, isAdmin, isCreator),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
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
                    Tab(
                      height: 60,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 22),
                          SizedBox(height: 4),
                          Text('Chat'),
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
                    _buildMembersTab(group, currentUserId, isAdmin, isCreator),
                    isMember
                        ? _buildChatTab(group, chatProvider)
                        : const Center(
                            child: Text(
                              'Bạn cần tham gia nhóm để chat',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: _buildBottomBar(
            group,
            isMember,
            isCreator,
            currentUserId ?? '',
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
                  color: Colors.black.withOpacity(0.1),
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
                            color: Colors.blue.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.school, size: 14, color: Colors.white),
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
                              color: Colors.orange.withOpacity(0.4),
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
                              color: Colors.green.withOpacity(0.3),
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
        _buildInfoRow(Icons.calendar_today, 'Ngày tạo',
            _formatDate(group.createdAt)),
        _buildInfoRow(Icons.person, 'Người tạo',
            group.creatorName ?? group.creatorUsername ?? 'Unknown'),
        _buildInfoRow(Icons.people, 'Số thành viên', '${group.memberCount}/${group.maxMembers}'),
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
                _buildStatItem('Tin nhắn', stats.totalMessages.toString(), Icons.message),
                _buildStatItem('Hôm nay', stats.todayMessages.toString(), Icons.today),
                _buildStatItem('Hoạt động', stats.activeMembers.toString(), Icons.people_alt),
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

  Widget _buildMembersTab(group, String? currentUserId, bool isAdmin, bool isCreator) {
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
              backgroundImage: member.avatar != null
                  ? NetworkImage(member.avatar!)
                  : null,
              backgroundColor: Colors.grey[300],
              child: member.avatar == null
                  ? Text(
                      (member.fullName ?? member.username ?? 'U')[0].toUpperCase(),
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
                            Icon(Icons.remove_circle, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Kick khỏi nhóm', style: TextStyle(color: Colors.red)),
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

  Widget? _buildBottomBar(group, bool isMember, bool isCreator, String currentUserId) {
    if (isMember) {
      if (isCreator) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
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
                color: Colors.grey.withOpacity(0.3),
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
              color: Colors.grey.withOpacity(0.3),
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

  void _handleMemberAction(String action, String userId, String userName) async {
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

    if (confirm == true) {
      final provider = Provider.of<StudyGroupProvider>(context, listen: false);
      final success = await provider.leaveGroup(groupId);

      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã rời nhóm')),
        );
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

    if (confirm == true) {
      final provider = Provider.of<StudyGroupProvider>(context, listen: false);
      final success = await provider.deleteGroup(groupId);

      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa nhóm')),
        );
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
                          child: selectedImageBytes == null && group.avatar == null
                              ? Icon(Icons.group, size: 40, color: Colors.grey[600])
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
                            child: Text(level == 'ALL' ? 'Tất cả cấp độ' : 'JLPT $level'),
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
                  subtitle: const Text('Chỉ thành viên được mời mới có thể tham gia'),
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

                final provider = Provider.of<StudyGroupProvider>(context, listen: false);
                
                // Upload avatar if selected
                if (selectedImageBytes != null) {
                  final avatarSuccess = await provider.uploadGroupAvatar(
                    group.id, 
                    selectedImageBytes!, 
                    selectedImageName!,
                  );
                  
                  if (!avatarSuccess && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(provider.error ?? 'Lỗi khi upload avatar')),
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

                if (success && mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã cập nhật thông tin nhóm')),
                  );
                  provider.loadGroupDetail(group.id);
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(provider.error ?? 'Lỗi khi cập nhật nhóm')),
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

  void _showNotificationSettings(group) {
    bool notifyNewMessage = true; // TODO: Load from SharedPreferences
    bool notifyMemberJoin = true;
    bool notifyMemberLeave = false;

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
              onPressed: () {
                // TODO: Save to SharedPreferences
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã lưu cài đặt thông báo')),
                );
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

  // Chat Tab - Tích hợp chat trực tiếp vào group detail
  Widget _buildChatTab(group, GroupChatProvider chatProvider) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final messages = chatProvider.getMessages(widget.groupId);
    final isLoading = chatProvider.isLoading(widget.groupId);
    final replyToMessage = chatProvider.replyToMessage;

    return Column(
      children: [
        // Message list
        Expanded(
          child: isLoading && messages.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'Chưa có tin nhắn nào',
                            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Hãy bắt đầu cuộc trò chuyện!',
                            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final isMe = message.userId == auth.user?.id;
                        return _buildMessageBubble(message, isMe, chatProvider);
                      },
                    ),
        ),
        // Reply preview
        if (replyToMessage != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              border: Border(top: BorderSide(color: Colors.blue[200]!)),
            ),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 40,
                  color: Colors.blue,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trả lời ${replyToMessage.displayName}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[700],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        replyToMessage.content,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => chatProvider.clearReply(),
                ),
              ],
            ),
          ),
        // Message input
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey[300]!)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Nhập tin nhắn...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(chatProvider),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white, size: 20),
                  onPressed: () => _sendMessage(chatProvider),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(GroupMessage message, bool isMe, GroupChatProvider chatProvider) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundImage: message.userAvatar != null
                  ? NetworkImage(message.userAvatar!)
                  : null,
              backgroundColor: Colors.grey[300],
              child: message.userAvatar == null
                  ? Text(
                      message.displayName[0].toUpperCase(),
                      style: const TextStyle(fontSize: 14),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: () => _showMessageOptions(message, isMe, chatProvider),
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4, left: 4),
                      child: Text(
                        message.displayName,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  // Reply quote
                  if (message.replyMessage != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isMe ? Colors.blue[100] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        border: const Border(
                          left: BorderSide(color: Colors.blue, width: 3),
                        ),
                      ),
                      child: Text(
                        message.replyMessage!.content,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  // Message content
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.blue : Colors.grey[200],
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(isMe ? 18 : 4),
                        topRight: Radius.circular(isMe ? 4 : 18),
                        bottomLeft: const Radius.circular(18),
                        bottomRight: const Radius.circular(18),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.content,
                          style: TextStyle(
                            fontSize: 15,
                            color: isMe ? Colors.white : Colors.black87,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              message.getTimeAgo(),
                              style: TextStyle(
                                fontSize: 11,
                                color: isMe ? Colors.white70 : Colors.grey[600],
                              ),
                            ),
                            if (message.isEdited) ...[
                              const SizedBox(width: 4),
                              Text(
                                '(đã sửa)',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isMe ? Colors.white70 : Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMessageOptions(GroupMessage message, bool isMe, GroupChatProvider chatProvider) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.reply, color: Colors.blue),
              title: const Text('Trả lời'),
              onTap: () {
                Navigator.pop(context);
                chatProvider.setReplyTo(message);
                _messageController.text = '';
                FocusScope.of(context).requestFocus(FocusNode());
              },
            ),
            if (isMe) ...[
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.orange),
                title: const Text('Chỉnh sửa'),
                onTap: () {
                  Navigator.pop(context);
                  _editMessage(message, chatProvider);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Xóa'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteMessage(message, chatProvider);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _sendMessage(GroupChatProvider chatProvider) async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    _messageController.clear();
    final success = await chatProvider.sendMessage(
      groupId: widget.groupId,
      content: content,
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lỗi khi gửi tin nhắn')),
      );
    }
  }

  void _editMessage(GroupMessage message, GroupChatProvider chatProvider) {
    final controller = TextEditingController(text: message.content);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chỉnh sửa tin nhắn'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Nội dung tin nhắn',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newContent = controller.text.trim();
              if (newContent.isNotEmpty && newContent != message.content) {
                final success = await chatProvider.editMessage(
                  groupId: widget.groupId,
                  messageId: message.id,
                  content: newContent,
                );
                if (success && mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã cập nhật tin nhắn')),
                  );
                }
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _deleteMessage(GroupMessage message, GroupChatProvider chatProvider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc muốn xóa tin nhắn này?'),
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

    if (confirm == true) {
      final success = await chatProvider.deleteMessage(
        groupId: widget.groupId,
        messageId: message.id,
      );
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa tin nhắn')),
        );
      }
    }
  }
}
