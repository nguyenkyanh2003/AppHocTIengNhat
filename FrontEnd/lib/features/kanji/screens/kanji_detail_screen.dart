import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/content_pane.dart';
import '../../srs/widgets/srs_confirm_dialog.dart';
import '../models/kanji.dart';
import '../providers/kanji_detail_provider.dart';
import '../services/kanji_service.dart';
import '../widgets/kanji_detail_header.dart';
import '../widgets/kanji_example_list.dart';
import '../widgets/kanji_meaning_card.dart';
import '../widgets/kanji_readings_card.dart';
import '../widgets/kanji_review_button.dart';

/// Chi tiết một chữ Kanji: Hán Việt, nghĩa, cách đọc, ví dụ — và nút đưa chữ
/// vào lịch ôn tập (spec Kanji SRS §3).
///
/// Provider tạo cùng màn và huỷ khi rời màn; [service] chỉ để test truyền
/// service giả.
class KanjiDetailScreen extends StatelessWidget {
  const KanjiDetailScreen({super.key, required this.kanjiId, this.service});

  final String kanjiId;
  final KanjiService? service;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => KanjiDetailProvider(service: service)..load(kanjiId),
      child: _KanjiDetailView(kanjiId: kanjiId),
    );
  }
}

class _KanjiDetailView extends StatelessWidget {
  const _KanjiDetailView({required this.kanjiId});

  final String kanjiId;

  /// Thêm thì làm ngay; gỡ thì hỏi trước vì mất luôn tiến độ ôn của chữ.
  Future<void> _toggleReview(BuildContext context, Kanji kanji) async {
    final provider = context.read<KanjiDetailProvider>();
    final messenger = ScaffoldMessenger.of(context);
    if (kanji.isInReview &&
        !await confirmSrsAction(
          context,
          title: 'Gỡ khỏi lịch ôn?',
          message: 'Thẻ của chữ ${kanji.character} bị gỡ cùng toàn bộ tiến độ ôn của nó.',
          confirmLabel: 'Gỡ',
        )) {
      return;
    }

    final error = await provider.toggleReview();
    messenger.showSnackBar(SnackBar(
      content: Text(error ??
          (kanji.isInReview
              ? 'Đã gỡ ${kanji.character} khỏi lịch ôn.'
              : 'Đã thêm ${kanji.character} vào lịch ôn, ôn lần đầu sau 24 giờ.')),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<KanjiDetailProvider>();

    return Scaffold(
      body: AsyncView<Kanji>(
        state: provider.detailState,
        onRetry: () => provider.load(kanjiId),
        builder: (context, kanji) => CustomScrollView(
          slivers: [
            KanjiDetailHeader(kanji: kanji),
            // `SliverAppBar` giữ nguyên bề rộng cửa sổ; chỉ nội dung đọc
            // bên dưới mới bị bó lại cho khỏi dài quá tầm mắt.
            SliverLayoutBuilder(
              builder: (context, constraints) => SliverPadding(
                padding: ContentPane.paddingFor(
                  constraints.crossAxisExtent,
                  maxWidth: AppContentWidth.reading,
                  base: EdgeInsets.zero,
                ),
                sliver: SliverToBoxAdapter(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [context.colors.surface, context.colors.surfaceVariant],
                      ),
                    ),
                    child: Column(
                      children: [
                        KanjiMeaningCard(
                          kanji: kanji,
                          footer: KanjiReviewButton(
                            progress: kanji.srsProgress,
                            saving: provider.isSaving,
                            onPressed: () => _toggleReview(context, kanji),
                          ),
                        ),
                        if (kanji.onyomi.isNotEmpty || kanji.kunyomi.isNotEmpty)
                          KanjiReadingsCard(kanji: kanji),
                        if (kanji.examples.isNotEmpty) KanjiExampleList(examples: kanji.examples),
                        AppGap.lg,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
