import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/exercise_provider.dart';
import '../models/exercise.dart';
import '../../../shared/widgets/content_pane.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/app_tokens.dart';

class ExerciseHistoryScreen extends StatefulWidget {
  const ExerciseHistoryScreen({super.key});

  @override
  State<ExerciseHistoryScreen> createState() => _ExerciseHistoryScreenState();
}

class _ExerciseHistoryScreenState extends State<ExerciseHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHistory();
    });
  }

  Future<void> _loadHistory() async {
    await context.read<ExerciseProvider>().loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Lịch sử làm bài',
      onRefresh: _loadHistory,
      body: ContentWidthLimit(
        child: RefreshIndicator(
          onRefresh: _loadHistory,
          child: _buildHistoryList(),
        ),
      ),
    );
  }

  Widget _buildHistoryList() {
    return Consumer<ExerciseProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                const SizedBox(height: 16),
                const Text(
                  'Đã xảy ra lỗi',
                  style: TextStyle(
                    fontSize: AppTypography.subtitle,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _loadHistory,
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }

        if (provider.history.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 80, color: AppColors.textDisabled),
                SizedBox(height: 16),
                Text(
                  'Chưa có lịch sử làm bài',
                  style: TextStyle(
                    fontSize: AppTypography.subtitle,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Hãy thử làm một bài tập nhé!',
                  style: TextStyle(
                    fontSize: AppTypography.bodySmall,
                    color: AppColors.textDisabled,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: provider.history.length,
          itemBuilder: (context, index) {
            final result = provider.history[index];
            return _buildHistoryCard(result);
          },
        );
      },
    );
  }

  Widget _buildHistoryCard(ExerciseResult result) {
    final isPassed = result.passed;
    final score = result.score;

    // Get exercise info from the result
    String exerciseTitle = result.exerciseTitle ?? 'Bài tập đã hoàn thành';
    String exerciseLevel = result.exerciseLevel ?? '';
    String exerciseType = result.exerciseType ?? '';

    final completedAt = result.createdAt;
    final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(completedAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPassed ? AppColors.success : AppColors.error,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.textSecondary.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          // Trước đây chỗ này chỉ nạp kết quả vào provider rồi dừng, vì chưa
          // có màn kết quả mở được bằng mã. Nay đã có đường dẫn thật.
          onTap: () => context.push('/exercise/result/${result.id}'),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isPassed
                              ? [AppColors.success, AppColors.success]
                              : [AppColors.error, AppColors.error],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '${score.toInt()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: AppTypography.headline,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exerciseTitle,
                            style: const TextStyle(
                              fontSize: AppTypography.body,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (exerciseLevel.isNotEmpty) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.warning,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    exerciseLevel,
                                    style: const TextStyle(
                                      fontSize: AppTypography.caption,
                                      color: AppColors.warning,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              if (exerciseType.isNotEmpty)
                                Text(
                                  exerciseType,
                                  style: const TextStyle(
                                    fontSize: AppTypography.caption,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isPassed
                            ? AppColors.success
                            : AppColors.error,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isPassed ? 'Đạt' : 'Chưa đạt',
                        style: TextStyle(
                          color: isPassed
                              ? AppColors.success
                              : AppColors.error,
                          fontWeight: FontWeight.bold,
                          fontSize: AppTypography.caption,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      _buildStatChip(
                        Icons.check_circle,
                        'Đúng',
                        '${result.correctAnswers}',
                        AppColors.success,
                      ),
                      const SizedBox(width: 12),
                      _buildStatChip(
                        Icons.quiz,
                        'Tổng',
                        '${result.totalQuestions}',
                        AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      _buildStatChip(
                        Icons.timer,
                        'Thời gian',
                        _formatTime(result.timeSpent),
                        Colors.purple,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 14, color: AppColors.textDisabled),
                    const SizedBox(width: 4),
                    Text(
                      formattedDate,
                      style: const TextStyle(
                        fontSize: AppTypography.caption,
                        color: AppColors.textDisabled,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: AppTypography.bodySmall,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: AppTypography.caption,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }
}
