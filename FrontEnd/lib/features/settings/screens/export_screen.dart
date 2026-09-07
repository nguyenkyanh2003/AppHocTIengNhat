import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/files/file_saver.dart';
import '../../../core/network/api_client.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  static const _types = <String, (String, String, IconData)>{
    'full_stats': (
      'Thống kê tổng quan',
      'Tiến độ, phân tích bài học và streak',
      Icons.analytics_outlined,
    ),
    'lesson_progress': (
      'Tiến độ bài học',
      'Toàn bộ tiến độ học tập hiện có',
      Icons.trending_up,
    ),
    'notebook': (
      'Ghi chép',
      'Danh sách ghi chú cá nhân',
      Icons.note_alt_outlined,
    ),
    'achievements': (
      'Thành tích',
      'Thành tích đã mở khóa và đang thực hiện',
      Icons.emoji_events_outlined,
    ),
    'streaks': (
      'Streak và XP',
      'Chuỗi học tập và lịch sử điểm kinh nghiệm',
      Icons.local_fire_department_outlined,
    ),
    'all_data': (
      'Toàn bộ dữ liệu',
      'Gộp tất cả nhóm dữ liệu phía trên',
      Icons.archive_outlined,
    ),
  };

  final _client = ApiClient();
  String _selectedType = 'all_data';
  String _selectedFormat = 'json';
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Xuất dữ liệu')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              children: [
                Icon(Icons.download, size: 52, color: Colors.blue),
                SizedBox(height: 12),
                Text(
                  'Sao lưu dữ liệu học tập',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 6),
                Text(
                  'Dữ liệu được lấy trực tiếp từ tài khoản tại thời điểm xuất.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Chọn loại dữ liệu',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ..._types.entries.map((entry) {
            final info = entry.value;
            return Card(
              child: RadioListTile<String>(
                value: entry.key,
                groupValue: _selectedType,
                onChanged: _isExporting
                    ? null
                    : (value) => setState(() => _selectedType = value!),
                secondary: Icon(info.$3),
                title: Text(info.$1),
                subtitle: Text(info.$2),
              ),
            );
          }),
          const SizedBox(height: 20),
          const Text(
            'Định dạng tệp',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'json',
                icon: Icon(Icons.data_object),
                label: Text('JSON'),
              ),
              ButtonSegment(
                value: 'csv',
                icon: Icon(Icons.table_view),
                label: Text('CSV'),
              ),
            ],
            selected: {_selectedFormat},
            onSelectionChanged: _isExporting
                ? null
                : (values) => setState(() => _selectedFormat = values.single),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _isExporting ? null : _exportToFile,
            icon: _isExporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download),
            label: Text(_isExporting ? 'Đang xuất...' : 'Xuất tệp'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _isExporting ? null : _copyJson,
            icon: const Icon(Icons.content_copy),
            label: const Text('Sao chép JSON'),
          ),
          const SizedBox(height: 16),
          const Text(
            'CSV dùng hai cột “section” và “data”; dữ liệu lồng nhau được giữ dưới dạng JSON để không bị mất trường.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _loadSelectedData() async {
    switch (_selectedType) {
      case 'full_stats':
        final values = await Future.wait([
          _client.get('/progress/dashboard/stats'),
          _client.get('/progress/dashboard/breakdown'),
          _client.get('/streak/my-streak'),
        ]);
        return {
          'statistics': values[0],
          'breakdown': values[1],
          'streak': values[2],
        };
      case 'lesson_progress':
        return {'lesson_progress': await _client.get('/progress')};
      case 'notebook':
        return {'notebook': await _client.get('/notebook?limit=100')};
      case 'achievements':
        return {
          'achievements': await _client.get('/achievement/my-achievements'),
        };
      case 'streaks':
        final values = await Future.wait([
          _client.get('/streak/my-streak'),
          _client.get('/streak/xp-history'),
        ]);
        return {'streak': values[0], 'xp_history': values[1]};
      case 'all_data':
        final values = await Future.wait([
          _client.get('/progress'),
          _client.get('/progress/dashboard/stats'),
          _client.get('/notebook?limit=100'),
          _client.get('/achievement/my-achievements'),
          _client.get('/streak/my-streak'),
          _client.get('/streak/xp-history'),
        ]);
        return {
          'lesson_progress': values[0],
          'statistics': values[1],
          'notebook': values[2],
          'achievements': values[3],
          'streak': values[4],
          'xp_history': values[5],
        };
      default:
        throw ArgumentError('Loại dữ liệu không hợp lệ.');
    }
  }

  Future<void> _exportToFile() async {
    setState(() => _isExporting = true);
    try {
      final data = await _loadSelectedData();
      final content = _selectedFormat == 'json'
          ? const JsonEncoder.withIndent('  ').convert({
              'exported_at': DateTime.now().toIso8601String(),
              'type': _selectedType,
              'data': data,
            })
          : _toCsv(data);
      final encoded = utf8.encode(content);
      final bytes = Uint8List.fromList(
        _selectedFormat == 'csv' ? [0xEF, 0xBB, 0xBF, ...encoded] : encoded,
      );
      final now = DateTime.now();
      final fileName =
          '${_selectedType}_${now.year}${_two(now.month)}${_two(now.day)}.$_selectedFormat';
      final saved = await saveBytes(
        fileName: fileName,
        bytes: bytes,
        mimeType: _selectedFormat == 'json'
            ? 'application/json;charset=utf-8'
            : 'text/csv;charset=utf-8',
      );
      if (mounted) {
        _message(saved ? 'Đã xuất tệp $fileName.' : 'Đã hủy xuất tệp.', saved);
      }
    } catch (error) {
      if (mounted) _message('Không thể xuất dữ liệu: $error', false);
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _copyJson() async {
    setState(() => _isExporting = true);
    try {
      final data = await _loadSelectedData();
      final content = const JsonEncoder.withIndent('  ').convert({
        'exported_at': DateTime.now().toIso8601String(),
        'type': _selectedType,
        'data': data,
      });
      await Clipboard.setData(ClipboardData(text: content));
      if (mounted) _message('Đã sao chép dữ liệu JSON.', true);
    } catch (error) {
      if (mounted) _message('Không thể sao chép dữ liệu: $error', false);
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  String _toCsv(Map<String, dynamic> data) {
    final buffer = StringBuffer()..writeln('"section","data"');
    for (final entry in data.entries) {
      buffer.writeln(
        '${_csvCell(entry.key)},${_csvCell(jsonEncode(entry.value))}',
      );
    }
    return buffer.toString();
  }

  String _csvCell(String value) => '"${value.replaceAll('"', '""')}"';

  String _two(int value) => value.toString().padLeft(2, '0');

  void _message(String message, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }
}
