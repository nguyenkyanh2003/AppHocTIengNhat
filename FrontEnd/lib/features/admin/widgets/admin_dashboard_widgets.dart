import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../models/admin_dashboard_summary.dart';

/// Một số liệu trên nền đầu trang.
class AdminStatTile extends StatelessWidget {
  const AdminStatTile({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: const TextStyle(
              fontSize: AppTypography.headline,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: AppTypography.caption,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}

/// Ô dẫn sang một màn quản trị.
class AdminActionCard extends StatelessWidget {
  const AdminActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 28, color: context.colors.readable(color)),
              const SizedBox(height: AppSpacing.sm),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: AppTypography.body,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: AppTypography.caption,
                  color: context.colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Một sự kiện gần đây.
class AdminActivityTile extends StatelessWidget {
  const AdminActivityTile({super.key, required this.activity, this.now});

  final AdminActivity activity;

  /// Chỉ test truyền vào để cố định thời điểm.
  final DateTime? now;

  String _ago() {
    final elapsed = (now ?? DateTime.now()).difference(activity.at);
    if (elapsed.inMinutes < 1) return 'Vừa xong';
    if (elapsed.inHours < 1) return '${elapsed.inMinutes} phút trước';
    if (elapsed.inDays < 1) return '${elapsed.inHours} giờ trước';
    return '${elapsed.inDays} ngày trước';
  }

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (activity.kind) {
      AdminActivityKind.newUser => (Icons.person_add_alt, AppColors.primary),
      AdminActivityKind.newReport => (Icons.flag_outlined, AppColors.warning),
    };

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.2),
          child: Icon(icon, color: context.colors.readable(color), size: 20),
        ),
        title: Text(
          activity.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${activity.subtitle} · ${_ago()}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
