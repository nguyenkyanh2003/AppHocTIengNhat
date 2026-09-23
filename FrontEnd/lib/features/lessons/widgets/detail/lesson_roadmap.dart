import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../models/lesson.dart';
import '../../models/lesson_progress.dart';
import '../../models/lesson_study_step.dart';
import '../../models/quick_quiz.dart';
import '../study_step_icon.dart';

/// Lộ trình của bài: các bước sẽ đi qua, nối với nhau như một con đường.
///
/// Người học thấy trước bài gồm những phần nhỏ nào và đang ở đâu; chạm một
/// bước để mở thẳng bước đó (ví dụ quay lại xem video).
class LessonRoadmap extends StatelessWidget {
  const LessonRoadmap({
    super.key,
    required this.detail,
    required this.progress,
    required this.onOpenStep,
  });

  final LessonDetail detail;
  final LessonProgress? progress;
  final ValueChanged<int> onOpenStep;

  String _subtitle(StudyStep step) {
    final lesson = detail.lesson;
    return switch (step.kind) {
      StudyStepKind.intro => 'Mục tiêu và nội dung bài',
      StudyStepKind.video => 'Video có lời thoại tiếng Nhật – tiếng Việt',
      StudyStepKind.dialogue => '${lesson.dialogue.length} câu thoại, bấm để nghe',
      StudyStepKind.vocabulary => progress == null
          ? '${detail.words.length} thẻ từ'
          : '${progress!.completedVocabularies}/${detail.words.length} từ đã nhớ',
      StudyStepKind.kanji => '${detail.kanjis.length} chữ Hán',
      StudyStepKind.grammar => '${detail.grammars.length} mẫu câu',
      StudyStepKind.quiz => '${buildQuickQuiz(detail.words).length} câu chọn nghĩa',
      StudyStepKind.finish => 'Nhận XP, rồi làm bài tập của bài',
    };
  }

  @override
  Widget build(BuildContext context) {
    final steps = buildStudySteps(detail);
    final completed = progress?.isCompleted ?? false;

    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          _RoadmapNode(
            step: steps[i],
            subtitle: _subtitle(steps[i]),
            state: completed
                ? _NodeState.done
                : i == 0
                    ? _NodeState.current
                    : _NodeState.upcoming,
            isLast: i == steps.length - 1,
            // Bước cuối là kết quả của cả phiên, không mở riêng được.
            onTap: steps[i].kind == StudyStepKind.finish ? null : () => onOpenStep(i),
          ),
      ],
    );
  }
}

enum _NodeState { done, current, upcoming }

class _RoadmapNode extends StatelessWidget {
  const _RoadmapNode({
    required this.step,
    required this.subtitle,
    required this.state,
    required this.isLast,
    required this.onTap,
  });

  final StudyStep step;
  final String subtitle;
  final _NodeState state;
  final bool isLast;
  final VoidCallback? onTap;

  static const double _node = 48;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final (Color fill, Color foreground) = switch (state) {
      _NodeState.done => (AppColors.success, Colors.white),
      _NodeState.current => (AppColors.primary, Colors.white),
      _NodeState.upcoming => (AppColors.surfaceVariant, AppColors.textSecondary),
    };

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.mdAll,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: _node,
              child: Column(
                children: [
                  Container(
                    width: _node,
                    height: _node,
                    decoration: BoxDecoration(
                      color: fill,
                      shape: BoxShape.circle,
                      // Mép đặc ở đáy như các khối "chunky" khác của app.
                      boxShadow: [BoxShadow(color: Color.lerp(fill, Colors.black, 0.2)!, offset: const Offset(0, 4))],
                    ),
                    child: Icon(state == _NodeState.done ? Icons.check_rounded : studyStepIcon(step.kind), color: foreground),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 4,
                        margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                        decoration: BoxDecoration(
                          color: state == _NodeState.done ? AppColors.success : AppColors.border,
                          borderRadius: AppRadius.pillAll,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            AppGap.md,
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(step.title, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    Text(subtitle, style: textTheme.bodySmall),
                  ],
                ),
              ),
            ),
            if (onTap != null) const Icon(Icons.chevron_right, color: AppColors.textDisabled),
          ],
        ),
      ),
    );
  }
}
