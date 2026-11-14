import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_client.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/pronounce.dart';
import '../../flashcards/widgets/add_to_flashcard_dialog.dart';
import '../../srs/models/srs_progress.dart';
import '../../srs/providers/srs_provider.dart';
import '../../srs/widgets/srs_confirm_dialog.dart';
import '../models/vocabulary.dart';
import '../providers/vocabulary_provider.dart';
import '../widgets/detail/vocabulary_example_list.dart';
import '../widgets/detail/vocabulary_detail_layout.dart';
import '../widgets/detail/vocabulary_kanji_breakdown.dart';
import '../widgets/detail/vocabulary_memory_progress.dart';
import '../widgets/detail/vocabulary_related_words.dart';
import '../widgets/detail/vocabulary_word_hero.dart';

/// Chi tiết một từ vựng.
///
/// Màn rộng chia hai cột: thẻ từ và mức ghi nhớ bên trái (thứ cần nhìn đầu
/// tiên), phân tích chữ Hán, ví dụ và từ liên quan bên phải. Màn hẹp xếp tất
/// cả thành một cột theo đúng thứ tự đó (xem [VocabularyDetailLayout]).
class VocabularyDetailScreen extends StatefulWidget {
  const VocabularyDetailScreen({super.key, required this.vocabularyId});

  final String vocabularyId;

  @override
  State<VocabularyDetailScreen> createState() => _VocabularyDetailScreenState();
}

class _VocabularyDetailScreenState extends State<VocabularyDetailScreen> {
  bool _toggling = false;
  bool _resetting = false;

  @override
  void initState() {
    super.initState();
    _loadAfterFrame();
  }

  /// Cùng route chỉ đổi mã từ (sửa địa chỉ trên web) thì màn được dùng lại,
  /// `initState` không chạy lần nữa: phải tự tải từ mới.
  @override
  void didUpdateWidget(covariant VocabularyDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.vocabularyId != widget.vocabularyId) _loadAfterFrame();
  }

  /// Tải sau khung hình: đang dựng cây thì provider chưa được phép báo thay đổi.
  void _loadAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load({bool silent = false}) => context
      .read<VocabularyProvider>()
      .loadVocabularyDetail(widget.vocabularyId, silent: silent);

  Future<void> _toggleLearned(Vocabulary vocabulary) async {
    final provider = context.read<VocabularyProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final wasLearned = vocabulary.isLearned;

    setState(() => _toggling = true);
    try {
      if (wasLearned) {
        await provider.unmarkAsLearned(widget.vocabularyId);
      } else {
        await provider.markAsLearned(widget.vocabularyId);
      }
      await _load(silent: true);
      messenger.showSnackBar(SnackBar(
        content: Text(wasLearned
            ? 'Đã bỏ đánh dấu đã học.'
            : 'Đã đánh dấu là đã học, từ này sẽ vào lịch ôn tập.'),
      ));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Không cập nhật được trạng thái học.')),
      );
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  /// Đặt lại lịch bằng mốc hạn ôn vừa đọc mới từ server. Lịch đã đổi ở nơi
  /// khác thì tải lại chi tiết để người học thấy lịch hiện tại.
  Future<void> _resetSchedule(Vocabulary vocabulary) async {
    final progress = vocabulary.srsProgress;
    if (progress == null) return;
    final confirmed = await confirmSrsAction(
      context,
      title: 'Đặt lại lịch ôn?',
      message: 'Từ về hộp 1 và sẽ đến hạn ôn lại sau 24 giờ.',
      confirmLabel: 'Đặt lại',
    );
    if (!confirmed || !mounted) return;

    final srs = context.read<SrsProvider>();
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _resetting = true);
    try {
      await srs.resetSchedule(
        itemId: vocabulary.id,
        itemType: SrsProgress.itemTypeVocabulary,
        expectedNextReview: progress.nextReview,
      );
      messenger.showSnackBar(const SnackBar(content: Text('Đã đặt lại lịch ôn, ôn lại sau 24 giờ.')));
    } on ApiException catch (error) {
      messenger.showSnackBar(SnackBar(
        content: Text(error.code == 'SRS_PROGRESS_CHANGED'
            ? 'Lịch ôn vừa thay đổi ở nơi khác, đã tải lại.'
            : error.message),
      ));
    } finally {
      if (mounted) {
        setState(() => _resetting = false);
        await _load(silent: true);
      }
    }
  }

  /// Chi tiết dùng chung một state trong provider, nên quay về từ một từ liên
  /// quan phải tải lại từ của màn này.
  Future<void> _openRelated(Vocabulary word) async {
    await context.push('/vocabulary/${word.id}');
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VocabularyProvider>();
    final vocabulary = provider.selectedVocabulary;

    return AppScaffold(
      title: 'Chi tiết từ vựng',
      actions: [
        if (vocabulary != null)
          IconButton(
            icon: const Icon(Icons.bookmark_add_outlined),
            tooltip: 'Thêm vào bộ thẻ của tôi',
            onPressed: () => AddToFlashcardDialog.show(
              context,
              front: vocabulary.word,
              back: vocabulary.meaning,
              frontSubtext: vocabulary.hiragana,
            ),
          ),
      ],
      body: AsyncView<Vocabulary>(
        state: provider.detailState,
        onRetry: _load,
        builder: (context, item) => VocabularyDetailLayout(
          primary: [
            VocabularyWordHero(
              vocabulary: item,
              togglingLearned: _toggling,
              onSpeak: () => pronounce(
                context,
                audioUrl: item.audioUrl,
                text: item.hiragana.isNotEmpty ? item.hiragana : item.word,
              ),
              onToggleLearned: () => _toggleLearned(item),
            ),
            VocabularyMemoryProgress(
              vocabulary: item,
              resetting: _resetting,
              onResetSchedule: () => _resetSchedule(item),
            ),
          ],
          secondary: [
            if (item.kanjiBreakdown.isNotEmpty)
              VocabularyKanjiBreakdown(
                parts: item.kanjiBreakdown,
                onOpenKanji: (id) => context.push('/kanji/$id'),
              ),
            // Không đọc được câu ví dụ thì thôi, không báo: chữ vẫn đọc được.
            VocabularyExampleList(
              examples: item.examples,
              onSpeak: (example) =>
                  pronounce(context, audioUrl: example.audioUrl, text: example.sentence, quiet: true),
            ),
            VocabularyRelatedWords(
              words: item.relatedWords,
              onOpen: _openRelated,
            ),
          ],
        ),
      ),
    );
  }
}
