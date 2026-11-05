import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/exercise_provider.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/content_pane.dart';
import '../../../app/theme/app_typography.dart';
import '../widgets/exercise_result_card.dart';
import '../widgets/exercise_answer_review.dart';
import '../widgets/exercise_result_unavailable.dart';

/// Kết quả một lần làm bài.
///
/// Trang này mở lại được bằng URL: [resultId] nằm trên đường dẫn, và khi
/// provider chưa có sẵn dữ liệu (mở link trực tiếp, F5, tab mới) thì màn hình
/// tự tải kết quả theo mã, rồi tải đề bài theo `exerciseId` của kết quả để
/// dựng phần xem lại đáp án.
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureLoaded());
  }

  Future<void> _ensureLoaded() async {
    if (!mounted) return;
    final provider = context.read<ExerciseProvider>();

    if (provider.currentResult?.id != widget.resultId) {
      await provider.loadResultDetail(widget.resultId);
    }
    if (!mounted) return;

    final result = provider.currentResult;
    if (result == null) return;
    if (provider.currentExercise?.id != result.exerciseId) {
      await provider.loadExerciseDetail(result.exerciseId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ExerciseProvider>(
      builder: (context, provider, child) {
        final result = provider.currentResult;
        final exercise = provider.currentExercise;

        if (provider.isLoading && (result == null || exercise == null)) {
          return const AppScaffold(
            title: 'Kết quả',
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (result == null || exercise == null) {
          return AppScaffold(
            title: 'Kết quả',
            body: ContentWidthLimit(
              child: ExerciseResultUnavailable(onRetry: _ensureLoaded),
            ),
          );
        }

        final isPassed = result.passed;
        final score = result.score.toDouble();
        final correctCount = result.correctAnswers;
        final totalQuestions = result.totalQuestions;

        return Scaffold(
          body: ContentWidthLimit(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    isPassed ? AppColors.success : AppColors.error,
                    context.colors.background,
                  ],
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    _buildAppBar(context),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            ExerciseResultCard(
                                isPassed: isPassed,
                                score: score,
                                correctCount: correctCount,
                                totalQuestions: totalQuestions,
                                timeSpent: result.timeSpent),
                            const SizedBox(height: 24),
                            ExerciseAnswerReview(
                                exercise: exercise, result: result),
                            const SizedBox(height: 24),
                            _buildActionButtons(context),
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
      },
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.close, color: context.colors.textPrimary),
            onPressed: () {
              context.go('/home');
            },
          ),
          Text(
            'Kết quả làm bài',
            style: TextStyle(
              fontSize: AppTypography.title,
              fontWeight: FontWeight.bold,
              color: context.colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () {
              context.go('/home');
            },
            icon: const Icon(Icons.home),
            label: const Text('Về trang chủ'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: () {
              // Pop back to exercise list
              // Stack: Home → Exercise List → Exercise Result (detail was replaced)
              // So we only need to pop 1 time to return to Exercise List
              Navigator.pop(context);
            },
            icon: const Icon(Icons.list),
            label: const Text('Danh sách bài tập'),
            style: OutlinedButton.styleFrom(
              foregroundColor: context.colors.primary,
              side: BorderSide(color: context.colors.primary, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
