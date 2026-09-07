import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../profile/providers/user_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../app/localization/locale_provider.dart';
import '../services/settings_service.dart';
import '../../../app/localization/app_localizations.dart';

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
  String _selectedTheme = 'light';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final response = await _settingsService.getSettings();
      if (response.isNotEmpty) {
        setState(() {
          _notificationsEnabled = response['notificationsEnabled'] ?? true;
          _soundEnabled = response['soundEnabled'] ?? true;
          _vibrateEnabled = response['vibrateEnabled'] ?? true;
          _selectedLanguage = response['language'] ?? 'vi';
          _selectedTheme = response['theme'] ?? 'light';
        });
      }
    } catch (e) {
      debugPrint('Lỗi khi tải cài đặt: $e');
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    try {
      await _settingsService.saveSettings({
        'notificationsEnabled': _notificationsEnabled,
        'soundEnabled': _soundEnabled,
        'vibrateEnabled': _vibrateEnabled,
        'language': _selectedLanguage,
        'theme': _selectedTheme,
      });

      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.settingsSaved),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text(l10n.settings),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        children: [
          // Phần thông tin tài khoản
          _buildSectionHeader(l10n.accountInfo),
          _buildUserInfoTile(userProvider),

          // Phần thông báo
          _buildSectionHeader(l10n.notifications),
          _buildSwitchTile(
            title: l10n.enableNotifications,
            subtitle: l10n.receiveNotifications,
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() => _notificationsEnabled = value);
            },
          ),
          _buildSwitchTile(
            title: l10n.sound,
            subtitle: l10n.playSoundNotification,
            value: _soundEnabled,
            onChanged: (value) {
              setState(() => _soundEnabled = value);
            },
          ),
          _buildSwitchTile(
            title: l10n.vibrate,
            subtitle: l10n.vibrateNotification,
            value: _vibrateEnabled,
            onChanged: (value) {
              setState(() => _vibrateEnabled = value);
            },
          ),

          // Phần ngôn ngữ & giao diện
          _buildSectionHeader(l10n.languageInterface),
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
          _buildDropdownTile(
            title: l10n.interface,
            value: _selectedTheme,
            items: [
              DropdownMenuItem(value: 'light', child: Text(l10n.light)),
              DropdownMenuItem(value: 'dark', child: Text(l10n.dark)),
              DropdownMenuItem(value: 'auto', child: Text(l10n.auto)),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _selectedTheme = value);
            },
          ),

          // Phần khác
          _buildSectionHeader(l10n.other),
          _buildMenuTile(
            icon: Icons.help_outline,
            title: l10n.helpFeedback,
            onTap: () {
              _showHelpDialog();
            },
          ),
          _buildMenuTile(
            icon: Icons.privacy_tip_outlined,
            title: l10n.privacyPolicy,
            onTap: () {
              _showPrivacyDialog();
            },
          ),
          _buildMenuTile(
            icon: Icons.info_outline,
            title: l10n.aboutApp,
            onTap: () {
              _showAboutDialog();
            },
          ),
          _buildMenuTile(
            icon: Icons.logout,
            title: l10n.logout,
            onTap: () {
              _showLogoutDialog(context, authProvider);
            },
          ),

          // Nút lưu
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
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
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      l10n.saveSettings,
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildUserInfoTile(UserProvider userProvider) {
    final user = userProvider.user;
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

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.blue,
      ),
    );
  }

  Widget _buildDropdownTile({
    required String title,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
  }) {
    return ListTile(
      title: Text(title),
      trailing: DropdownButton<String>(
        value: value,
        items: items,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Trợ giúp & Phản hồi'),
        content: const Text(
          'Để được hỗ trợ, vui lòng liên hệ:\n\n'
          'Email: support@apphoctiengnhat.com\n'
          'Điện thoại: 1900-xxxx\n\n'
          'Hoặc gửi phản hồi qua ứng dụng.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chính sách riêng tư'),
        content: const SingleChildScrollView(
          child: Text(
            'Chúng tôi cam kết bảo vệ dữ liệu cá nhân của bạn.\n\n'
            '1. Dữ liệu của bạn được mã hóa và bảo vệ\n'
            '2. Chúng tôi không bao giờ chia sẻ thông tin cá nhân\n'
            '3. Bạn có quyền truy cập, chỉnh sửa dữ liệu của mình\n\n'
            'Xem chi tiết tại website của chúng tôi.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Về ứng dụng'),
        content: const Text(
          'App Học Tiếng Nhật\n'
          'Phiên bản: 1.0.0\n\n'
          'Giúp bạn học tiếng Nhật một cách hiệu quả và vui vẻ.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              authProvider.logout();
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
            child: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
