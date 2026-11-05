import 'package:flutter/material.dart';
import '../providers/study_group_provider.dart';
import '../../../app/theme/app_tokens.dart';
import '../models/study_group.dart';

/// Tab thông tin chung và số liệu hoạt động.
class GroupInfoTab extends StatelessWidget {
  const GroupInfoTab({
    super.key,
    required this.group,
    required this.provider,
  });

  final StudyGroup group;
  final StudyGroupProvider provider;

  @override
  Widget build(BuildContext context) {
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
        _buildInfoRow(context, Icons.calendar_today, 'Ngày tạo',
            _formatDate(group.createdAt)),
        _buildInfoRow(context, Icons.person, 'Người tạo',
            group.creatorName ?? group.creatorUsername ?? 'Unknown'),
        _buildInfoRow(context, Icons.people, 'Số thành viên',
            '${group.memberCount}/${group.maxMembers}'),
        if (stats != null) ...[
          const SizedBox(height: 24),
          const Text(
            'Thống kê hoạt động',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildStatsCard(context, stats),
        ],
      ],
    );
  }

  Widget _buildInfoRow(
      BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: context.colors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style:
                  TextStyle(fontSize: 14, color: context.colors.textSecondary),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context, GroupStats stats) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(context, 'Tin nhắn',
                    stats.totalMessages.toString(), Icons.message),
                _buildStatItem(context, 'Hôm nay',
                    stats.todayMessages.toString(), Icons.today),
                _buildStatItem(context, 'Hoạt động',
                    stats.activeMembers.toString(), Icons.people_alt),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
      BuildContext context, String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 32, color: context.colors.readable(Colors.blue)),
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
          style: TextStyle(fontSize: 12, color: context.colors.textSecondary),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
