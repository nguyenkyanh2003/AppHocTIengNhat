import 'package:flutter/material.dart';

import '../services/settings_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final _service = SettingsService();
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrateEnabled = true;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final settings = await _service.getSettings();
      if (!mounted) return;
      setState(() {
        _notificationsEnabled = settings['notificationsEnabled'] ?? true;
        _soundEnabled = settings['soundEnabled'] ?? true;
        _vibrateEnabled = settings['vibrateEnabled'] ?? true;
      });
    } catch (error) {
      if (mounted) _message('Không thể tải cài đặt: $error', false);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final current = await _service.getSettings();
      await _service.saveSettings({
        ...current,
        'notificationsEnabled': _notificationsEnabled,
        'soundEnabled': _soundEnabled,
        'vibrateEnabled': _vibrateEnabled,
      });
      if (mounted) _message('Đã lưu cài đặt thông báo.', true);
    } catch (error) {
      if (mounted) _message('Không thể lưu cài đặt: $error', false);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt thông báo')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _notificationsEnabled
                            ? Icons.notifications_active
                            : Icons.notifications_off_outlined,
                        size: 52,
                        color:
                            _notificationsEnabled ? Colors.blue : Colors.grey,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _notificationsEnabled
                            ? 'Thông báo đang bật'
                            : 'Thông báo đang tắt',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
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
                        subtitle: const Text(
                          'Cho phép ứng dụng hiển thị thông báo trong tài khoản.',
                        ),
                        value: _notificationsEnabled,
                        onChanged: (value) =>
                            setState(() => _notificationsEnabled = value),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        secondary: const Icon(Icons.volume_up_outlined),
                        title: const Text('Âm thanh'),
                        subtitle:
                            const Text('Phát âm báo khi có thông báo mới.'),
                        value: _soundEnabled,
                        onChanged: _notificationsEnabled
                            ? (value) => setState(() => _soundEnabled = value)
                            : null,
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        secondary: const Icon(Icons.vibration),
                        title: const Text('Rung'),
                        subtitle:
                            const Text('Rung thiết bị khi có thông báo mới.'),
                        value: _vibrateEnabled,
                        onChanged: _notificationsEnabled
                            ? (value) => setState(() => _vibrateEnabled = value)
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(_saving ? 'Đang lưu...' : 'Lưu cài đặt'),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Ứng dụng chỉ hiển thị các tùy chọn đã được backend lưu và hỗ trợ. Lịch yên tĩnh, SMS và email định kỳ không nằm trong phạm vi phiên bản này.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
    );
  }

  void _message(String text, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }
}
