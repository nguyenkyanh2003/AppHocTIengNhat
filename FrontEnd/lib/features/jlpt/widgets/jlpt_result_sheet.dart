import 'package:flutter/material.dart';
import '../providers/jlpt_exam_provider.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/app_tokens.dart';

/// Bảng kết quả sau khi nộp đề.
void showJlptResultSheet(BuildContext context, JLPTExamProvider provider) {
  final result = provider.result!;
  final isPassed = result.passed;
  final color = isPassed ? AppColors.success : AppColors.error;
  final icon = isPassed ? Icons.check_circle : Icons.cancel;

  showModalBottomSheet(
    context: context,
    builder: (ctx) => SizedBox(
      height: 600,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    Icon(icon, size: 64, color: context.colors.readable(color)),
                    const SizedBox(height: 8),
                    Text(
                      isPassed ? 'Chúc mừng!' : 'Cố gắng lên',
                      style: TextStyle(
                          fontSize: AppTypography.headline,
                          fontWeight: FontWeight.bold,
                          color: context.colors.readable(color)),
                    ),
                    Text(
                      'Điểm: ${result.totalScore} / 100',
                      style: const TextStyle(fontSize: AppTypography.subtitle),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildScoreItem('Từ vựng', result.vocabScore),
              _buildScoreItem('Ngữ pháp', result.grammarScore),
              _buildScoreItem('Đọc hiểu', result.readingScore),
              _buildScoreItem('Nghe hiểu', result.listeningScore),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Đóng'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _buildScoreItem(String title, int score) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: AppTypography.body)),
        Text('$score',
            style: const TextStyle(
                fontSize: AppTypography.body, fontWeight: FontWeight.bold)),
      ],
    ),
  );
}
