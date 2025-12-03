import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/lesson_provider.dart';
import '../providers/lesson_progress_provider.dart';
import '../providers/vocabulary_provider.dart';
import '../providers/kanji_provider.dart';
import '../providers/exercise_provider.dart';
import '../providers/streak_provider.dart';
import '../providers/achievement_provider.dart';
import '../providers/progress_provider.dart';
import '../providers/study_group_provider.dart';
import '../providers/group_chat_provider.dart';
import '../providers/notebook_provider.dart';

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
