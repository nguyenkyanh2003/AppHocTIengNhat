import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../core/audio/audio_service.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/content_pane.dart';
import '../../../shared/widgets/async_view.dart';
import '../../flashcards/widgets/add_to_flashcard_dialog.dart';
import '../models/vocabulary.dart';
import '../providers/vocabulary_provider.dart';
import '../widgets/vocabulary_examples.dart';
import '../widgets/vocabulary_headline.dart';

/// Chi tiết một từ vựng: cách đọc, nghĩa, ngữ cảnh, ví dụ và trạng thái đã học.
class VocabularyDetailScreen extends StatefulWidget {
  const VocabularyDetailScreen({super.key, required this.vocabularyId});

  final String vocabularyId;

  @override
  State<VocabularyDetailScreen> createState() => _VocabularyDetailScreenState();
}

class _VocabularyDetailScreenState extends State<VocabularyDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() =>
      context.read<VocabularyProvider>().loadVocabularyDetail(
            widget.vocabularyId,
          );

  Future<void> _play(String? url) async {
    if (url == null) return;
    final messenger = ScaffoldMessenger.of(context);

    try {
      await AudioService().playAudio(url);
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Không phát được âm thanh.')),
      );
    }
  }

  Future<void> _toggleLearned(Vocabulary vocabulary) async {
    final provider = context.read<VocabularyProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final wasLearned = vocabulary.isLearned;

    try {
      if (wasLearned) {
        await provider.unmarkAsLearned(widget.vocabularyId);
      } else {
        await provider.markAsLearned(widget.vocabularyId);
      }

      await provider.loadVocabularyDetail(widget.vocabularyId);

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            wasLearned
                ? 'Đã bỏ đánh dấu đã học.'
                : 'Đã đánh dấu là đã học, từ này sẽ vào lịch ôn tập.',
          ),
        ),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Không cập nhật được trạng thái học.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VocabularyProvider>();
    final vocabulary = provider.selectedVocabulary;

    return AppScaffold(
      title: vocabulary?.word ?? 'Từ vựng',
      actions: [
        if (vocabulary != null)
          IconButton(
            icon: const Icon(Icons.add_card),
            tooltip: 'Thêm vào Flashcard',
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
        builder: (context, item) => ContentPaneList(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.lg,
          ),
          builder: (context, padding) => ListView(
            padding: padding,
            children: [
              VocabularyHeadline(
                vocabulary: item,
                onPlayAudio: () => _play(item.audioUrl),
              ),
              if (item.usageContext != null)
                VocabularyUsageContext(usageContext: item.usageContext!),
              if (item.examples.isNotEmpty)
                VocabularyExamples(
                  examples: item.examples,
                  onPlayAudio: (example) => _play(example.audioUrl),
                ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
      floatingActionButton: vocabulary == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _toggleLearned(vocabulary),
              backgroundColor: vocabulary.isLearned
                  ? AppColors.success
                  : AppColors.textSecondary,
              icon: Icon(
                vocabulary.isLearned
                    ? Icons.check_circle
                    : Icons.circle_outlined,
                color: Colors.white,
              ),
              label: Text(
                vocabulary.isLearned ? 'Đã học' : 'Chưa học',
                style: const TextStyle(color: Colors.white),
              ),
            ),
    );
  }
}
