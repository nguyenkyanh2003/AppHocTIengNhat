import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../core/audio/speech_service.dart';
import '../../models/dialogue_turn.dart';
import '../dialogue_view.dart';

/// Đọc lại hội thoại của bài. Nghĩa tiếng Việt ẩn sẵn: người học tự hiểu câu
/// trước, bấm hiện nghĩa để kiểm tra — đọc chủ động thay vì lướt bản dịch.
class StudyDialogueStep extends StatefulWidget {
  const StudyDialogueStep({super.key, required this.dialogue});

  final List<DialogueTurn> dialogue;

  @override
  State<StudyDialogueStep> createState() => _StudyDialogueStepState();
}

class _StudyDialogueStepState extends State<StudyDialogueStep> {
  bool _showTranslation = false;

  Future<void> _speak(DialogueTurn turn) async {
    try {
      await SpeechService.instance.speak(turn.textJa);
    } catch (_) {
      // Thiết bị không có giọng đọc tiếng Nhật: câu vẫn đọc được bằng mắt.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: FilterChip(
            selected: _showTranslation,
            onSelected: (value) => setState(() => _showTranslation = value),
            avatar: Icon(_showTranslation ? Icons.visibility : Icons.visibility_off_outlined, size: 18),
            label: Text(_showTranslation ? 'Đang hiện nghĩa tiếng Việt' : 'Hiện nghĩa tiếng Việt'),
            showCheckmark: false,
          ),
        ),
        AppGap.lg,
        DialogueView(
          dialogue: widget.dialogue,
          showTranslation: _showTranslation,
          onSpeak: _speak,
        ),
      ],
    );
  }
}
