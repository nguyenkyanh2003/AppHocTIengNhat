import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';

/// Ngày dạng d/m/yyyy; chưa có thì hiện [missing].
String profileDate(DateTime? value, {String missing = 'Chưa cập nhật'}) =>
    value == null ? missing : '${value.day}/${value.month}/${value.year}';

/// Một nhóm thông tin trên trang hồ sơ.
class ProfileInfoCard extends StatelessWidget {
  const ProfileInfoCard({super.key, required this.title, required this.rows});

  final String title;
  final List<ProfileInfoRow> rows;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
      child: Padding(
        padding: AppSpacing.page,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: AppTypography.subtitle,
                fontWeight: FontWeight.w600,
                color: context.colors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ...rows,
          ],
        ),
      ),
    );
  }
}

/// Một dòng nhãn – giá trị có biểu tượng.
class ProfileInfoRow extends StatelessWidget {
  const ProfileInfoRow(this.icon, this.label, this.value, {super.key});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(color: context.colors.primarySoft, borderRadius: AppRadius.smAll),
            child: Icon(icon, size: 20, color: context.colors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: AppTypography.caption, color: context.colors.textSecondary)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: AppTypography.body, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
