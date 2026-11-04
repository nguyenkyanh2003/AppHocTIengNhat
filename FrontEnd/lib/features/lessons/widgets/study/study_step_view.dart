import 'package:flutter/material.dart';

import '../../models/lesson_study_step.dart';
import '../../providers/lesson_study_session.dart';
import '../lesson_reference_lists.dart';
import 'study_dialogue_step.dart';
import 'study_intro_step.dart';
import 'study_kanji_step.dart';
import 'study_quiz_step.dart';
import 'study_video_step.dart';
import 'study_vocabulary_step.dart';

/// Nội dung của bước hiện tại trong phiên học (trừ bước hoàn thành, do màn
/// học dựng vì cần XP và điều hướng).
class StudyStepView extends StatelessWidget {
  const StudyStepView({super.key, required this.session});

  final LessonStudySession session;

  @override
  Widget build(BuildContext context) {
    final detail = session.detail;
    final step = session.step;

    return switch (step.kind) {
      StudyStepKind.intro => StudyIntroStep(detail: detail),
      StudyStepKind.video => StudyVideoStep(video: detail.lesson.videos[step.videoIndex!]),
      StudyStepKind.dialogue => StudyDialogueStep(dialogue: detail.lesson.dialogue),
      StudyStepKind.vocabulary => StudyVocabularyStep(
          words: detail.words,
          isLearned: session.isLearned,
          isSaving: session.isSaving,
          onMarkLearned: session.markLearned,
          onUnmarkLearned: session.unmarkLearned,
        ),
      StudyStepKind.kanji => StudyKanjiStep(
          kanjis: detail.kanjis,
          isLearned: session.isKanjiLearned,
          isSaving: session.isKanjiSaving,
          onMarkLearned: session.markKanjiLearned,
          onUnmarkLearned: session.unmarkKanjiLearned,
          footer: StudyKanjiReviewOffer(
            pending: session.kanjiPendingReview,
            added: session.kanjiAddedToReview,
            busy: session.isAddingToReview,
            onAdd: session.addLearnedKanjiToReview,
          ),
        ),
      StudyStepKind.grammar => LessonGrammarList(grammars: detail.grammars),
      StudyStepKind.quiz => StudyQuizStep(
          questions: session.quiz,
          answerOf: session.answerOf,
          onAnswer: session.answer,
        ),
      StudyStepKind.finish => const SizedBox.shrink(),
    };
  }
}
