import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../shared/widgets/app_dialog.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/content_pane.dart';
import '../../streaks/providers/streak_provider.dart';
import '../models/lesson.dart';
import '../models/lesson_study_step.dart';
import '../providers/lesson_progress_provider.dart';
import '../providers/lesson_provider.dart';
import '../providers/lesson_study_session.dart';
import '../widgets/lesson_action_button.dart';
import '../widgets/study/study_finish_step.dart';
import '../widgets/study/study_progress_header.dart';
import '../widgets/study/study_step_view.dart';

/// Phiên học một bài, chế độ tập trung: mỗi bước một việc, một nút đi tiếp.
///
/// Mở đầu → từng cảnh video → hội thoại → thẻ từ vựng → kiểm tra nhanh →
/// hoàn thành (chỉ gồm phần bài thật sự có). [initialStep] cho phép mở thẳng
/// một bước từ lộ trình ở màn chi tiết.
class LessonStudyScreen extends StatefulWidget {
  const LessonStudyScreen({super.key, required this.lessonId, this.initialStep = 0});

  final String lessonId;
  final int initialStep;

  @override
  State<LessonStudyScreen> createState() => _LessonStudyScreenState();
}

class _LessonStudyScreenState extends State<LessonStudyScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final lessons = context.read<LessonProvider>();
      if (lessons.currentLessonDetail?.lesson.id != widget.lessonId) {
        lessons.loadLessonDetail(widget.lessonId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final lessons = context.watch<LessonProvider>();
    return Scaffold(
      body: SafeArea(
        child: AsyncView<LessonDetail>(
          state: lessons.detailState,
          onRetry: () => lessons.loadLessonDetail(widget.lessonId),
          builder: (context, detail) {
            // Chi tiết của bài khác còn sót trong provider: chờ bản đúng.
            if (detail.lesson.id != widget.lessonId) {
              return const Center(child: CircularProgressIndicator());
            }
            return ChangeNotifierProvider(
              create: (_) => LessonStudySession(detail: detail, initialStep: widget.initialStep)..start(),
              child: const _StudyBody(),
            );
          },
        ),
      ),
    );
  }
}

class _StudyBody extends StatefulWidget {
  const _StudyBody();

  @override
  State<_StudyBody> createState() => _StudyBodyState();
}

class _StudyBodyState extends State<_StudyBody> {
  int? _xpBefore;
  int? _xpEarned;

  @override
  void initState() {
    super.initState();
    // Đọc số dư XP lúc bắt đầu để cuối bài hiện đúng số XP server đã cộng,
    // thay vì tự tính và có thể nói sai.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final streak = context.read<StreakProvider>();
      await streak.loadStreak();
      _xpBefore = streak.currentStreak?.totalXP;
    });
  }

  Future<void> _afterSaved(LessonStudySession session) async {
    if (!session.completion.hasData) return;
    final streak = context.read<StreakProvider>();
    final progress = context.read<LessonProgressProvider>();
    await Future.wait([streak.loadStreak(), progress.loadProgress(session.lessonId)]);
    final after = streak.currentStreak?.totalXP;
    if (mounted && _xpBefore != null && after != null) {
      setState(() => _xpEarned = (after - _xpBefore!).clamp(0, 1 << 30));
    }
  }

  Future<void> _continue(LessonStudySession session) async {
    await session.next();
    if (session.isFinished) await _afterSaved(session);
  }

  void _leave(LessonStudySession session) {
    context.read<LessonProgressProvider>().loadProgress(session.lessonId);
    context.pop();
  }

  Future<void> _close(LessonStudySession session) async {
    if (session.index == 0 || session.isFinished) return _leave(session);
    final leave = await showAppDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rời bài học?'),
        content: const Text('Những từ bạn đã bấm "Đã nhớ" vẫn được lưu. Lần sau bạn có thể học tiếp bài này.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Học tiếp')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Rời bài')),
        ],
      ),
    );
    if (leave == true && mounted) _leave(session);
  }

  void _showMessage(LessonStudySession session) {
    final message = session.consumeMessage();
    if (message != null) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Bước video cần khung rộng để lời thoại nằm cạnh video; các bước đọc giữ
  /// khung hẹp cho dòng chữ dễ theo.
  double _contentWidth(LessonStudySession session) =>
      session.step.kind == StudyStepKind.video ? AppContentWidth.detail : AppContentWidth.reading;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<LessonStudySession>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showMessage(session);
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close(session);
      },
      child: Column(
        children: [
          StudyProgressHeader(steps: session.steps, index: session.index, onClose: () => _close(session)),
          Expanded(
            child: SingleChildScrollView(
              child: ContentPane(
                maxWidth: _contentWidth(session),
                child: AnimatedSwitcher(
                  duration: MediaQuery.of(context).disableAnimations ? Duration.zero : AppDurations.normal,
                  child: KeyedSubtree(
                    key: ValueKey(session.index),
                    child: session.isFinished ? _finish(session) : StudyStepView(session: session),
                  ),
                ),
              ),
            ),
          ),
          if (!session.isFinished) _bottomBar(session),
        ],
      ),
    );
  }

  Widget _finish(LessonStudySession session) => StudyFinishStep(
        completion: session.completion,
        xpEarned: _xpEarned,
        learnedWords: session.learnedCount,
        totalWords: session.detail.words.length,
        quizCorrect: session.correctAnswers,
        quizTotal: session.quiz.length,
        onRetry: () async {
          await session.complete();
          await _afterSaved(session);
        },
        onExercises: () => context.pushReplacement(Uri(
          path: '/exercise',
          queryParameters: {'lessonId': session.lessonId, 'lessonTitle': session.detail.lesson.title},
        ).toString()),
        onDone: () => _leave(session),
      );

  Widget _bottomBar(LessonStudySession session) {
    final nextIsFinish = session.steps[session.index + 1].kind == StudyStepKind.finish;
    final label = session.index == 0
        ? 'Bắt đầu học'
        : !session.canContinue
            ? 'Trả lời hết để tiếp tục'
            : nextIsFinish
                ? 'Hoàn thành bài học'
                : 'Tiếp tục';

    return Material(
      elevation: AppElevation.medium,
      child: ContentPane(
        maxWidth: _contentWidth(session),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            if (session.index > 0) ...[
              IconButton.outlined(
                onPressed: session.back,
                tooltip: 'Bước trước',
                icon: const Icon(Icons.arrow_back),
              ),
              AppGap.md,
            ],
            Expanded(
              child: LessonActionButton(
                label: label,
                icon: nextIsFinish ? Icons.flag : null,
                onPressed: session.canContinue ? () => _continue(session) : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
