import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/localization/locale_provider.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/theme_provider.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/content_pane.dart';
import '../../auth/providers/auth_provider.dart';
import '../../streaks/widgets/streak_settings_sheet.dart';
import '../models/user_settings.dart';
import '../providers/settings_provider.dart';
import '../widgets/settings_info_dialogs.dart';
import '../widgets/settings_tiles.dart';

/// Cài đặt chung. Mọi lựa chọn có tác dụng ngay và tự lưu, không có nút Lưu;
/// ba công tắc thông báo nằm ở màn Cài đặt thông báo (một chỗ, không hai).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  /// Lưu lên tài khoản; chưa tải được cài đặt thì lựa chọn chỉ có tác dụng trên
  /// máy này (ngôn ngữ, giao diện vẫn đổi ngay), không lưu đè bằng mặc định.
  Future<void> _saveRemotely(BuildContext context, UserSettings Function(UserSettings current) edit) async {
    final provider = context.read<SettingsProvider>();
    if (!provider.isLoaded) return;
    final messenger = ScaffoldMessenger.of(context);
    final error = await provider.change(edit);
    if (error == null) return;
    messenger.showSnackBar(SnackBar(
      content: Text('Đã đổi trên máy này, chưa lưu được lên tài khoản: $error'),
      backgroundColor: AppColors.errorStrong,
    ));
  }

  Future<void> _changeLanguage(BuildContext context, String language) async {
    await context.read<LocaleProvider>().setLanguage(language);
    if (context.mounted) await _saveRemotely(context, (current) => current.copyWith(language: language));
  }

  Future<void> _changeTheme(BuildContext context, ThemeMode mode) async {
    await context.read<ThemeProvider>().setMode(mode);
    if (context.mounted) await _saveRemotely(context, (current) => current.copyWith(theme: ThemeProvider.valueOf(mode)));
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final themeMode = context.select<ThemeProvider, ThemeMode>((theme) => theme.mode);
    final settings = context.watch<SettingsProvider>().settings;
    final l10n = AppLocalizations.of(context);

    return AppScaffold(
      title: l10n.settings,
      body: ContentPaneList(
        maxWidth: AppContentWidth.dashboard,
        builder: (context, padding) => ListView(
          padding: padding,
          children: [
            SettingsSectionHeader(title: l10n.accountInfo),
            SettingsUserInfoTile(user: user),
            SettingsSectionHeader(title: l10n.notifications),
            SettingsMenuTile(
              icon: Icons.local_fire_department_outlined,
              title: l10n.dailyGoalAndReminder,
              onTap: () => showStreakSettingsSheet(context),
            ),
            SettingsMenuTile(
              icon: Icons.notifications_outlined,
              title: 'Thông báo, âm thanh, rung',
              subtitle: _notificationSummary(settings),
              onTap: () => context.push('/notification-settings'),
            ),
            SettingsSectionHeader(title: l10n.languageInterface),
            _DropdownTile<String>(
              title: l10n.language,
              value: settings.language,
              items: [
                DropdownMenuItem(value: 'vi', child: Text(l10n.vietnamese)),
                DropdownMenuItem(value: 'en', child: Text(l10n.english)),
                DropdownMenuItem(value: 'ja', child: Text(l10n.japanese)),
              ],
              onChanged: (value) {
                if (value != null) _changeLanguage(context, value);
              },
            ),
            // Giao diện do máy quyết định và đổi ngay, kể cả khi mất mạng.
            _DropdownTile<ThemeMode>(
              title: l10n.interface,
              value: themeMode,
              items: [
                DropdownMenuItem(value: ThemeMode.light, child: Text(l10n.light)),
                DropdownMenuItem(value: ThemeMode.dark, child: Text(l10n.dark)),
                DropdownMenuItem(value: ThemeMode.system, child: Text(l10n.auto)),
              ],
              onChanged: (value) {
                if (value != null) _changeTheme(context, value);
              },
            ),
            SettingsSectionHeader(title: l10n.other),
            SettingsMenuTile(
              icon: Icons.help_outline,
              title: l10n.helpFeedback,
              onTap: () => showSettingsHelpDialog(context),
            ),
            SettingsMenuTile(
              icon: Icons.privacy_tip_outlined,
              title: l10n.privacyPolicy,
              onTap: () => showSettingsPrivacyDialog(context),
            ),
            SettingsMenuTile(
              icon: Icons.info_outline,
              title: l10n.aboutApp,
              onTap: () => showSettingsAboutDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  static String _notificationSummary(UserSettings settings) {
    if (!settings.notificationsEnabled) return 'Đang tắt';
    final extras = [if (settings.soundEnabled) 'âm thanh', if (settings.vibrateEnabled) 'rung'];
    return extras.isEmpty ? 'Đang bật, không kêu, không rung' : 'Đang bật, có ${extras.join(' và ')}';
  }
}

class _DropdownTile<T> extends StatelessWidget {
  const _DropdownTile({required this.title, required this.value, required this.items, required this.onChanged});

  final String title;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      trailing: DropdownButton<T>(value: value, items: items, onChanged: onChanged),
    );
  }
}
