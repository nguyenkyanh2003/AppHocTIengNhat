import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/audio/audio_source_resolver.dart';
import '../models/jlpt_practice_question.dart';

/// Một câu luyện nhanh: chọn đáp án là biết đúng sai và xem được lời giải.
class JlptPracticeQuestionCard extends StatelessWidget {
  const JlptPracticeQuestionCard({
    super.key,
    required this.number,
    required this.question,
    required this.selected,
    required this.onSelect,
  });

  final int number;
  final JlptPracticeQuestion question;
  final int? selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final answered = selected != null;
    final explanation = question.explanation;
    final transcript = question.transcript;
    final passage = question.passage;
    final audioUrl = question.audioUrl;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (passage != null && passage.isNotEmpty) ...[
              Text(passage),
              const SizedBox(height: AppSpacing.md),
            ],
            if (audioUrl != null) ...[
              _PracticeAudioButton(url: audioUrl),
              const SizedBox(height: AppSpacing.md),
            ],
            Text(
              '$number. ${question.questionText}',
              style: const TextStyle(
                fontSize: AppTypography.body,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            for (var index = 0; index < question.choices.length; index += 1)
              _ChoiceTile(
                text: question.choices[index],
                isSelected: selected == index,
                isCorrect: question.correctAnswer == index,
                answered: answered,
                onTap: () => onSelect(index),
              ),
            if (answered && explanation != null && explanation.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Giải thích: $explanation',
                style: TextStyle(
                  fontSize: AppTypography.bodySmall,
                  color: context.colors.textSecondary,
                ),
              ),
            ],
            if (answered && transcript != null && transcript.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Lời thoại: $transcript',
                style: TextStyle(
                  fontSize: AppTypography.bodySmall,
                  color: context.colors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.text,
    required this.isSelected,
    required this.isCorrect,
    required this.answered,
    required this.onTap,
  });

  final String text;
  final bool isSelected;
  final bool isCorrect;
  final bool answered;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color? tone = !answered
        ? null
        : isCorrect
            ? AppColors.success
            : isSelected
                ? AppColors.error
                : null;
    final IconData? icon = !answered
        ? null
        : isCorrect
            ? Icons.check_circle
            : isSelected
                ? Icons.cancel
                : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: tone?.withValues(alpha: 0.12) ?? context.colors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: answered ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(child: Text(text)),
                if (icon != null)
                  Icon(icon, size: 20, color: context.colors.readable(tone!)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Nút phát file nghe của một câu. Mỗi câu có trình phát riêng, tạo khi bấm lần đầu.
class _PracticeAudioButton extends StatefulWidget {
  const _PracticeAudioButton({required this.url});

  final String url;

  @override
  State<_PracticeAudioButton> createState() => _PracticeAudioButtonState();
}

class _PracticeAudioButtonState extends State<_PracticeAudioButton> {
  AudioPlayer? _player;
  bool _busy = false;
  bool _failed = false;

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  Future<void> _play() async {
    setState(() {
      _busy = true;
      _failed = false;
    });
    try {
      final player = _player ??= AudioPlayer();
      await player.stop();
      await player.play(await resolveAudioSource(
        url: widget.url,
        fileName: widget.url.split('/').last,
      ));
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: OutlinedButton.icon(
        onPressed: _busy ? null : _play,
        icon: Icon(_failed ? Icons.error_outline : Icons.play_arrow),
        label:
            Text(_failed ? 'Không phát được, thử lại' : 'Nghe đoạn hội thoại'),
      ),
    );
  }
}
