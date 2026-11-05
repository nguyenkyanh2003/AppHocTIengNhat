import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:apphoctiengnnhat/app/app_providers.dart';
import 'package:apphoctiengnnhat/app/localization/app_localizations.dart';
import 'package:apphoctiengnnhat/app/theme/app_theme.dart';
import 'package:apphoctiengnnhat/features/achievements/screens/achievement_screen.dart';
import 'package:apphoctiengnnhat/features/admin/screens/admin_achievement_management_screen.dart';
import 'package:apphoctiengnnhat/features/admin/screens/admin_analytics_screen.dart';
import 'package:apphoctiengnnhat/features/admin/screens/admin_content_management_screen.dart';
import 'package:apphoctiengnnhat/features/admin/screens/admin_dashboard_screen.dart';
import 'package:apphoctiengnnhat/features/admin/screens/admin_report_management_screen.dart';
import 'package:apphoctiengnnhat/features/admin/screens/admin_transaction_screen.dart';
import 'package:apphoctiengnnhat/features/admin/screens/admin_user_management_screen.dart';
import 'package:apphoctiengnnhat/features/exercise/screens/exercise_detail_screen.dart';
import 'package:apphoctiengnnhat/features/exercise/screens/exercise_history_screen.dart';
import 'package:apphoctiengnnhat/features/exercise/screens/exercise_list_screen.dart';
import 'package:apphoctiengnnhat/features/flashcards/screens/flashcard_deck_detail_screen.dart';
import 'package:apphoctiengnnhat/features/flashcards/screens/flashcard_deck_list_screen.dart';
import 'package:apphoctiengnnhat/features/goals/screens/learning_goals_screen.dart';
import 'package:apphoctiengnnhat/features/grammar/screens/grammar_detail_screen.dart';
import 'package:apphoctiengnnhat/features/grammar/screens/grammar_list_screen.dart';
import 'package:apphoctiengnnhat/features/jlpt/screens/jlpt_exam_screen.dart';
import 'package:apphoctiengnnhat/features/jlpt/screens/jlpt_list_screen.dart';
import 'package:apphoctiengnnhat/features/jlpt/screens/jlpt_practice_screen.dart';
import 'package:apphoctiengnnhat/features/kanji/screens/kanji_detail_screen.dart';
import 'package:apphoctiengnnhat/features/kanji/screens/kanji_list_screen.dart';
import 'package:apphoctiengnnhat/features/lessons/screens/lesson_detail_screen.dart';
import 'package:apphoctiengnnhat/features/lessons/screens/lesson_list_screen.dart';
import 'package:apphoctiengnnhat/features/news/screens/news_detail_screen.dart';
import 'package:apphoctiengnnhat/features/news/screens/news_list_screen.dart';
import 'package:apphoctiengnnhat/features/notebook/screens/notebook_detail_screen.dart';
import 'package:apphoctiengnnhat/features/notebook/screens/notebook_list_screen.dart';
import 'package:apphoctiengnnhat/features/notifications/screens/notifications_screen.dart';
import 'package:apphoctiengnnhat/features/progress/screens/learning_history_screen.dart';
import 'package:apphoctiengnnhat/features/progress/screens/progress_dashboard_screen.dart';
import 'package:apphoctiengnnhat/features/progress/screens/user_statistics_screen.dart';
import 'package:apphoctiengnnhat/features/reports/screens/my_reports_screen.dart';
import 'package:apphoctiengnnhat/features/settings/screens/notification_settings_screen.dart';
import 'package:apphoctiengnnhat/features/srs/screens/srs_review_screen.dart';
import 'package:apphoctiengnnhat/features/streaks/screens/leaderboard_screen.dart';
import 'package:apphoctiengnnhat/features/streaks/screens/streak_calendar_screen.dart';
import 'package:apphoctiengnnhat/features/streaks/screens/streak_screen.dart';
import 'package:apphoctiengnnhat/features/study_groups/screens/group_detail_screen.dart';
import 'package:apphoctiengnnhat/features/study_groups/screens/study_group_list_screen.dart';
import 'package:apphoctiengnnhat/features/vocabulary/screens/vocabulary_detail_screen.dart';
import 'package:apphoctiengnnhat/features/vocabulary/screens/vocabulary_main_screen.dart';
import 'package:apphoctiengnnhat/features/vocabulary/screens/vocabulary_set_screen.dart';
import 'package:apphoctiengnnhat/shared/widgets/async_view.dart';

const _id = '507f1f77bcf86cd799439011';

/// Mọi màn tải dữ liệu từ server. Thêm màn mới vào đây để nó được kiểm cả ba
/// trạng thái; màn thuần biểu mẫu thì không thuộc danh sách này.
final Map<String, Widget Function()> _lists = {
  'bài học': () => const LessonListScreen(),
  'từ vựng': () => const VocabularyMainScreen(),
  'kanji': () => const KanjiListScreen(),
  'ngữ pháp': () => const GrammarListScreen(),
  'bài tập': () => const ExerciseListScreen(),
  'lịch sử làm bài': () => const ExerciseHistoryScreen(),
  'đề JLPT': () => const JLPTListScreen(),
  'luyện nhanh JLPT': () => const JLPTPracticeScreen(),
  'tin tức': () => const NewsListScreen(),
  'thành tích': () => const AchievementScreen(),
  'bộ thẻ': () => const FlashcardDeckListScreen(),
  'sổ tay': () => const NotebookListScreen(),
  'nhóm học': () => const StudyGroupListScreen(),
  'bảng xếp hạng': () => const LeaderboardScreen(),
  'thông báo': () => const NotificationsScreen(),
  'báo cáo của tôi': () => const MyReportsScreen(),
  'mục tiêu': () => const LearningGoalsScreen(),
  'quản trị người dùng': () => const AdminUserManagementScreen(),
  'quản trị báo cáo': () => const AdminReportManagementScreen(),
  'quản trị thành tích': () => const AdminAchievementManagementScreen(),
  'quản trị giao dịch': () => const AdminTransactionScreen(),
  'quản trị nội dung': () => const AdminContentManagementScreen(),
};

final Map<String, Widget Function()> _details = {
  'chi tiết bài học': () => const LessonDetailScreen(lessonId: _id),
  'chi tiết từ vựng': () => const VocabularyDetailScreen(vocabularyId: _id),
  'bộ từ vựng': () => const VocabularySetScreen(setId: _id),
  'chi tiết kanji': () => const KanjiDetailScreen(kanjiId: _id),
  'chi tiết ngữ pháp': () => const GrammarDetailScreen(grammarId: _id),
  'làm bài tập': () => const ExerciseDetailScreen(exerciseId: _id),
  'làm đề JLPT': () => const JLPTExamScreen(examId: _id, title: 'Đề thử'),
  'chi tiết tin tức': () => const NewsDetailScreen(newsId: _id),
  'chi tiết bộ thẻ': () => const FlashcardDeckDetailScreen(deckId: _id),
  'chi tiết ghi chú': () => const NotebookDetailScreen(noteId: _id),
  'chi tiết nhóm': () => const GroupDetailScreen(groupId: _id),
  'ôn tập SRS': () => const SrsReviewScreen(),
  'lịch học': () => const StreakCalendarScreen(),
  'chuỗi ngày': () => const StreakScreen(),
  'tiến độ': () => const ProgressDashboardScreen(),
  'lịch sử học': () => const LearningHistoryScreen(),
  'thống kê chi tiết': () => const UserStatisticsScreen(),
  'quản trị tổng quan': () => const AdminDashboardScreen(),
  'quản trị thống kê': () => const AdminAnalyticsScreen(),
  'cài đặt thông báo': () => const NotificationSettingsScreen(),
};

const _json = {'content-type': 'application/json; charset=utf-8'};

/// Danh sách rỗng theo mọi kiểu phản hồi mà các service đang đọc.
final _emptyBody = jsonEncode({
  'data': [],
  'total': 0,
  'totalItems': 0,
  'page': 1,
  'limit': 20,
  'pages': 0,
  'current': 1,
  'currentPage': 1,
  'totalPages': 0,
  'earned': [],
  'locked': [],
  'leaderboard': [],
  'unreadCount': 0,
  'count': 0,
  'users': [],
  'reports': [],
  'achievements': [],
  'transactions': [],
  'exercises': [],
  'results': [],
  'kanjis': [],
});

/// Mất kết nối theo đúng cách trình duyệt báo: thông báo có cả tên exception
/// và địa chỉ máy chủ, không cái nào được phép lọt lên giao diện.
http.Client _unreachable() => MockClient((request) async =>
    throw http.ClientException('Failed to fetch', request.url));

Widget _app(Widget screen) => MultiProvider(
      providers: createAppProviders(),
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('vi', 'VN')],
        locale: const Locale('vi', 'VN'),
        routerConfig: GoRouter(
          routes: [GoRoute(path: '/', builder: (context, state) => screen)],
        ),
      ),
    );

/// Không dùng `pumpAndSettle`: vòng xoay chạy mãi sẽ làm test treo thay vì báo
/// đúng lỗi "màn kẹt ở trạng thái tải".
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i += 1) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}

void _expectNoRawError(WidgetTester tester) {
  for (final raw in [
    'ClientException',
    'Exception:',
    'localhost',
    'Failed to fetch'
  ]) {
    expect(find.textContaining(raw), findsNothing,
        reason: 'Lộ chuỗi kỹ thuật "$raw" lên giao diện');
  }
}

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  group('máy chủ không kết nối được', () {
    for (final MapEntry(key: name, value: build)
        in {..._lists, ..._details}.entries) {
      testWidgets(
          '$name: báo lỗi kèm nút thử lại, không hiện như danh sách rỗng',
          (tester) async {
        tester.view.physicalSize = const Size(1280, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await http.runWithClient(() async {
          await tester.pumpWidget(_app(build()));
          await _settle(tester);

          expect(find.byType(CircularProgressIndicator), findsNothing,
              reason: 'Kẹt ở vòng xoay');
          expect(find.byType(EmptyStateView), findsNothing,
              reason: 'Lỗi mạng bị hiện thành "chưa có dữ liệu"');
          expect(find.byType(ErrorStateView), findsWidgets);
          expect(find.text('Thử lại'), findsWidgets);
          _expectNoRawError(tester);
        }, _unreachable);
      });
    }
  });

  group('dữ liệu rỗng', () {
    for (final MapEntry(key: name, value: build) in _lists.entries) {
      testWidgets('$name: hiện trạng thái rỗng, không hiện lỗi',
          (tester) async {
        tester.view.physicalSize = const Size(1280, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await http.runWithClient(() async {
          await tester.pumpWidget(_app(build()));
          await _settle(tester);

          expect(find.byType(CircularProgressIndicator), findsNothing,
              reason: 'Kẹt ở vòng xoay');
          expect(find.byType(ErrorStateView), findsNothing);
          expect(find.byType(EmptyStateView), findsWidgets);
          _expectNoRawError(tester);
        },
            () => MockClient(
                (_) async => http.Response(_emptyBody, 200, headers: _json)));
      });
    }
  });

  group('nút thử lại', () {
    for (final MapEntry(key: name, value: build) in _lists.entries) {
      testWidgets('$name: có mạng trở lại thì bấm thử lại là hết lỗi',
          (tester) async {
        tester.view.physicalSize = const Size(1280, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        var online = false;
        final client = MockClient((request) async {
          if (!online) {
            throw http.ClientException('Failed to fetch', request.url);
          }
          return http.Response(_emptyBody, 200, headers: _json);
        });

        await http.runWithClient(() async {
          await tester.pumpWidget(_app(build()));
          await _settle(tester);

          online = true;
          await tester.tap(find.text('Thử lại').first);
          await _settle(tester);

          expect(find.byType(ErrorStateView), findsNothing);
          expect(find.byType(EmptyStateView), findsWidgets);
        }, () => client);
      });
    }
  });
}
