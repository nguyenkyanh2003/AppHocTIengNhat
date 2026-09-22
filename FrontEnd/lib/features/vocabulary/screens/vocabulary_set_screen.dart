import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/content_pane.dart';
import '../../flashcards/widgets/add_to_flashcard_dialog.dart';
import '../models/vocabulary.dart';
import '../models/vocabulary_set.dart';
import '../providers/vocabulary_set_provider.dart';
import '../../../shared/widgets/app_dialog.dart';
import '../widgets/vocabulary_set_header.dart';
import '../widgets/vocabulary_set_word_tile.dart';

/// Một bộ từ vựng: tiến độ, nút học và danh sách từ theo thứ tự học.
class VocabularySetScreen extends StatefulWidget {
  const VocabularySetScreen({super.key, required this.setId});

  final String setId;

  @override
  State<VocabularySetScreen> createState() => _VocabularySetScreenState();
}

class _VocabularySetScreenState extends State<VocabularySetScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() =>
      context.read<VocabularySetProvider>().loadSet(widget.setId);

  /// Mở màn khác rồi tải lại bộ khi quay về, vì trạng thái đã học có thể đổi.
  Future<void> _pushAndReload(String location, {Object? extra}) async {
    await context.push(location, extra: extra);
    if (mounted) await _load();
  }

  void _study(VocabularySetDetail detail) => _pushAndReload(
        Uri(
          path: '/vocabulary/study',
          queryParameters: {'level': detail.set.level},
        ).toString(),
        extra: detail.words,
      );

  /// Chạy một thao tác đánh dấu và báo kết quả bằng snackbar.
  Future<void> _runMarking(
    Future<int> Function(VocabularySetProvider provider) task,
    String Function(int count) success,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final count = await task(context.read<VocabularySetProvider>());
      if (count > 0) {
        messenger.showSnackBar(SnackBar(content: Text(success(count))));
      }
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Không cập nhật được, vui lòng thử lại.')),
      );
    }
  }

  void _markAllLearned() => _runMarking(
        (provider) => provider.markCurrentSetLearned(),
        (count) => 'Đã đánh dấu $count từ, các từ này sẽ vào lịch ôn tập.',
      );

  /// Bỏ đánh dấu cả bộ xoá luôn tiến độ ôn tập của các từ, nên hỏi lại trước.
  Future<void> _unmarkAll(VocabularySet set) async {
    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Bỏ đánh dấu cả bộ?'),
        content: Text(
          '${set.learnedCount} từ sẽ trở lại trạng thái chưa học và bị xoá '
          'khỏi lịch ôn tập.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Bỏ đánh dấu'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await _runMarking(
      (provider) => provider.unmarkCurrentSetLearned(),
      (count) => 'Đã bỏ đánh dấu $count từ.',
    );
  }

  void _toggleWord(Vocabulary word) => _runMarking(
        (provider) => provider.toggleWordLearned(word),
        (_) => word.isLearned
            ? 'Đã bỏ đánh dấu "${word.word}".'
            : 'Đã đánh dấu "${word.word}" là đã học.',
      );

  void _addToFlashcard(Vocabulary vocabulary) {
    AddToFlashcardDialog.show(
      context,
      front: vocabulary.word,
      back: vocabulary.meaning,
      frontSubtext: vocabulary.hiragana,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VocabularySetProvider>();
    final detail = provider.detailState.valueOrNull;
    // Chỉ lấy tiêu đề khi dữ liệu đang hiện đúng là bộ này.
    final title = detail?.set.id == widget.setId
        ? detail!.set.displayTitle
        : 'Bộ từ vựng';

    return AppScaffold(
      title: title,
      onRefresh: _load,
      body: AsyncView<VocabularySetDetail>(
        state: provider.detailState,
        onRetry: _load,
        builder: (context, detail) => ContentPaneList(
          builder: (context, padding) => ListView.builder(
            padding: padding,
            itemCount: detail.words.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: VocabularySetHeader(
                    set: detail.set,
                    isMarking: provider.isMarking,
                    onStudy: () => _study(detail),
                    onMarkAllLearned: _markAllLearned,
                    onUnmarkAll: () => _unmarkAll(detail.set),
                  ),
                );
              }

              final word = detail.words[index - 1];
              return VocabularySetWordTile(
                index: index,
                vocabulary: word,
                busy: provider.isMarking,
                onTap: () => _pushAndReload('/vocabulary/${word.id}'),
                onToggleLearned: () => _toggleWord(word),
                onAddToFlashcard: () => _addToFlashcard(word),
              );
            },
          ),
        ),
      ),
    );
  }
}
