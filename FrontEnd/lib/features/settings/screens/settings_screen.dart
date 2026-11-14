import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/localization/locale_provider.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/theme_provider.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/content_pane.dart';
import '../../auth/providers/auth_provider.dart';
import '../../streaks/widgets/streak_settings_sheet.dart';
import '../models/user_settings.dart';
import '../providers/settings_provider.dart';
import '../widgets/settings_info_dialogs.dart';
import '../widgets/settings_tiles.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SettingsProvider(),
      child: const _SettingsView(),
    );
  }
}

class _SettingsView extends StatefulWidget {
  const _SettingsView();

  @override
  State<_SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<_SettingsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final error = await context.read<SettingsProvider>().load();
    if (error == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Không tải được cài đặt: $error'),
        action: SnackBarAction(label: 'Thử lại', onPressed: _load),
      ),
    );
  }

  Future<void> _save() async {
    final provider = context.read<SettingsProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final savedText = AppLocalizations.of(context).settingsSaved;
    final error = await provider.save(theme: ThemeProvider.valueOf(context.read<ThemeProvider>().mode));
    messenger.showSnackBar(
      SnackBar(
        content: Text(error ?? savedText),
        backgroundColor: error == null ? AppColors.successStrong : AppColors.errorStrong,
      ),
    );
  }

  Future<void> _changeLanguage(String language) async {
    final provider = context.read<SettingsProvider>();
    provider.update((current) => current.copyWith(language: language));
    // Áp dụng ngôn ngữ ngay, rồi tự lưu nếu đã có cài đặt thật để lưu.
    await context.read<LocaleProvider>().setLanguage(language);
    if (mounted && provider.canSave) await _save();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final themeProvider = context.watch<ThemeProvider>();
    final provider = context.watch<SettingsProvider>();
    final settings = provider.settings;
    final l10n = AppLocalizations.of(context);

    // Chưa tải được cài đặt thật thì công tắc mờ đi.
    ValueChanged<bool>? toggle(UserSettings Function(UserSettings current, bool value) change) =>
        provider.isLoaded ? (value) => provider.update((current) => change(current, value)) : null;

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
            SettingsSwitchTile(
              title: l10n.enableNotifications,
              subtitle: l10n.receiveNotifications,
              value: settings.notificationsEnabled,
              onChanged: toggle((current, value) => current.copyWith(notificationsEnabled: value)),
            ),
            SettingsSwitchTile(
              title: l10n.sound,
              subtitle: l10n.playSoundNotification,
              value: settings.soundEnabled,
              onChanged: toggle((current, value) => current.copyWith(soundEnabled: value)),
            ),
            SettingsSwitchTile(
              title: l10n.vibrate,
              subtitle: l10n.vibrateNotification,
              value: settings.vibrateEnabled,
              onChanged: toggle((current, value) => current.copyWith(vibrateEnabled: value)),
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
                if (value != null) _changeLanguage(value);
              },
            ),
            // Đổi ngay và lưu trên máy, không chờ nút Lưu: mất mạng không được
            // làm hỏng việc đổi giao diện.
            _DropdownTile<ThemeMode>(
              title: l10n.interface,
              value: themeProvider.mode,
              items: [
                DropdownMenuItem(value: ThemeMode.light, child: Text(l10n.light)),
                DropdownMenuItem(value: ThemeMode.dark, child: Text(l10n.dark)),
                DropdownMenuItem(value: ThemeMode.system, child: Text(l10n.auto)),
              ],
              onChanged: (value) {
                if (value != null) themeProvider.setMode(value);
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
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: ElevatedButton(
                onPressed: provider.canSave ? _save : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: const RoundedRectangleBorder(borderRadius: AppRadius.smAll),
                ),
                child: provider.isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        l10n.saveSettings,
                        style: const TextStyle(fontSize: AppTypography.body, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
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
