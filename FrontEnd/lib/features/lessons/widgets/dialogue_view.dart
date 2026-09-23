import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../models/dialogue_turn.dart';
import 'lesson_goals_card.dart';

/// Hiển thị một bài học tình huống: mục tiêu "làm được gì" và hội thoại của cảnh.
///
/// Lượt thoại được xếp so le trái/phải theo người nói để đọc như một đoạn hội
/// thoại thật, thay vì một danh sách câu phẳng.
class DialogueView extends StatelessWidget {
  final List<DialogueTurn> dialogue;
  final List<String> canDoGoals;

  /// Tắt để người học tự hiểu câu trước rồi mới xem nghĩa.
  final bool showTranslation;

  /// Có thì mỗi lượt thoại có nút nghe câu tiếng Nhật.
  final ValueChanged<DialogueTurn>? onSpeak;

  const DialogueView({
    super.key,
    required this.dialogue,
    this.canDoGoals = const [],
    this.showTranslation = true,
    this.onSpeak,
  });

  @override
  Widget build(BuildContext context) {
    // Người nói xuất hiện đầu tiên được coi là "phía bên kia" (nhân viên,
    // người bản xứ); người học thường là vai còn lại.
    final speakers = dialogue.map((turn) => turn.speaker).toSet().toList();
    final firstSpeaker = speakers.isEmpty ? '' : speakers.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (canDoGoals.isNotEmpty) LessonGoalsCard(goals: canDoGoals),
        if (canDoGoals.isNotEmpty) const SizedBox(height: AppSpacing.xl),
        if (dialogue.isNotEmpty) ...[
          const _SectionTitle(icon: Icons.forum_outlined, label: 'Hội thoại'),
          const SizedBox(height: AppSpacing.md),
          ...dialogue.map(
            (turn) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _TurnBubble(
                turn: turn,
                alignLeft: turn.speaker == firstSpeaker,
                showTranslation: showTranslation,
                onSpeak: onSpeak == null ? null : () => onSpeak!(turn),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SectionTitle({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.lesson),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _TurnBubble extends StatelessWidget {
  final DialogueTurn turn;
  final bool alignLeft;
  final bool showTranslation;
  final VoidCallback? onSpeak;

  const _TurnBubble({
    required this.turn,
    required this.alignLeft,
    required this.showTranslation,
    this.onSpeak,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bubbleColor = alignLeft
        ? AppColors.surfaceVariant
        : AppColors.primary.withValues(alpha: 0.12);

    return Row(
      mainAxisAlignment:
          alignLeft ? MainAxisAlignment.start : MainAxisAlignment.end,
      children: [
        Flexible(
          child: Column(
            crossAxisAlignment:
                alignLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
            children: [
              Text(
                turn.speaker,
                style: textTheme.labelMedium
                    ?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(
                          child: Text(
                            turn.textJa,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              height: 1.5,
                            ),
                          ),
                        ),
                        if (onSpeak != null)
                          IconButton(
                            onPressed: onSpeak,
                            tooltip: 'Nghe câu này',
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.volume_up_outlined,
                                size: 20, color: AppColors.primary),
                          ),
                      ],
                    ),
                    if (turn.reading.isNotEmpty &&
                        turn.reading != turn.textJa) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        turn.reading,
                        style: textTheme.bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                    if (showTranslation && turn.textVi.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        turn.textVi,
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
