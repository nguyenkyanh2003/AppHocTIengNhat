import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/content_pane.dart';
import '../../streaks/providers/streak_provider.dart';
import '../models/srs_card.dart';
import '../providers/srs_provider.dart';
import '../widgets/srs_answer_bar.dart';
import '../widgets/srs_card_menu.dart';
import '../widgets/srs_confirm_dialog.dart';
import '../widgets/srs_flashcard.dart';
import '../widgets/srs_session_summary.dart';

/// Ôn tập hôm nay: từng thẻ từ vựng đến hạn, tự nhớ → lật → "Nhớ"/"Chưa nhớ".
///
/// Tải đợt đầu dùng [AsyncView]; lỗi của một thao tác trên thẻ hiện ngay dưới
/// thẻ kèm nút thử lại, không thay cả phiên bằng màn lỗi và làm mất thẻ đang ôn.
class SrsReviewScreen extends StatefulWidget {
  const SrsReviewScreen({super.key});

  @override
  State<SrsReviewScreen> createState() => _SrsReviewScreenState();
}

class _SrsReviewScreenState extends State<SrsReviewScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<SrsProvider>().startSession();
    });
  }

  /// Chạy một thao tác rồi báo thông điệp một lần của provider (thẻ vừa đổi ở
  /// nơi khác...). Phiên vừa kết thúc thì làm mới chuỗi ngày và XP.
  Future<void> _run(Future<void> Function(SrsProvider provider) action) async {
    final provider = context.read<SrsProvider>();
    final streak = context.read<StreakProvider>();
    final messenger = ScaffoldMessenger.of(context);

    await action(provider);

    final notice = provider.consumeNotice();
    if (notice != null) messenger.showSnackBar(SnackBar(content: Text(notice)));
    if (provider.isFinished) streak.loadStreak();
  }

  Future<void> _remove() async {
    final confirmed = await confirmSrsAction(
      context,
      title: 'Xoá khỏi lịch ôn?',
      message: 'Tiến độ ôn của từ này bị xoá và từ trở về trạng thái chưa học.',
      confirmLabel: 'Xoá',
    );
    if (confirmed && mounted) await _run((provider) => provider.removeCurrent());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SrsProvider>();
    final card = provider.currentCard;

    return AppScaffold(
      title: 'Ôn tập hôm nay',
      actions: [
        if (card != null)
          SrsCardMenu(
            enabled: !provider.isBusy,
            onSkip: () => _run((provider) => provider.skip()),
            onReset: () => _run((provider) => provider.resetCurrent()),
            onRemove: () => _run((provider) => provider.removeCurrent()),
          ),
      ],
      body: AsyncView<List<SrsCard>>(
        state: provider.sessionState,
        onRetry: provider.reloadBatch,
        builder: (context, cards) => SingleChildScrollView(
          child: ContentPane(
            child: cards.isEmpty
                ? SrsSessionSummary(
                    tally: provider.tally,
                    stats: provider.statsState,
                    onRestart: provider.startSession,
                    onDone: () => context.go('/review'),
                  )
                : _ReviewPane(
                    card: cards.first,
                    queued: cards.length,
                    provider: provider,
                    onRun: _run,
                    onRemove: _remove,
                  ),
          ),
        ),
      ),
    );
  }
}

class _ReviewPane extends StatelessWidget {
  const _ReviewPane({
    required this.card,
    required this.queued,
    required this.provider,
    required this.onRun,
    required this.onRemove,
  });

  final SrsCard card;
  final int queued;
  final SrsProvider provider;
  final Future<void> Function(Future<void> Function(SrsProvider provider) action) onRun;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final due = provider.dueCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Thẻ ${provider.handledCount + 1} · còn $queued thẻ trong đợt'
          '${due == null ? '' : ' · $due thẻ đến hạn'}',
          style: textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
        AppGap.md,
        SrsFlashcard(card: card, revealed: provider.isRevealed, onReveal: provider.reveal),
        if (provider.actionError case final message?) ...[
          AppGap.md,
          _ActionError(message: message, onRetry: () => onRun((provider) => provider.retry())),
        ],
        AppGap.lg,
        SrsAnswerBar(
          revealed: provider.isRevealed,
          unavailable: card.unavailable,
          busy: provider.isBusy,
          onReveal: provider.reveal,
          onAnswer: (remembered) => onRun((provider) => provider.answer(remembered: remembered)),
          onSkip: () => onRun((provider) => provider.skip()),
          onRemove: onRemove,
        ),
      ],
    );
  }
}

class _ActionError extends StatelessWidget {
  const _ActionError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.card,
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: AppRadius.mdAll,
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error),
          AppGap.md,
          Expanded(child: Text(message)),
          TextButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    );
  }
}
