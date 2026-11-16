import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/content_pane.dart';
import '../models/exercise.dart';
import '../providers/exercise_provider.dart';
import '../widgets/exercise_answer_review.dart';
import '../widgets/exercise_result_card.dart';

/// Kết quả một lần làm bài.
///
/// Mở lại được bằng URL: [resultId] nằm trên đường dẫn, và server trả kết quả
/// kèm đề đầy đủ (đáp án đúng, lời giải) nên một lần tải là đủ dựng cả phần
/// xem lại.
class ExerciseResultScreen extends StatefulWidget {
  const ExerciseResultScreen({super.key, required this.resultId});

  final String resultId;

  @override
  State<ExerciseResultScreen> createState() => _ExerciseResultScreenState();
}

class _ExerciseResultScreenState extends State<ExerciseResultScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() => context.read<ExerciseProvider>().loadResult(widget.resultId);

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ExerciseProvider>().resultOf(widget.resultId);
    if (state.valueOrNull case final result?) return _ResultView(result: result);
    return AppScaffold(
      title: 'Kết quả',
      body: ContentWidthLimit(
        child: AsyncView<ExerciseResult>(state: state, onRetry: _load, builder: (context, _) => const SizedBox()),
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({required this.result});

  final ExerciseResult result;

  @override
  Widget build(BuildContext context) {
    final exercise = result.exercise;
    return Scaffold(
      body: ContentWidthLimit(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [result.passed ? AppColors.success : AppColors.error, context.colors.background],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: AppSpacing.page,
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Về trang chủ',
                        icon: Icon(Icons.close, color: context.colors.textPrimary),
                        onPressed: () => context.go('/home'),
                      ),
                      Expanded(
                        child: Text(
                          'Kết quả làm bài',
                          style: TextStyle(
                            fontSize: AppTypography.title,
                            fontWeight: FontWeight.bold,
                            color: context.colors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      children: [
                        ExerciseResultCard(
                          isPassed: result.passed,
                          score: result.score,
                          correctCount: result.correctAnswers,
                          totalQuestions: result.totalQuestions,
                          timeSpent: result.timeSpent,
                        ),
                        // Bài tập đã bị xoá thì không còn đề để xem lại.
                        if (exercise != null) ...[
                          const SizedBox(height: AppSpacing.xl),
                          ExerciseAnswerReview(exercise: exercise, result: result),
                        ],
                        const SizedBox(height: AppSpacing.xl),
                        const _ResultActions(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultActions extends StatelessWidget {
  const _ResultActions();

  @override
  Widget build(BuildContext context) {
    const shape = RoundedRectangleBorder(borderRadius: AppRadius.mdAll);
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () => context.go('/home'),
            icon: const Icon(Icons.home),
            label: const Text('Về trang chủ'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: shape,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            // Màn làm bài đã được thay bằng màn này, nên quay lại là về danh sách.
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.list),
            label: const Text('Danh sách bài tập'),
            style: OutlinedButton.styleFrom(
              foregroundColor: context.colors.primary,
              side: BorderSide(color: context.colors.primary, width: 2),
              shape: shape,
            ),
          ),
        ),
      ],
    );
  }
}
