import 'package:flutter/material.dart';
import '../models/exercise.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/app_tokens.dart';

/// Một câu hỏi cùng các lựa chọn trả lời.
class ExerciseQuestionCard extends StatelessWidget {
  const ExerciseQuestionCard({
    super.key,
    required this.question,
    required this.index,
    required this.userAnswers,
    required this.selectAnswer,
  });

  final Question question;
  final int index;
  final Map<String, String> userAnswers;
  final void Function(String questionId, String answerId) selectAnswer;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
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
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primary,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: AppTypography.body,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Câu hỏi',
                        style: TextStyle(
                          fontSize: AppTypography.body,
                          fontWeight: FontWeight.bold,
                          color: context.colors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  question.content,
                  style: TextStyle(
                    fontSize: AppTypography.subtitle,
                    fontWeight: FontWeight.w500,
                    color: context.colors.textPrimary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...question.answers.asMap().entries.map((entry) {
            final answerIndex = entry.key;
            final answer = entry.value;
            final isSelected = userAnswers[question.id] == answer.id;

            return GestureDetector(
              onTap: () {
                selectAnswer(question.id, answer.id);
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? context.colors.primarySoft
                      : context.colors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? context.colors.primary
                        : context.colors.border,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? AppColors.primary
                            : context.colors.surface,
                        border: Border.all(
                          color: isSelected
                              ? context.colors.primary
                              : context.colors.textDisabled,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          String.fromCharCode(65 + answerIndex),
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : context.colors.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: AppTypography.bodySmall,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        answer.content,
                        style: TextStyle(
                          fontSize: AppTypography.body,
                          color: isSelected
                              ? context.colors.primaryStrong
                              : context.colors.textPrimary,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color: context.colors.primary,
                        size: 24,
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
