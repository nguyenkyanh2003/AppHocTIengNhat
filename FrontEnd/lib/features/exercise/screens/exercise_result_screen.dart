import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/exercise_provider.dart';
import '../../../app/theme/app_tokens.dart';
import '../models/exercise.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/content_pane.dart';

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
              child: _ResultUnavailable(onRetry: _ensureLoaded),
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
                    isPassed ? Colors.green.shade50 : Colors.red.shade50,
                    Colors.white,
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
                            _buildResultCard(
                              isPassed,
                              score,
                              correctCount,
                              totalQuestions,
                              result.timeSpent,
                            ),
                            const SizedBox(height: 24),
                            _buildAnswerReview(exercise, result),
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
            icon: const Icon(Icons.close, color: Colors.black87),
            onPressed: () {
              context.go('/home');
            },
          ),
          const Text(
            'Kết quả làm bài',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(
    bool isPassed,
    double score,
    int correctCount,
    int totalQuestions,
    int timeSpent,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPassed
              ? [Colors.green.shade400, Colors.green.shade600]
              : [Colors.red.shade400, Colors.red.shade600],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color:
                (isPassed ? Colors.green : Colors.red).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            isPassed ? Icons.emoji_events : Icons.refresh,
            color: Colors.white,
            size: 80,
          ),
          const SizedBox(height: 16),
          Text(
            isPassed ? 'Chúc mừng! Bạn đã đạt' : 'Chưa đạt',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${score.toStringAsFixed(0)} điểm',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  Icons.check_circle,
                  'Đúng',
                  '$correctCount',
                ),
                Container(width: 1, height: 40, color: Colors.white30),
                _buildStatItem(
                  Icons.cancel,
                  'Sai',
                  '${totalQuestions - correctCount}',
                ),
                Container(width: 1, height: 40, color: Colors.white30),
                _buildStatItem(
                  Icons.timer,
                  'Thời gian',
                  _formatTime(timeSpent),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  Widget _buildAnswerReview(Exercise exercise, ExerciseResult result) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.article, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                'Chi tiết đáp án',
                style: TextStyle(
                  fontSize: 18,
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
    int number,
    Question question,
    UserAnswer userAnswer,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: userAnswer.isCorrect ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: userAnswer.isCorrect
              ? Colors.green.shade200
              : Colors.red.shade200,
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
                  color: userAnswer.isCorrect ? Colors.green : Colors.red,
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
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                userAnswer.isCorrect ? Icons.check_circle : Icons.cancel,
                color: userAnswer.isCorrect ? Colors.green : Colors.red,
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
                    ? Colors.green.shade100
                    : (isUserAnswer && !isCorrectAnswer)
                        ? Colors.red.shade100
                        : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isCorrectAnswer
                      ? Colors.green
                      : (isUserAnswer && !isCorrectAnswer)
                          ? Colors.red
                          : Colors.grey.shade300,
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
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check,
                          color: Colors.white, size: 16),
                    )
                  else if (isUserAnswer && !isCorrectAnswer)
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: Colors.red,
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
                        fontSize: 15,
                        fontWeight: isCorrectAnswer || isUserAnswer
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isCorrectAnswer
                            ? Colors.green.shade900
                            : (isUserAnswer && !isCorrectAnswer)
                                ? Colors.red.shade900
                                : Colors.black87,
                      ),
                    ),
                  ),
                  // Add label for correct/wrong answer
                  if (isCorrectAnswer)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Đúng',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else if (isUserAnswer && !isCorrectAnswer)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Sai',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
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
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      question.explanation!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue.shade900,
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
              backgroundColor: Colors.blue,
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
              foregroundColor: Colors.blue,
              side: const BorderSide(color: Colors.blue, width: 2),
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

/// Trạng thái khi không lấy được kết quả — thay cho một dòng chữ cụt.
class _ResultUnavailable extends StatelessWidget {
  const _ResultUnavailable({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ContentPane(
        maxWidth: AppContentWidth.form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.assignment_late_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            AppGap.lg,
            Text(
              'Không mở được kết quả này',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            AppGap.sm,
            const Text(
              'Kết quả có thể đã bị xoá, hoặc không thuộc về tài khoản này.',
              textAlign: TextAlign.center,
            ),
            AppGap.xl,
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.sm,
              alignment: WrapAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Thử lại'),
                ),
                FilledButton.icon(
                  onPressed: () => context.go('/exercise-history'),
                  icon: const Icon(Icons.history),
                  label: const Text('Lịch sử làm bài'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
