import 'package:flutter/material.dart';

import '../../features/admin/screens/admin_achievement_management_screen.dart';
import '../../features/admin/screens/admin_analytics_screen.dart';
import '../../features/admin/screens/admin_content_management_screen.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/admin/screens/admin_report_management_screen.dart';
import '../../features/admin/screens/admin_transaction_screen.dart';
import '../../features/admin/screens/admin_user_management_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/change_password_screen.dart';
import '../../features/exercise/screens/exercise_detail_screen.dart';
import '../../features/exercise/screens/exercise_history_screen.dart';
import '../../features/exercise/screens/exercise_list_screen.dart';
import '../../features/exercise/screens/exercise_result_screen.dart';
import '../../features/settings/screens/export_screen.dart';
import '../../features/social/screens/friend_leaderboard_screen.dart';
import '../../features/grammar/screens/grammar_list_screen.dart';
import '../../features/settings/screens/help_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/jlpt/screens/jlpt_list_screen.dart';
import '../../features/jlpt/screens/jlpt_practice_screen.dart';
import '../../features/kanji/screens/kanji_detail_screen.dart';
import '../../features/kanji/screens/kanji_list_screen.dart';
import '../../features/progress/screens/learning_goals_screen.dart';
import '../../features/progress/screens/learning_history_screen.dart';
import '../../features/lessons/screens/lesson_list_screen.dart';
import '../../features/notebook/screens/notebook_list_screen.dart';
import '../../features/settings/screens/notification_settings_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/settings/screens/offline_mode_screen.dart';
import '../../features/billing/screens/payment_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/reports/screens/report_screen.dart';
import '../../features/search/screens/search_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/progress/screens/user_statistics_screen.dart';
import '../../features/vocabulary/screens/vocabulary_detail_screen.dart';
import '../../features/vocabulary/screens/vocabulary_main_screen.dart';

abstract final class AppRouter {
  static final Map<String, WidgetBuilder> routes = {
    '/login': (context) => const LoginScreen(),
    '/register': (context) => const RegisterScreen(),
    '/home': (context) => const HomeScreen(),
    '/profile': (context) => const ProfileScreen(),
    '/lessons': (context) => const LessonListScreen(),
    '/vocabulary': (context) => const VocabularyMainScreen(),
    '/kanji': (context) => const KanjiListScreen(),
    '/grammar': (context) => const GrammarListScreen(),
    '/exercise': (context) => const ExerciseListScreen(),
    '/exercise-history': (context) => const ExerciseHistoryScreen(),
    '/notebook': (context) => const NotebookListScreen(),
    '/report': (context) => const ReportScreen(),
    '/search': (context) => const SearchScreen(),
    '/payment': (context) => const PaymentScreen(),
    '/statistics': (context) => const UserStatisticsScreen(),
    '/goals': (context) => const LearningGoalsScreen(),
    '/friend-leaderboard': (context) => const FriendLeaderboardScreen(),
    '/jlpt': (context) => const JLPTListScreen(),
    '/jlpt-practice': (context) => const JLPTPracticeScreen(),
    '/settings': (context) => const SettingsScreen(),
    '/notifications': (context) => const NotificationsScreen(),
    '/export': (context) => const ExportScreen(),
    '/offline-mode': (context) => const OfflineModeScreen(),
    '/notification-settings': (context) => const NotificationSettingsScreen(),
    '/help': (context) => const HelpScreen(),
    '/learning-history': (context) => const LearningHistoryScreen(),
    '/change-password': (context) => const ChangePasswordScreen(),
    '/admin/dashboard': (context) => const AdminDashboardScreen(),
    '/admin/users': (context) => const AdminUserManagementScreen(),
    '/admin/content': (context) => const AdminContentManagementScreen(),
    '/admin/reports': (context) => const AdminReportManagementScreen(),
    '/admin/achievements': (context) =>
        const AdminAchievementManagementScreen(),
    '/admin/analytics': (context) => const AdminAnalyticsScreen(),
    '/admin/transactions': (context) => const AdminTransactionScreen(),
  };

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    if (settings.name != null &&
        settings.name!.startsWith('/vocabulary-detail')) {
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
    if (settings.name != null &&
        settings.name!.startsWith('/exercise-detail')) {
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
  }

  static Route<dynamic> onUnknownRoute(RouteSettings settings) {
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
  }
}
