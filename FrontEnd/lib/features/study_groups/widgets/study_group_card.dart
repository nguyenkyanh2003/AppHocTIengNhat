import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/study_group_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../app/theme/app_tokens.dart';
import '../models/study_group.dart';

/// Một nhóm trong danh sách.
class StudyGroupCard extends StatelessWidget {
  const StudyGroupCard({
    super.key,
    required this.group,
    required this.isMyGroup,
  });

  final StudyGroup group;
  final bool isMyGroup;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = auth.user?.id;
    final isMember = currentUserId != null && group.isMember(currentUserId);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          context.push('/study-groups/${group.id}');
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Avatar lớn hơn
                  CircleAvatar(
                    radius: 32,
                    backgroundImage: group.avatar == null
                        ? null
                        : NetworkImage(group.avatar!),
                    backgroundColor: context.colors.surfaceVariant,
                    child: group.avatar == null
                        ? const Icon(Icons.groups_outlined)
                        : null,
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
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: context.colors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (group.isPrivate)
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.24),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  Icons.lock,
                                  size: 16,
                                  color: context.colors
                                      .readable(Colors.orange[700]!),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: Colors.blue.withValues(alpha: 0.4)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.school,
                                    size: 14,
                                    color: context.colors
                                        .readable(Colors.blue[700]!),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    group.levelDisplay,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: context.colors
                                          .readable(Colors.blue[700]!),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.people,
                                size: 16, color: context.colors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              group.memberCountDisplay,
                              style: TextStyle(
                                fontSize: 13,
                                color: context.colors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!isMember)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.blue[700],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.add, color: Colors.white),
                        onPressed: () => _joinGroup(context, group.id),
                        tooltip: 'Tham gia',
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.green.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle,
                              size: 16,
                              color:
                                  context.colors.readable(Colors.green[700]!)),
                          const SizedBox(width: 4),
                          Text(
                            'Đã tham gia',
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  context.colors.readable(Colors.green[700]!),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              if (group.description != null &&
                  group.description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: context.colors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    group.description!,
                    style: TextStyle(
                      fontSize: 14,
                      color: context.colors.textSecondary,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _joinGroup(BuildContext context, String groupId) async {
    final hostContext = context;
    final provider = Provider.of<StudyGroupProvider>(context, listen: false);
    final success = await provider.joinGroup(groupId);

    if (success && hostContext.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã tham gia nhóm thành công!')),
      );
      provider.loadAllGroups(refresh: true);
    } else if (hostContext.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Lỗi khi tham gia nhóm')),
      );
    }
  }
}
