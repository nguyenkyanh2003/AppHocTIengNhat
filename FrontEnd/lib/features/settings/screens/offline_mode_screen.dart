import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';

class OfflineModeScreen extends StatefulWidget {
  const OfflineModeScreen({super.key});

  @override
  State<OfflineModeScreen> createState() => _OfflineModeScreenState();
}

class _OfflineModeScreenState extends State<OfflineModeScreen> {
  final _client = ApiClient();
  bool _enabled = false;
  bool _busy = true;
  int _cachedItems = 0;
  int _cachedBytes = 0;
  DateTime? _lastSync;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final enabled = await _client.isOfflineModeEnabled();
    final info = await _client.offlineCacheInfo();
    if (!mounted) return;
    setState(() {
      _enabled = enabled;
      _cachedItems = info['items'] as int? ?? 0;
      _cachedBytes = info['bytes'] as int? ?? 0;
      _lastSync = info['lastSync'] as DateTime?;
      _busy = false;
    });
  }

  Future<void> _setEnabled(bool value) async {
    await _client.setOfflineModeEnabled(value);
    if (mounted) setState(() => _enabled = value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chế độ ngoại tuyến')),
      body: _busy
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  color: _enabled
                      ? Colors.orange.withValues(alpha: 0.1)
                      : Colors.green.withValues(alpha: 0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Icon(
                          _enabled ? Icons.wifi_off : Icons.wifi,
                          size: 42,
                          color: _enabled ? Colors.orange : Colors.green,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _enabled
                                    ? 'Dự phòng ngoại tuyến đang bật'
                                    : 'Đang ưu tiên dữ liệu trực tuyến',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _enabled
                                    ? 'Khi mất mạng, ứng dụng dùng nội dung đã tải về.'
                                    : 'Bật để dùng cache nếu máy chủ không truy cập được.',
                              ),
                            ],
                          ),
                        ),
                        Switch(value: _enabled, onChanged: _setEnabled),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Dữ liệu đã tải',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.inventory_2_outlined),
                        title: Text('$_cachedItems gói nội dung'),
                        subtitle: Text(_formatBytes(_cachedBytes)),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.schedule),
                        title: const Text('Đồng bộ gần nhất'),
                        subtitle: Text(_formatDate(_lastSync)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _busy ? null : _showDownloadDialog,
                  icon: const Icon(Icons.download),
                  label: const Text('Tải nội dung để học ngoại tuyến'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _busy || _cachedItems == 0 ? null : _syncNow,
                  icon: const Icon(Icons.sync),
                  label: const Text('Đồng bộ cache ngay'),
                ),
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: _busy || _cachedItems == 0 ? null : _clearCache,
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: const Text(
                    'Xóa dữ liệu đã tải',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Cache chỉ lưu nội dung học tập như bài học, từ vựng, Kanji và ngữ pháp. Dữ liệu đăng nhập không được lưu trong cache này.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
    );
  }

  Future<void> _showDownloadDialog() async {
    var lessons = true;
    var vocabulary = true;
    var kanji = true;
    var grammar = true;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Chọn nội dung cần tải'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CheckboxListTile(
                value: lessons,
                onChanged: (value) =>
                    setDialogState(() => lessons = value ?? false),
                title: const Text('Bài học'),
              ),
              CheckboxListTile(
                value: vocabulary,
                onChanged: (value) =>
                    setDialogState(() => vocabulary = value ?? false),
                title: const Text('Từ vựng'),
              ),
              CheckboxListTile(
                value: kanji,
                onChanged: (value) =>
                    setDialogState(() => kanji = value ?? false),
                title: const Text('Kanji'),
              ),
              CheckboxListTile(
                value: grammar,
                onChanged: (value) =>
                    setDialogState(() => grammar = value ?? false),
                title: const Text('Ngữ pháp'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: lessons || vocabulary || kanji || grammar
                  ? () => Navigator.pop(dialogContext, true)
                  : null,
              child: const Text('Tải'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      final loaded = await _client.preloadOfflineContent(
        lessons: lessons,
        vocabulary: vocabulary,
        kanji: kanji,
        grammar: grammar,
      );
      await _client.setOfflineModeEnabled(true);
      await _loadState();
      if (mounted) _message('Đã tải $loaded nhóm nội dung.', true);
    } catch (error) {
      if (mounted) {
        setState(() => _busy = false);
        _message('Không thể tải dữ liệu: $error', false);
      }
    }
  }

  Future<void> _syncNow() async {
    setState(() => _busy = true);
    final synced = await _client.syncOfflineCache();
    await _loadState();
    if (mounted) {
      _message(
        synced > 0
            ? 'Đã đồng bộ $synced gói nội dung.'
            : 'Không thể làm mới cache. Dữ liệu cũ vẫn được giữ.',
        synced > 0,
      );
    }
  }

  Future<void> _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa cache ngoại tuyến?'),
        content:
            const Text('Ứng dụng sẽ cần mạng để tải lại nội dung học tập.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _client.clearOfflineCache();
    await _loadState();
    if (mounted) _message('Đã xóa cache ngoại tuyến.', true);
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDate(DateTime? value) {
    if (value == null) return 'Chưa đồng bộ';
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(value.hour)}:${two(value.minute)} ${two(value.day)}/${two(value.month)}/${value.year}';
  }

  void _message(String message, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }
}
