import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../streaks/widgets/streak_settings_sheet.dart';
import '../../../app/localization/locale_provider.dart';
import '../../../app/theme/theme_provider.dart';
import '../services/settings_service.dart';
import '../../../app/localization/app_localizations.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/content_pane.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../widgets/settings_info_dialogs.dart';
import '../widgets/settings_tiles.dart';
import '../../../core/state/view_state.dart';
import '../../auth/providers/auth_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settingsService = SettingsService();
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrateEnabled = true;
  String _selectedLanguage = 'vi';
  bool _isLoading = false;

  /// Chưa đọc được cài đặt thật thì không cho lưu: lưu lúc này sẽ ghi đè bằng giá
  /// trị mặc định trên màn hình.
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final response = await _settingsService.getSettings();
      if (mounted) setState(() => _loaded = true);
      if (response.isNotEmpty && mounted) {
        setState(() {
          _notificationsEnabled = response['notificationsEnabled'] ?? true;
          _soundEnabled = response['soundEnabled'] ?? true;
          _vibrateEnabled = response['vibrateEnabled'] ?? true;
          _selectedLanguage = response['language'] ?? 'vi';
        });
      }
    } catch (e) {
      debugPrint('Lỗi khi tải cài đặt: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không tải được cài đặt: ${userMessageOf(e)}'),
            action: SnackBarAction(label: 'Thử lại', onPressed: _loadSettings),
          ),
        );
      }
    }
  }

  Future<void> _saveSettings() async {
    if (!_loaded) return;
    setState(() => _isLoading = true);
    try {
      await _settingsService.saveSettings({
        'notificationsEnabled': _notificationsEnabled,
        'soundEnabled': _soundEnabled,
        'vibrateEnabled': _vibrateEnabled,
        'language': _selectedLanguage,
        'theme': ThemeProvider.valueOf(context.read<ThemeProvider>().mode),
      });

      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.settingsSaved),
            backgroundColor: AppColors.successStrong,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userMessageOf(e)),
            backgroundColor: AppColors.errorStrong,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final themeProvider = context.watch<ThemeProvider>();
    final l10n = AppLocalizations.of(context);

    return AppScaffold(
      title: l10n.settings,
      body: ContentPaneList(
        maxWidth: AppContentWidth.dashboard,
        builder: (context, padding) => ListView(
          padding: padding,
          children: [
            // Phần thông tin tài khoản
            SettingsSectionHeader(title: l10n.accountInfo),
            SettingsUserInfoTile(user: user),

            // Phần thông báo
            SettingsSectionHeader(title: l10n.notifications),
            SettingsMenuTile(
                icon: Icons.local_fire_department_outlined,
                title: l10n.dailyGoalAndReminder,
                onTap: () => showStreakSettingsSheet(context)),
            SettingsSwitchTile(
                title: l10n.enableNotifications,
                subtitle: l10n.receiveNotifications,
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() => _notificationsEnabled = value);
                }),
            SettingsSwitchTile(
                title: l10n.sound,
                subtitle: l10n.playSoundNotification,
                value: _soundEnabled,
                onChanged: (value) {
                  setState(() => _soundEnabled = value);
                }),
            SettingsSwitchTile(
                title: l10n.vibrate,
                subtitle: l10n.vibrateNotification,
                value: _vibrateEnabled,
                onChanged: (value) {
                  setState(() => _vibrateEnabled = value);
                }),

            // Phần ngôn ngữ & giao diện
            SettingsSectionHeader(title: l10n.languageInterface),
            _buildDropdownTile(
              title: l10n.language,
              value: _selectedLanguage,
              items: [
                DropdownMenuItem(value: 'vi', child: Text(l10n.vietnamese)),
                DropdownMenuItem(value: 'en', child: Text(l10n.english)),
                DropdownMenuItem(value: 'ja', child: Text(l10n.japanese)),
              ],
              onChanged: (value) async {
                if (value != null) {
                  setState(() => _selectedLanguage = value);
                  // Áp dụng ngôn ngữ ngay lập tức
                  final localeProvider =
                      Provider.of<LocaleProvider>(context, listen: false);
                  await localeProvider.setLanguage(value);
                  // Tự động lưu cài đặt
                  await _saveSettings();
                }
              },
            ),
            // Đổi ngay và lưu trên máy, không chờ nút Lưu: mất mạng không được
            // làm hỏng việc đổi giao diện.
            _buildDropdownTile<ThemeMode>(
              title: l10n.interface,
              value: themeProvider.mode,
              items: [
                DropdownMenuItem(
                    value: ThemeMode.light, child: Text(l10n.light)),
                DropdownMenuItem(value: ThemeMode.dark, child: Text(l10n.dark)),
                DropdownMenuItem(
                    value: ThemeMode.system, child: Text(l10n.auto)),
              ],
              onChanged: (value) {
                if (value != null) themeProvider.setMode(value);
              },
            ),

            // Phần khác
            SettingsSectionHeader(title: l10n.other),
            SettingsMenuTile(
                icon: Icons.help_outline,
                title: l10n.helpFeedback,
                onTap: () {
                  showSettingsHelpDialog(context);
                }),
            SettingsMenuTile(
                icon: Icons.privacy_tip_outlined,
                title: l10n.privacyPolicy,
                onTap: () {
                  showSettingsPrivacyDialog(context);
                }),
            SettingsMenuTile(
                icon: Icons.info_outline,
                title: l10n.aboutApp,
                onTap: () {
                  showSettingsAboutDialog(context);
                }),

            // Nút lưu
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _isLoading || !_loaded ? null : _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        l10n.saveSettings,
                        style: const TextStyle(
                            fontSize: AppTypography.body, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownTile<T>({
    required String title,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return ListTile(
      title: Text(title),
      trailing: DropdownButton<T>(
        value: value,
        items: items,
        onChanged: onChanged,
      ),
    );
  }
}
