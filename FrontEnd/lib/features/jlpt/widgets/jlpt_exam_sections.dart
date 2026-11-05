import 'package:flutter/material.dart';
import '../providers/jlpt_exam_provider.dart';
import '../models/jlpt_models.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/app_tokens.dart';

/// Các dòng của một phần thi gồm câu hỏi rời.
List<Widget> buildJlptSection(BuildContext context, String title,
    List<JLPTQuestion> questions, String keyPrefix, JLPTExamProvider provider,
    {required int startIndex}) {
  if (questions.isEmpty) return [];
  return [
    Padding(
      padding: const EdgeInsets.all(12),
      child: Text(title,
          style: const TextStyle(
              fontSize: AppTypography.subtitle, fontWeight: FontWeight.bold)),
    ),
    ...questions.asMap().entries.map((entry) {
      final idx = entry.key;
      final q = entry.value;
      final key = '$keyPrefix-$idx';
      final selected = provider.answers[key];
      final solutionIdx = startIndex + idx;
      final hasResult =
          provider.result != null && provider.solutions.length > solutionIdx;
      final solution = hasResult ? provider.solutions[solutionIdx] : null;
      final correctIdx = solution?.correctAnswer;
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${idx + 1}. ${q.questionText}'),
              const SizedBox(height: 8),
              ...q.choices.asMap().entries.map((c) {
                final cid = c.key;
                final isUserChoice = selected == cid;
                final isCorrectChoice = hasResult && correctIdx == cid;
                Color? fill;
                if (hasResult) {
                  if (isCorrectChoice) {
                    fill = AppColors.success.withValues(alpha: 0.12);
                  } else if (isUserChoice) {
                    fill = AppColors.error.withValues(alpha: 0.12);
                  }
                }
                return RadioListTile<int>(
                  value: cid,
                  groupValue: selected,
                  onChanged: provider.hasSubmitted
                      ? null
                      : (v) => provider.setAnswer(key, v ?? 0),
                  title: Text(c.value),
                  activeColor:
                      hasResult && isCorrectChoice ? AppColors.success : null,
                  tileColor: fill,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  secondary: hasResult
                      ? Icon(
                          isCorrectChoice
                              ? Icons.check_circle_outline
                              : (isUserChoice
                                  ? Icons.cancel_outlined
                                  : Icons.radio_button_unchecked),
                          color: isCorrectChoice
                              ? AppColors.success
                              : (isUserChoice
                                  ? context.colors.error
                                  : context.colors.textSecondary),
                        )
                      : null,
                );
              }).toList(),
              if (hasResult && solution?.explanation != null) ...[
                const Divider(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lightbulb_outline,
                        size: 20,
                        color: context.colors.readable(AppColors.warning)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        solution!.explanation!,
                        style: TextStyle(
                            fontSize: AppTypography.caption,
                            color: context.colors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      );
    }).toList(),
  ];
}

/// Các dòng của một phần thi gồm nhóm câu hỏi và file nghe.
List<Widget> buildJlptGroupSection(BuildContext context, String title,
    List<JLPTGroupQuestion> groups, String keyPrefix, JLPTExamProvider provider,
    {required int startIndex,
    required Widget Function(String audioPath, String audioName) audioBar}) {
  if (groups.isEmpty) return [];

  final widgets = <Widget>[];

  // Tìm file audio chung cho section (chỉ lấy từ group đầu tiên có audio)
  String? sectionAudio;
  String? sectionAudioName;
  for (var g in groups) {
    if (g.groupAudio != null && g.groupAudio!.isNotEmpty) {
      sectionAudio = g.groupAudio;
      sectionAudioName = g.groupAudio!.split('/').last;
      break;
    }
  }

  // Header với audio player widget (nếu có)
  widgets.add(
    Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: AppTypography.subtitle,
                  fontWeight: FontWeight.bold)),
          if (sectionAudio != null) audioBar(sectionAudio, sectionAudioName!),
        ],
      ),
    ),
  );

  int questionCounter = startIndex;

  for (var groupIdx = 0; groupIdx < groups.length; groupIdx++) {
    final group = groups[groupIdx];

    // Hiển thị nội dung nhóm (bài đọc) - KHÔNG hiện audio ở đây
    widgets.add(
      Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        color: context.colors.primarySoft,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mondai ${group.mondai}',
                style: const TextStyle(
                    fontSize: AppTypography.body, fontWeight: FontWeight.bold),
              ),
              if (group.groupContent != null &&
                  group.groupContent!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  group.groupContent!,
                  style: const TextStyle(
                      fontSize: AppTypography.bodySmall, height: 1.6),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    // Hiển thị các câu hỏi trong nhóm
    for (var qIdx = 0; qIdx < group.questions.length; qIdx++) {
      final q = group.questions[qIdx];
      final key = '$keyPrefix-$groupIdx-$qIdx';
      final selected = provider.answers[key];
      final solutionIdx = questionCounter;
      final hasResult =
          provider.result != null && provider.solutions.length > solutionIdx;
      final solution = hasResult ? provider.solutions[solutionIdx] : null;
      final correctIdx = solution?.correctAnswer;

      widgets.add(
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(q.questionText.isNotEmpty
                    ? q.questionText
                    : 'Câu ${qIdx + 1}'),
                const SizedBox(height: 8),
                ...q.choices.asMap().entries.map((c) {
                  final cid = c.key;
                  final isUserChoice = selected == cid;
                  final isCorrectChoice = hasResult && correctIdx == cid;
                  Color? fill;
                  if (hasResult) {
                    if (isCorrectChoice) {
                      fill = AppColors.success.withValues(alpha: 0.12);
                    } else if (isUserChoice) {
                      fill = AppColors.error.withValues(alpha: 0.12);
                    }
                  }
                  return RadioListTile<int>(
                    value: cid,
                    groupValue: selected,
                    onChanged: provider.hasSubmitted
                        ? null
                        : (v) => provider.setAnswer(key, v ?? 0),
                    title: Text(c.value),
                    activeColor:
                        hasResult && isCorrectChoice ? AppColors.success : null,
                    tileColor: fill,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    secondary: hasResult
                        ? Icon(
                            isCorrectChoice
                                ? Icons.check_circle_outline
                                : (isUserChoice
                                    ? Icons.cancel_outlined
                                    : Icons.radio_button_unchecked),
                            color: isCorrectChoice
                                ? AppColors.success
                                : (isUserChoice
                                    ? context.colors.error
                                    : context.colors.textSecondary),
                          )
                        : null,
                  );
                }).toList(),
                if (hasResult && solution?.explanation != null) ...[
                  const Divider(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lightbulb_outline,
                          size: 20,
                          color: context.colors.readable(AppColors.warning)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          solution!.explanation!,
                          style: TextStyle(
                              fontSize: AppTypography.caption,
                              color: context.colors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      );

      questionCounter++;
    }
  }

  return widgets;
}
