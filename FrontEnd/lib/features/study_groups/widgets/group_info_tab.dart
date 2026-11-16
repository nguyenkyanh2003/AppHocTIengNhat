import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../shared/widgets/async_view.dart';
import '../models/study_group.dart';
import '../providers/study_group_provider.dart';

/// Tab thông tin chung và số liệu hoạt động.
class GroupInfoTab extends StatelessWidget {
  const GroupInfoTab({super.key, required this.group});

  final StudyGroup group;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudyGroupProvider>();
    final createdAt = group.createdAt;

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
        if (createdAt != null) _buildInfoRow(context, Icons.calendar_today, 'Ngày tạo', _formatDate(createdAt)),
        _buildInfoRow(context, Icons.person, 'Người tạo', group.creatorName ?? group.creatorUsername ?? 'Không rõ'),
        _buildInfoRow(context, Icons.people, 'Số thành viên',
            '${group.memberCount}/${group.maxMembers}'),
        const SizedBox(height: 24),
        const Text(
          'Thống kê hoạt động',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        // Khối riêng: thống kê lỗi thì chỉ khối này báo lỗi, thông tin nhóm vẫn hiện.
        AsyncView<GroupStats>(
          state: provider.statsOf(group.id),
          compact: true,
          onRetry: () => provider.loadGroupDetail(group.id),
          builder: (context, stats) => _buildStatsCard(context, stats),
        ),
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
                _buildStatItem(context, 'Thành viên', '${stats.memberCount}', Icons.people),
                _buildStatItem(context, 'Quản trị', '${stats.adminCount}', Icons.admin_panel_settings),
                _buildStatItem(context, 'Hoạt động 24h', '${stats.activeMembers}', Icons.people_alt),
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
