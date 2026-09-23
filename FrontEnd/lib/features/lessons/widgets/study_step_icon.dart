import 'package:flutter/material.dart';

import '../models/lesson_study_step.dart';

/// Biểu tượng của từng loại bước — dùng chung cho lộ trình ở màn chi tiết và
/// thanh tiến độ ở màn học, để hai nơi nói cùng một ngôn ngữ hình ảnh.
IconData studyStepIcon(StudyStepKind kind) => switch (kind) {
      StudyStepKind.intro => Icons.flag_outlined,
      StudyStepKind.video => Icons.play_circle_outline,
      StudyStepKind.dialogue => Icons.forum_outlined,
      StudyStepKind.vocabulary => Icons.style_outlined,
      StudyStepKind.kanji => Icons.draw_outlined,
      StudyStepKind.grammar => Icons.account_tree_outlined,
      StudyStepKind.quiz => Icons.quiz_outlined,
      StudyStepKind.finish => Icons.emoji_events_outlined,
    };
