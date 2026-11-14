import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/content_pane.dart';
import '../models/offline_cache.dart';
import '../providers/offline_mode_provider.dart';
import '../widgets/offline_mode_widgets.dart';

class OfflineModeScreen extends StatelessWidget {
  const OfflineModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OfflineModeProvider()..load(),
      child: const _OfflineModeView(),
    );
  }
}

class _OfflineModeView extends StatelessWidget {
  const _OfflineModeView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OfflineModeProvider>();
    return AppScaffold(
      title: 'Chế độ ngoại tuyến',
      body: ContentWidthLimit(
        child: AsyncView<OfflineCacheStatus>(
          state: provider.state,
          onRetry: provider.load,
          builder: (context, status) => _OfflineModeBody(status: status, busy: provider.isBusy),
        ),
      ),
    );
  }
}

class _OfflineModeBody extends StatelessWidget {
  const _OfflineModeBody({required this.status, required this.busy});

  final OfflineCacheStatus status;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<OfflineModeProvider>();
    final canUseCache = !busy && !status.isEmpty;

    return ListView(
      padding: AppSpacing.page,
      children: [
        if (busy) const LinearProgressIndicator(),
        OfflineStatusCard(enabled: status.enabled, onChanged: busy ? null : provider.setEnabled),
        const SizedBox(height: 20),
        const Text(
          'Dữ liệu đã tải',
          style: TextStyle(fontSize: AppTypography.subtitle, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.sm),
        OfflineCacheInfoCard(status: status),
        const SizedBox(height: AppSpacing.lg),
        FilledButton.icon(
          onPressed: busy ? null : () => _download(context),
          icon: const Icon(Icons.download),
          label: const Text('Tải nội dung để học ngoại tuyến'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: canUseCache ? () => _report(context, provider.sync()) : null,
          icon: const Icon(Icons.sync),
          label: const Text('Đồng bộ cache ngay'),
        ),
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: canUseCache ? () => _clear(context) : null,
          icon: Icon(Icons.delete_outline, color: context.colors.error),
          label: Text('Xóa dữ liệu đã tải', style: TextStyle(color: context.colors.error)),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Cache chỉ lưu nội dung học tập như bài học, từ vựng, Kanji và ngữ pháp. Dữ liệu đăng nhập không được lưu trong cache này.',
          textAlign: TextAlign.center,
          style: TextStyle(color: context.colors.textSecondary),
        ),
      ],
    );
  }

  Future<void> _download(BuildContext context) async {
    final provider = context.read<OfflineModeProvider>();
    final selection = await showOfflineDownloadDialog(context);
    if (selection == null || !context.mounted) return;
    await _report(context, provider.download(selection));
  }

  Future<void> _clear(BuildContext context) async {
    final provider = context.read<OfflineModeProvider>();
    if (!await confirmClearOfflineCache(context) || !context.mounted) return;
    await _report(context, provider.clear());
  }

  Future<void> _report(BuildContext context, Future<OfflineActionResult> action) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await action;
    messenger.showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.success ? AppColors.successStrong : AppColors.errorStrong,
      ),
    );
  }
}
