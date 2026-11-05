import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/study_group_provider.dart';
import '../../../app/theme/app_tokens.dart';
import '../models/study_group.dart';

/// Nút tham gia, rời hoặc xoá nhóm ở cuối màn.
class GroupBottomBar extends StatelessWidget {
  const GroupBottomBar({
    super.key,
    required this.group,
    required this.isMember,
    required this.isCreator,
    required this.currentUserId,
  });

  final StudyGroup group;
  final bool isMember;
  final bool isCreator;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    if (isMember) {
      if (isCreator) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.colors.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: () => _confirmDeleteGroup(context, group.id),
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
            color: context.colors.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: () => _confirmLeaveGroup(context, group.id),
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
          color: context.colors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: () => _joinGroup(context, group.id),
          icon: const Icon(Icons.add),
          label: const Text('Tham gia nhóm'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      );
    }
  }

  void _joinGroup(BuildContext context, String groupId) async {
    final hostContext = context;
    final provider = Provider.of<StudyGroupProvider>(context, listen: false);
    final success = await provider.joinGroup(groupId);

    if (success && hostContext.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã tham gia nhóm thành công!')),
      );
    } else if (hostContext.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Lỗi khi tham gia nhóm')),
      );
    }
  }

  void _confirmLeaveGroup(BuildContext context, String groupId) async {
    final hostContext = context;
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

    if (!hostContext.mounted) return;
    if (confirm == true) {
      final provider = context.read<StudyGroupProvider>();
      final navigator = Navigator.of(context);
      final messenger = ScaffoldMessenger.of(context);
      final success = await provider.leaveGroup(groupId);

      if (success && hostContext.mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Đã rời nhóm')),
        );
        navigator.pop();
      }
    }
  }

  void _confirmDeleteGroup(BuildContext context, String groupId) async {
    final hostContext = context;
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

    if (!hostContext.mounted) return;
    if (confirm == true) {
      final provider = context.read<StudyGroupProvider>();
      final navigator = Navigator.of(context);
      final messenger = ScaffoldMessenger.of(context);
      final success = await provider.deleteGroup(groupId);

      if (success && hostContext.mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Đã xóa nhóm')),
        );
        navigator.pop();
      }
    }
  }
}
