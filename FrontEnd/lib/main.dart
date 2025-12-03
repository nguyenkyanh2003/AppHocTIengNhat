import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'core/api_client.dart';
import 'providers/auth_provider.dart';
import 'providers/lesson_provider.dart';
import 'providers/lesson_progress_provider.dart';
import 'providers/vocabulary_provider.dart';
import 'providers/kanji_provider.dart';
import 'providers/exercise_provider.dart';
import 'providers/streak_provider.dart';
import 'providers/achievement_provider.dart';
import 'providers/progress_provider.dart';
import 'providers/study_group_provider.dart';
import 'providers/group_chat_provider.dart';
import 'providers/notebook_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/lesson/lesson_list_screen.dart';
import 'screens/vocabulary/vocabulary_list_screen.dart';
import 'screens/vocabulary/vocabulary_detail_screen.dart';
import 'screens/kanji/kanji_list_screen.dart';
import 'screens/kanji/kanji_detail_screen.dart';
import 'screens/exercise/exercise_list_screen.dart';
import 'screens/exercise/exercise_detail_screen.dart';
import 'screens/exercise/exercise_result_screen.dart';
import 'screens/exercise/exercise_history_screen.dart';
import 'screens/notebook/notebook_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiClient().init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
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
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return MaterialApp(
            title: 'App Học Tiếng Nhật',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system,
            debugShowCheckedModeBanner: false,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('vi', 'VN'),
              Locale('en', 'US'),
            ],
            routes: {
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
              '/home': (context) => const HomeScreen(),
              '/profile': (context) => const ProfileScreen(),
              '/lessons': (context) => const LessonListScreen(),
              '/vocabulary': (context) => const VocabularyListScreen(),
              '/kanji': (context) => const KanjiListScreen(),
              '/exercise': (context) => const ExerciseListScreen(),
              '/exercise-history': (context) => const ExerciseHistoryScreen(),
              '/notebook': (context) => const NotebookListScreen(),
            },
            onGenerateRoute: (settings) {
              // Route với tham số
              if (settings.name != null && settings.name!.startsWith('/vocabulary-detail')) {
                final id = settings.arguments as String;
                return MaterialPageRoute(
                  builder: (context) => VocabularyDetailScreen(vocabularyId: id),
                );
              }
              if (settings.name != null && settings.name!.startsWith('/kanji-detail')) {
                final id = settings.arguments as String;
                return MaterialPageRoute(
                  builder: (context) => KanjiDetailScreen(kanjiId: id),
                );
              }
              if (settings.name != null && settings.name!.startsWith('/exercise-detail')) {
                final id = settings.arguments as String;
                return MaterialPageRoute(
                  builder: (context) => ExerciseDetailScreen(exerciseId: id),
                );
              }
              if (settings.name == '/exercise-result') {
                return MaterialPageRoute(
                  builder: (context) => const ExerciseResultScreen(),
                );
              }
              return null;
            },
            onUnknownRoute: (settings) {
              // Trả về placeholder screen cho các route chưa implement
              return MaterialPageRoute(
                builder: (context) => Scaffold(
                  appBar: AppBar(
                    title: Text(settings.name ?? 'Tính năng'),
                  ),
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.construction, size: 64, color: Colors.orange),
                        const SizedBox(height: 16),
                        Text(
                          'Tính năng "${settings.name}" đang phát triển',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Quay lại'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            home: authProvider.isLoading
                ? const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  )
                : authProvider.isAuthenticated
                    ? const HomeScreen()
                    : const LoginScreen(),
          );
        },
      ),
    );
  }
}