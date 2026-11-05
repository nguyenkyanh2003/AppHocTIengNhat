import 'package:flutter/material.dart';
import 'dart:async';
import '../models/exercise.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/app_tokens.dart';

/// Đồng hồ và các nút chuyển câu, nộp bài.
class ExerciseBottomBar extends StatelessWidget {
  const ExerciseBottomBar({
    super.key,
    required this.exercise,
    required this.timeString,
    required this.pageController,
    required this.currentQuestionIndex,
    required this.isSubmitting,
    required this.submitExercise,
  });

  final Exercise exercise;
  final String timeString;
  final PageController pageController;
  final int currentQuestionIndex;
  final bool isSubmitting;
  final Future<void> Function() submitExercise;

  @override
  Widget build(BuildContext context) {
    final isFirstQuestion = currentQuestionIndex == 0;
    final isLastQuestion =
        currentQuestionIndex == exercise.questions.length - 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        boxShadow: [
          BoxShadow(
            color: context.colors.textSecondary.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Timer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: context.colors.primarySoft,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.colors.primarySoft),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.timer,
                    color: context.colors.primaryStrong, size: 20),
                const SizedBox(width: 8),
                Text(
                  timeString,
                  style: TextStyle(
                    fontSize: AppTypography.body,
                    fontWeight: FontWeight.bold,
                    color: context.colors.primaryStrong,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Navigation buttons
          Row(
            children: [
              // Previous button
              if (!isFirstQuestion)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Câu trước'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.colors.primaryStrong,
                      side: BorderSide(color: context.colors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              if (!isFirstQuestion) const SizedBox(width: 12),
              // Next or Submit button
              Expanded(
                flex: isFirstQuestion ? 1 : 1,
                child: ElevatedButton.icon(
                  onPressed: isSubmitting
                      ? null
                      : () {
                          if (isLastQuestion) {
                            submitExercise();
                          } else {
                            pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                  icon: isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(
                          isLastQuestion ? Icons.check : Icons.arrow_forward),
                  label: Text(isLastQuestion ? 'Nộp bài' : 'Câu tiếp'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isLastQuestion
                        ? AppColors.successStrong
                        : AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
