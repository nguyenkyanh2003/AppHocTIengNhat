import 'package:flutter/material.dart';
import '../../../app/theme/app_tokens.dart';
import '../models/exercise.dart';
import '../../../app/theme/app_typography.dart';

/// Xem lại từng câu: đáp án đã chọn và đáp án đúng.
class ExerciseAnswerReview extends StatelessWidget {
  const ExerciseAnswerReview({
    super.key,
    required this.exercise,
    required this.result,
  });

  final Exercise exercise;
  final ExerciseResult result;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: context.colors.textSecondary.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.article, color: context.colors.primary),
              const SizedBox(width: 8),
              const Text(
                'Chi tiết đáp án',
                style: TextStyle(
                  fontSize: AppTypography.subtitle,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...exercise.questions.asMap().entries.map((entry) {
            final index = entry.key;
            final question = entry.value;
            final userAnswer = result.answers.firstWhere(
              (ua) => ua.questionId == question.id,
              orElse: () => UserAnswer(
                questionId: question.id,
                answerId: '',
                isCorrect: false,
              ),
            );

            return _buildQuestionReview(
              context,
              index + 1,
              question,
              userAnswer,
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildQuestionReview(
    BuildContext context,
    int number,
    Question question,
    UserAnswer userAnswer,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (userAnswer.isCorrect ? AppColors.success : AppColors.error)
            .withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              userAnswer.isCorrect ? AppColors.success : context.colors.error,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: userAnswer.isCorrect
                      ? AppColors.success
                      : AppColors.error,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$number',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  question.content,
                  style: const TextStyle(
                    fontSize: AppTypography.body,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                userAnswer.isCorrect ? Icons.check_circle : Icons.cancel,
                color: userAnswer.isCorrect
                    ? AppColors.success
                    : context.colors.error,
                size: 28,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...question.answers.map((answer) {
            final isUserAnswer = answer.id == userAnswer.answerId;
            final isCorrectAnswer =
                answer.id == (userAnswer.correctAnswerId ?? '');

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isCorrectAnswer
                    ? AppColors.success.withValues(alpha: 0.12)
                    : (isUserAnswer && !isCorrectAnswer)
                        ? AppColors.error.withValues(alpha: 0.12)
                        : context.colors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isCorrectAnswer
                      ? AppColors.success
                      : (isUserAnswer && !isCorrectAnswer)
                          ? context.colors.error
                          : context.colors.border,
                  width: isCorrectAnswer || isUserAnswer ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  // Show check mark for correct answer, X mark for wrong selected answer
                  if (isCorrectAnswer)
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.check,
                          color: AppColors.onFill(AppColors.success), size: 16),
                    )
                  else if (isUserAnswer && !isCorrectAnswer)
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          color: Colors.white, size: 16),
                    )
                  else
                    const SizedBox(width: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      answer.content,
                      style: TextStyle(
                        fontSize: AppTypography.bodySmall,
                        fontWeight: isCorrectAnswer || isUserAnswer
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isCorrectAnswer
                            ? AppColors.success
                            : (isUserAnswer && !isCorrectAnswer)
                                ? context.colors.error
                                : context.colors.textPrimary,
                      ),
                    ),
                  ),
                  // Add label for correct/wrong answer
                  if (isCorrectAnswer)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Đúng',
                        style: TextStyle(
                          color: AppColors.onFill(AppColors.success),
                          fontSize: AppTypography.caption,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else if (isUserAnswer && !isCorrectAnswer)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Sai',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: AppTypography.caption,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
          if (question.explanation != null && question.explanation!.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.colors.primarySoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb,
                      color: context.colors.primaryStrong, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      question.explanation!,
                      style: TextStyle(
                        fontSize: AppTypography.caption,
                        color: context.colors.primaryStrong,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
