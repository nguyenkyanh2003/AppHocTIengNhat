import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/content_pane.dart';
import '../models/user_settings.dart';
import '../providers/settings_provider.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SettingsProvider()..load(),
      child: const _NotificationSettingsView(),
    );
  }
}

class _NotificationSettingsView extends StatelessWidget {
  const _NotificationSettingsView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SettingsProvider>();
    return AppScaffold(
      title: 'Cài đặt thông báo',
      body: ContentWidthLimit(
        child: AsyncView<UserSettings>(
          state: provider.state,
          onRetry: provider.load,
          builder: (context, settings) => _SettingsList(settings: settings),
        ),
      ),
    );
  }
}

class _SettingsList extends StatelessWidget {
  const _SettingsList({required this.settings});

  final UserSettings settings;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SettingsProvider>();
    final enabled = settings.notificationsEnabled;

    return ListView(
      padding: AppSpacing.page,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: AppRadius.lgAll,
          ),
          child: Column(
            children: [
              Icon(
                enabled ? Icons.notifications_active : Icons.notifications_off_outlined,
                size: 52,
                color: enabled ? context.colors.primary : context.colors.textSecondary,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                enabled ? 'Thông báo đang bật' : 'Thông báo đang tắt',
                style: const TextStyle(fontSize: AppTypography.title, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.notifications_outlined),
                title: const Text('Nhận thông báo'),
                subtitle: const Text('Cho phép ứng dụng hiển thị thông báo trong tài khoản.'),
                value: enabled,
                onChanged: (value) => provider.update((current) => current.copyWith(notificationsEnabled: value)),
              ),
              const Divider(height: 1),
              SwitchListTile(
                secondary: const Icon(Icons.volume_up_outlined),
                title: const Text('Âm thanh'),
                subtitle: const Text('Phát âm báo khi có thông báo mới.'),
                value: settings.soundEnabled,
                onChanged: enabled ? (value) => provider.update((current) => current.copyWith(soundEnabled: value)) : null,
              ),
              const Divider(height: 1),
              SwitchListTile(
                secondary: const Icon(Icons.vibration),
                title: const Text('Rung'),
                subtitle: const Text('Rung thiết bị khi có thông báo mới.'),
                value: settings.vibrateEnabled,
                onChanged: enabled ? (value) => provider.update((current) => current.copyWith(vibrateEnabled: value)) : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: provider.canSave ? () => _save(context) : null,
          icon: provider.isSaving
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.save_outlined),
          label: Text(provider.isSaving ? 'Đang lưu...' : 'Lưu cài đặt'),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Ứng dụng chỉ hiển thị các tùy chọn đã được backend lưu và hỗ trợ. Lịch yên tĩnh, SMS và email định kỳ không nằm trong phạm vi phiên bản này.',
          textAlign: TextAlign.center,
          style: TextStyle(color: context.colors.textSecondary),
        ),
      ],
    );
  }

  Future<void> _save(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final error = await context.read<SettingsProvider>().save();
    messenger.showSnackBar(
      SnackBar(
        content: Text(error == null ? 'Đã lưu cài đặt thông báo.' : 'Không thể lưu cài đặt: $error'),
        backgroundColor: error == null ? AppColors.successStrong : AppColors.errorStrong,
      ),
    );
  }
}
