import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/lessons/providers/lesson_provider.dart';
import '../../features/lessons/providers/lesson_progress_provider.dart';
import '../../features/vocabulary/providers/vocabulary_provider.dart';
import '../../features/kanji/providers/kanji_provider.dart';
import '../../features/exercise/providers/exercise_provider.dart';
import '../../features/streaks/providers/streak_provider.dart';
import '../../features/achievements/providers/achievement_provider.dart';
import '../../features/progress/providers/progress_provider.dart';
import '../../features/study_groups/providers/study_group_provider.dart';
import '../../features/study_groups/providers/group_chat_provider.dart';
import '../../features/notebook/providers/notebook_provider.dart';

/// Service để reset tất cả providers khi logout
class ProviderResetService {
  static void resetAllProviders(BuildContext context) {
    // Reset từng provider về state ban đầu
    try {
      context.read<LessonProvider>().clear();
    } catch (e) {
      debugPrint('Error resetting LessonProvider: $e');
    }

    try {
      context.read<LessonProgressProvider>().clear();
    } catch (e) {
      debugPrint('Error resetting LessonProgressProvider: $e');
    }

    try {
      context.read<VocabularyProvider>().clear();
    } catch (e) {
      debugPrint('Error resetting VocabularyProvider: $e');
    }

    try {
      context.read<KanjiProvider>().clear();
    } catch (e) {
      debugPrint('Error resetting KanjiProvider: $e');
    }

    try {
      context.read<ExerciseProvider>().clear();
    } catch (e) {
      debugPrint('Error resetting ExerciseProvider: $e');
    }

    try {
      context.read<StreakProvider>().clear();
    } catch (e) {
      debugPrint('Error resetting StreakProvider: $e');
    }

    try {
      context.read<AchievementProvider>().clear();
    } catch (e) {
      debugPrint('Error resetting AchievementProvider: $e');
    }

    try {
      context.read<ProgressProvider>().clear();
    } catch (e) {
      debugPrint('Error resetting ProgressProvider: $e');
    }

    try {
      context.read<StudyGroupProvider>().clear();
    } catch (e) {
      debugPrint('Error resetting StudyGroupProvider: $e');
    }

    try {
      context.read<GroupChatProvider>().clear();
    } catch (e) {
      debugPrint('Error resetting GroupChatProvider: $e');
    }

    try {
      context.read<NotebookProvider>().clear();
    } catch (e) {
      debugPrint('Error resetting NotebookProvider: $e');
    }

    debugPrint('✅ All providers reset successfully');
  }
}
