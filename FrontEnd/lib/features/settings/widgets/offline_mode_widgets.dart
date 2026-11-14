import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../models/offline_cache.dart';

/// Thẻ bật/tắt dùng nội dung đã tải khi mất mạng.
class OfflineStatusCard extends StatelessWidget {
  const OfflineStatusCard({super.key, required this.enabled, required this.onChanged});

  final bool enabled;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final color = enabled ? AppColors.warning : AppColors.success;
    return Card(
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(enabled ? Icons.wifi_off : Icons.wifi, size: 42, color: color),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    enabled ? 'Dự phòng ngoại tuyến đang bật' : 'Đang ưu tiên dữ liệu trực tuyến',
                    style: const TextStyle(fontSize: AppTypography.subtitle, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    enabled
                        ? 'Khi mất mạng, ứng dụng dùng nội dung đã tải về.'
                        : 'Bật để dùng cache nếu máy chủ không truy cập được.',
                  ),
                ],
              ),
            ),
            Switch(value: enabled, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

/// Dung lượng và lần đồng bộ gần nhất của bộ đệm.
class OfflineCacheInfoCard extends StatelessWidget {
  const OfflineCacheInfoCard({super.key, required this.status});

  final OfflineCacheStatus status;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.inventory_2_outlined),
            title: Text('${status.items} gói nội dung'),
            subtitle: Text(_formatBytes(status.bytes)),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.schedule),
            title: const Text('Đồng bộ gần nhất'),
            subtitle: Text(_formatDate(status.lastSync)),
          ),
        ],
      ),
    );
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  static String _formatDate(DateTime? value) {
    if (value == null) return 'Chưa đồng bộ';
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(value.hour)}:${two(value.minute)} ${two(value.day)}/${two(value.month)}/${value.year}';
  }
}

/// Hỏi nhóm nội dung cần tải; `null` là người dùng huỷ.
Future<OfflineContentSelection?> showOfflineDownloadDialog(BuildContext context) {
  var selection = const OfflineContentSelection();
  return showDialog<OfflineContentSelection>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) {
        Widget option(String label, bool value, OfflineContentSelection Function(bool) change) =>
            CheckboxListTile(
              value: value,
              onChanged: (checked) => setDialogState(() => selection = change(checked ?? false)),
              title: Text(label),
            );
        return AlertDialog(
          title: const Text('Chọn nội dung cần tải'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              option('Bài học', selection.lessons, (on) => selection.copyWith(lessons: on)),
              option('Từ vựng', selection.vocabulary, (on) => selection.copyWith(vocabulary: on)),
              option('Kanji', selection.kanji, (on) => selection.copyWith(kanji: on)),
              option('Ngữ pháp', selection.grammar, (on) => selection.copyWith(grammar: on)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Hủy')),
            FilledButton(
              onPressed: selection.isEmpty ? null : () => Navigator.pop(dialogContext, selection),
              child: const Text('Tải'),
            ),
          ],
        );
      },
    ),
  );
}

/// Hỏi lại trước khi xoá toàn bộ bộ đệm.
Future<bool> confirmClearOfflineCache(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Xóa cache ngoại tuyến?'),
      content: const Text('Ứng dụng sẽ cần mạng để tải lại nội dung học tập.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Hủy')),
        FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Xóa')),
      ],
    ),
  );
  return confirmed ?? false;
}
