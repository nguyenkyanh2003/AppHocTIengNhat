import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../shared/widgets/app_dialog.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/content_pane.dart';
import '../models/lesson.dart';
import '../models/lesson_progress.dart';
import '../providers/lesson_progress_provider.dart';
import '../providers/lesson_provider.dart';
import '../widgets/detail/lesson_hero.dart';
import '../widgets/detail/lesson_roadmap.dart';
import '../widgets/detail/lesson_section.dart';
import '../widgets/detail/lesson_word_grid.dart';
import '../widgets/lesson_action_button.dart';
import '../widgets/lesson_goals_card.dart';
import '../widgets/lesson_reference_lists.dart';
import '../widgets/video/lesson_video_section.dart';

/// Trang một bài học: bài nói về gì, gồm những bước nào, đã học tới đâu — và
/// một nút để vào học.
///
/// Video tình huống và từ vựng luôn xem lại được ở đây, dù đã hoàn thành bài
/// hay chưa; phần học có hướng dẫn nằm ở màn học.
class LessonDetailScreen extends StatefulWidget {
  const LessonDetailScreen({super.key, required this.lessonId});

  final String lessonId;

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await Future.wait([
      context.read<LessonProvider>().loadLessonDetail(widget.lessonId),
      context.read<LessonProgressProvider>().loadProgress(widget.lessonId),
    ]);
  }

  /// Tiến độ đang nằm trong provider có thể là của bài mở trước đó.
  LessonProgress? _progressOf(LessonProgressProvider provider) {
    final progress = provider.currentProgress;
    return progress?.lessonId == widget.lessonId ? progress : null;
  }

  Future<void> _study([int step = 0]) async {
    final query = step == 0 ? '' : '?step=$step';
    await context.push('/lessons/${widget.lessonId}/study$query');
  }

  Future<void> _confirmReset(LessonProgressProvider progress) async {
    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Học lại từ đầu?'),
        content: const Text('Dấu "đã nhớ" của các từ trong bài sẽ được xoá. XP đã nhận vẫn giữ nguyên.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Huỷ')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Đặt lại tiến độ')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await progress.resetProgress(widget.lessonId);
    messenger.showSnackBar(SnackBar(content: Text(ok ? 'Đã đặt lại tiến độ bài học.' : 'Chưa đặt lại được. Vui lòng thử lại.')));
  }

  @override
  Widget build(BuildContext context) {
    final lessons = context.watch<LessonProvider>();
    final progressProvider = context.watch<LessonProgressProvider>();
    final progress = _progressOf(progressProvider);

    return AppScaffold(
      title: 'Bài học',
      actions: [
        if (progress != null)
          PopupMenuButton<void>(
            tooltip: 'Tuỳ chọn',
            itemBuilder: (context) => [
              PopupMenuItem(onTap: () => _confirmReset(progressProvider), child: const Text('Đặt lại tiến độ')),
            ],
          ),
      ],
      body: AsyncView<LessonDetail>(
        state: lessons.detailState,
        onRetry: _load,
        builder: (context, detail) {
          if (detail.lesson.id != widget.lessonId) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: ContentPane(child: _content(detail, progress)),
                ),
              ),
              _actionBar(progress),
            ],
          );
        },
      ),
    );
  }

  Widget _content(LessonDetail detail, LessonProgress? progress) {
    final lesson = detail.lesson;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LessonHero(detail: detail, progress: progress),
        if (lesson.canDoGoals.isNotEmpty) ...[
          AppGap.xl,
          LessonGoalsCard(goals: lesson.canDoGoals),
        ],
        LessonSection(
          icon: Icons.route_outlined,
          title: 'Lộ trình bài học',
          caption: 'Chạm một bước để mở thẳng bước đó.',
          child: LessonRoadmap(detail: detail, progress: progress, onOpenStep: _study),
        ),
        if (lesson.videos.isNotEmpty)
          LessonSection(
            icon: Icons.play_circle_outline,
            title: 'Video tình huống',
            caption: lesson.videos.any((video) => video.transcript.isNotEmpty)
                ? 'Xem lại bất cứ lúc nào. Chạm vào câu thoại để nghe lại đoạn đó.'
                : 'Xem lại tình huống bất cứ lúc nào.',
            child: LessonVideoSection(videos: lesson.videos),
          ),
        if (detail.words.isNotEmpty)
          LessonSection(
            icon: Icons.style_outlined,
            title: 'Từ vựng trong bài',
            child: LessonWordGrid(
              words: detail.words,
              learnedIds: {...?progress?.learnedVocabularyIds},
              onOpen: (word) => context.push('/vocabulary/${word.id}'),
            ),
          ),
        if (detail.kanjis.isNotEmpty)
          LessonSection(
            icon: Icons.draw_outlined,
            title: 'Chữ Hán',
            child: LessonKanjiGrid(kanjis: detail.kanjis),
          ),
        if (detail.grammars.isNotEmpty)
          LessonSection(
            icon: Icons.account_tree_outlined,
            title: 'Ngữ pháp',
            child: LessonGrammarList(grammars: detail.grammars),
          ),
        AppGap.xl,
      ],
    );
  }

  Widget _actionBar(LessonProgress? progress) {
    final (label, icon) = switch (progress) {
      LessonProgress(isCompleted: true) => ('Học lại bài này', Icons.replay),
      LessonProgress(completedVocabularies: > 0) => ('Học tiếp', Icons.play_arrow_rounded),
      _ => ('Bắt đầu học', Icons.play_arrow_rounded),
    };
    return Material(
      elevation: AppElevation.medium,
      child: ContentPane(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: LessonActionButton(label: label, icon: icon, onPressed: _study),
      ),
    );
  }
}
