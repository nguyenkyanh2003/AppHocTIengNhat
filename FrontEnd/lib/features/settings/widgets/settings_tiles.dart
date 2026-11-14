import 'package:flutter/material.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/models/user.dart';

/// Tiêu đề một nhóm cài đặt.
class SettingsSectionHeader extends StatelessWidget {
  const SettingsSectionHeader({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: AppTypography.bodySmall,
          fontWeight: FontWeight.bold,
          color: context.colors.textSecondary,
        ),
      ),
    );
  }
}

/// Dòng tên người dùng.
class SettingsUserInfoTile extends StatelessWidget {
  const SettingsUserInfoTile({
    super.key,
    required this.user,
  });

  final User? user;

  @override
  Widget build(BuildContext context) {
    final user = this.user;
    return ListTile(
      leading: CircleAvatar(
        backgroundImage:
            user?.avatar != null ? NetworkImage(user!.avatar!) : null,
        child: user?.avatar == null ? const Icon(Icons.person) : null,
      ),
      title: Text(user?.fullName ?? 'Người dùng'),
      subtitle: Text(user?.email ?? ''),
    );
  }
}

/// Một cài đặt bật tắt.
class SettingsSwitchTile extends StatelessWidget {
  const SettingsSwitchTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;

  /// `null` thì công tắc mờ đi (chưa tải được cài đặt thật).
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: context.colors.primary,
      ),
    );
  }
}

/// Một dòng dẫn sang màn khác.
class SettingsMenuTile extends StatelessWidget {
  const SettingsMenuTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: context.colors.primary),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
