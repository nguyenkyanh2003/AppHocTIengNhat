import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../shared/widgets/chunky_card.dart';
import '../../models/quick_quiz.dart';

/// Kiểm tra nhanh cuối bài: nhìn từ, chọn nghĩa. Chọn xong là biết đúng sai
/// ngay, kèm đáp án đúng — phản hồi tức thì là thứ giữ nhịp học.
class StudyQuizStep extends StatelessWidget {
  const StudyQuizStep({
    super.key,
    required this.questions,
    required this.answerOf,
    required this.onAnswer,
  });

  final List<QuizQuestion> questions;
  final int? Function(int question) answerOf;
  final void Function(int question, int choice) onAnswer;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final answered = [for (var q = 0; q < questions.length; q++) answerOf(q)].whereType<int>().length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Chọn nghĩa đúng của mỗi từ. Đã trả lời $answered/${questions.length} câu.',
            style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
        AppGap.lg,
        for (var q = 0; q < questions.length; q++) ...[
          _QuestionCard(
            number: q + 1,
            question: questions[q],
            chosen: answerOf(q),
            onChoose: (choice) => onAnswer(q, choice),
          ),
          AppGap.lg,
        ],
      ],
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.number,
    required this.question,
    required this.chosen,
    required this.onChoose,
  });

  final int number;
  final QuizQuestion question;
  final int? chosen;
  final ValueChanged<int> onChoose;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final answered = chosen != null;

    return ChunkyCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Câu $number', style: textTheme.labelLarge?.copyWith(color: AppColors.textSecondary)),
          AppGap.xs,
          Text(question.word.word, style: AppTypography.japaneseDisplay(size: AppTypography.headline)),
          Text(question.word.hiragana, style: AppTypography.japaneseReading()),
          AppGap.md,
          for (var i = 0; i < question.choices.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _Choice(
                label: question.choices[i],
                state: !answered
                    ? _ChoiceState.open
                    : question.isCorrect(i)
                        ? _ChoiceState.correct
                        : i == chosen
                            ? _ChoiceState.wrong
                            : _ChoiceState.dimmed,
                onTap: answered ? null : () => onChoose(i),
              ),
            ),
          if (answered)
            Text(
              question.isCorrect(chosen!) ? 'Chính xác!' : 'Chưa đúng — nghĩa đúng được tô xanh.',
              style: textTheme.titleSmall?.copyWith(
                color: question.isCorrect(chosen!) ? AppColors.success : AppColors.error,
              ),
            ),
        ],
      ),
    );
  }
}

enum _ChoiceState { open, correct, wrong, dimmed }

class _Choice extends StatelessWidget {
  const _Choice({required this.label, required this.state, required this.onTap});

  final String label;
  final _ChoiceState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (Color border, Color fill, IconData? icon) = switch (state) {
      _ChoiceState.correct => (AppColors.success, AppColors.success.withValues(alpha: 0.12), Icons.check_circle),
      _ChoiceState.wrong => (AppColors.error, AppColors.error.withValues(alpha: 0.1), Icons.cancel),
      _ChoiceState.dimmed => (AppColors.border, AppColors.surface, null),
      _ChoiceState.open => (AppColors.border, AppColors.surface, null),
    };

    return Material(
      color: fill,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll, side: BorderSide(color: border, width: 2)),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.mdAll,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: state == _ChoiceState.dimmed ? AppColors.textDisabled : AppColors.textPrimary,
                      ),
                ),
              ),
              if (icon != null) Icon(icon, color: border),
            ],
          ),
        ),
      ),
    );
  }
}
