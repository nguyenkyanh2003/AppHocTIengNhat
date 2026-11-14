import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';

/// Ô cuối danh sách phân trang: vòng xoay khi đang tải trang sau, hoặc câu báo
/// lỗi kèm nút thử lại. Danh sách đang có vẫn nằm nguyên phía trên.
class LoadMoreFooter extends StatelessWidget {
  const LoadMoreFooter({super.key, required this.error, required this.onRetry});

  /// `null` là đang tải.
  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final error = this.error;
    if (error == null) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Text(error, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.sm),
          TextButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Thử lại')),
        ],
      ),
    );
  }
}
