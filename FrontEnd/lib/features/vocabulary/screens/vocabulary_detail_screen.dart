import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../core/audio/audio_service.dart';
import '../../../core/audio/speech_service.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/content_pane.dart';
import '../../../core/network/api_client.dart';
import '../../flashcards/widgets/add_to_flashcard_dialog.dart';
import '../../srs/providers/srs_provider.dart';
import '../../srs/widgets/srs_confirm_dialog.dart';
import '../models/vocabulary.dart';
import '../providers/vocabulary_provider.dart';
import '../widgets/detail/vocabulary_example_list.dart';
import '../widgets/detail/vocabulary_kanji_breakdown.dart';
import '../widgets/detail/vocabulary_memory_progress.dart';
import '../widgets/detail/vocabulary_related_words.dart';
import '../widgets/detail/vocabulary_word_hero.dart';

/// Chi tiết một từ vựng.
///
/// Màn rộng chia hai cột: thẻ từ và mức ghi nhớ bên trái (thứ cần nhìn đầu
/// tiên), phân tích chữ Hán, ví dụ và từ liên quan bên phải. Màn hẹp xếp tất
/// cả thành một cột theo đúng thứ tự đó.
class VocabularyDetailScreen extends StatefulWidget {
  const VocabularyDetailScreen({super.key, required this.vocabularyId});

  final String vocabularyId;

  /// Từ bề rộng này (vùng nội dung, không tính thanh điều hướng) thì chia
  /// hai cột; hẹp hơn thì cột phải bị ép dưới ~480px, đọc câu ví dụ rất chật.
  static const double twoColumnMinWidth = 840;

  @override
  State<VocabularyDetailScreen> createState() => _VocabularyDetailScreenState();
}

class _VocabularyDetailScreenState extends State<VocabularyDetailScreen> {
  bool _toggling = false;
  bool _resetting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load({bool silent = false}) => context
      .read<VocabularyProvider>()
      .loadVocabularyDetail(widget.vocabularyId, silent: silent);

  /// File âm thanh thật nếu có, không thì giọng đọc của thiết bị.
  Future<void> _speakWord(Vocabulary item) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (item.audioUrl != null) {
        await AudioService().playAudio(item.audioUrl!);
      } else {
        await SpeechService.instance.speak(
          item.hiragana.isNotEmpty ? item.hiragana : item.word,
        );
      }
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Không phát được âm thanh.')),
      );
    }
  }

  Future<void> _speakExample(VocabExample example) async {
    try {
      if (example.audioUrl != null) {
        await AudioService().playAudio(example.audioUrl!);
      } else {
        await SpeechService.instance.speak(example.sentence);
      }
    } catch (_) {
      // Không có giọng đọc tiếng Nhật trên thiết bị: bỏ qua, câu vẫn đọc được.
    }
  }

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
      await srs.resetSchedule(itemId: vocabulary.id, expectedNextReview: progress.nextReview);
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
        builder: (context, item) => _DetailLayout(
          primary: [
            VocabularyWordHero(
              vocabulary: item,
              togglingLearned: _toggling,
              onSpeak: () => _speakWord(item),
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
            VocabularyExampleList(
              examples: item.examples,
              onSpeak: _speakExample,
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

/// Hai cột trên màn rộng, một cột trên màn hẹp; nội dung luôn giới hạn bề
/// rộng [AppContentWidth.detail] và nằm giữa trang.
class _DetailLayout extends StatelessWidget {
  const _DetailLayout({required this.primary, required this.secondary});

  final List<Widget> primary;
  final List<Widget> secondary;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide =
            constraints.maxWidth >= VocabularyDetailScreen.twoColumnMinWidth;
        final padding = EdgeInsets.all(wide ? AppSpacing.xl : AppSpacing.lg);

        if (!wide) {
          return ListView(
            padding: ContentPane.paddingFor(
              constraints.maxWidth,
              maxWidth: AppContentWidth.reading,
              base: padding,
            ),
            children: [...primary, ...secondary],
          );
        }

        return SingleChildScrollView(
          padding: padding,
          child: Center(
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(maxWidth: AppContentWidth.detail),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: Column(children: primary)),
                  AppGap.xl,
                  Expanded(flex: 7, child: Column(children: secondary)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
