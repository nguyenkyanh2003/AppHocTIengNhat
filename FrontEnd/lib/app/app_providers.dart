import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../features/achievements/providers/achievement_provider.dart';
import '../features/admin/providers/admin_provider.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/exercise/providers/exercise_provider.dart';
import '../features/flashcards/providers/flashcard_provider.dart';
import '../features/grammar/providers/grammar_provider.dart';
import '../features/study_groups/providers/group_chat_provider.dart';
import '../features/jlpt/providers/jlpt_exam_provider.dart';
import '../features/jlpt/providers/jlpt_practice_provider.dart';
import '../features/jlpt/providers/jlpt_provider.dart';
import '../features/kanji/providers/kanji_provider.dart';
import '../features/lessons/providers/lesson_progress_provider.dart';
import '../features/lessons/providers/lesson_provider.dart';
import './localization/locale_provider.dart';
import '../features/news/providers/news_provider.dart';
import '../features/notebook/providers/notebook_provider.dart';
import '../features/progress/providers/progress_provider.dart';
import '../features/reports/providers/report_provider.dart';
import '../features/search/providers/search_provider.dart';
import '../features/streaks/providers/streak_provider.dart';
import '../features/study_groups/providers/study_group_provider.dart';
import '../features/profile/providers/user_provider.dart';
import '../features/vocabulary/providers/vocabulary_provider.dart';

List<SingleChildWidget> createAppProviders() => [
      ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
      ChangeNotifierProvider(create: (_) => UserProvider()),
      ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ChangeNotifierProvider(create: (_) => LessonProvider()),
      ChangeNotifierProvider(create: (_) => LessonProgressProvider()),
      ChangeNotifierProvider(create: (_) => VocabularyProvider()),
      ChangeNotifierProvider(create: (_) => KanjiProvider()),
      ChangeNotifierProvider(create: (_) => ExerciseProvider()),
      ChangeNotifierProvider(create: (_) => StreakProvider()),
      ChangeNotifierProvider(create: (_) => AchievementProvider()),
      ChangeNotifierProvider(create: (_) => ProgressProvider()),
      ChangeNotifierProvider(create: (_) => StudyGroupProvider()),
      ChangeNotifierProvider(create: (_) => GroupChatProvider()),
      ChangeNotifierProvider(create: (_) => NotebookProvider()),
      ChangeNotifierProvider(create: (_) => NewsProvider()),
      ChangeNotifierProvider(create: (_) => JLPTProvider()),
      ChangeNotifierProvider(create: (_) => JLPTExamProvider()),
      ChangeNotifierProvider(create: (_) => JLPTPracticeProvider()),
      ChangeNotifierProvider(create: (_) => GrammarProvider()),
      ChangeNotifierProvider(create: (_) => ReportProvider()),
      ChangeNotifierProvider(create: (_) => SearchProvider()),
      ChangeNotifierProvider(create: (_) => FlashcardProvider()),
      ChangeNotifierProvider(create: (_) => AdminProvider()),
    ];
