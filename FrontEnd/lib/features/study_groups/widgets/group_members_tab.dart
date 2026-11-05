import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/study_group_provider.dart';
import '../../../app/theme/app_tokens.dart';
import '../models/study_group.dart';

/// Tab danh sách thành viên và thao tác phân quyền.
class GroupMembersTab extends StatelessWidget {
  const GroupMembersTab({
    super.key,
    required this.group,
    required this.currentUserId,
    required this.isAdmin,
    required this.isCreator,
    required this.groupId,
  });

  final StudyGroup group;
  final String? currentUserId;
  final bool isAdmin;
  final bool isCreator;
  final String groupId;

  @override
  Widget build(BuildContext context) {
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
              backgroundColor: context.colors.surfaceVariant,
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
                      color: Colors.blue.withValues(alpha: 0.24),
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
                      PopupMenuItem(
                        value: 'kick',
                        child: Row(
                          children: [
                            Icon(Icons.remove_circle,
                                size: 18,
                                color: context.colors.readable(Colors.red)),
                            const SizedBox(width: 8),
                            Text('Kick khỏi nhóm',
                                style: TextStyle(
                                    color:
                                        context.colors.readable(Colors.red))),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) => _handleMemberAction(
                      context,
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

  void _handleMemberAction(BuildContext context, String action, String userId,
      String userName) async {
    final hostContext = context;
    final provider = Provider.of<StudyGroupProvider>(context, listen: false);
    bool success = false;

    switch (action) {
      case 'promote':
        success = await provider.promoteMember(groupId, userId);
        if (success && hostContext.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đã promote $userName lên Admin')),
          );
        }
        break;
      case 'demote':
        success = await provider.demoteMember(groupId, userId);
        if (success && hostContext.mounted) {
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
          success = await provider.kickMember(groupId, userId);
          if (success && hostContext.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Đã kick $userName khỏi nhóm')),
            );
          }
        }
        break;
    }
  }
}
