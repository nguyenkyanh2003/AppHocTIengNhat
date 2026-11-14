import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
import 'package:apphoctiengnnhat/app/shell/hub_screen.dart';
import 'package:apphoctiengnnhat/app/theme/app_theme.dart';
import 'package:apphoctiengnnhat/features/achievements/screens/achievement_screen.dart';
import 'package:apphoctiengnnhat/features/admin/screens/admin_achievement_management_screen.dart';
import 'package:apphoctiengnnhat/features/admin/screens/admin_analytics_screen.dart';
import 'package:apphoctiengnnhat/features/admin/screens/admin_content_management_screen.dart';
import 'package:apphoctiengnnhat/features/admin/screens/admin_dashboard_screen.dart';
import 'package:apphoctiengnnhat/features/admin/screens/admin_report_management_screen.dart';
import 'package:apphoctiengnnhat/features/admin/screens/admin_transaction_screen.dart';
import 'package:apphoctiengnnhat/features/admin/screens/admin_user_management_screen.dart';
import 'package:apphoctiengnnhat/features/auth/screens/change_password_screen.dart';
import 'package:apphoctiengnnhat/features/auth/screens/forgot_password_screen.dart';
import 'package:apphoctiengnnhat/features/auth/screens/login_screen.dart';
import 'package:apphoctiengnnhat/features/auth/screens/register_screen.dart';
import 'package:apphoctiengnnhat/features/auth/screens/reset_password_screen.dart';
import 'package:apphoctiengnnhat/features/billing/screens/payment_screen.dart';
import 'package:apphoctiengnnhat/features/exercise/screens/exercise_detail_screen.dart';
import 'package:apphoctiengnnhat/features/exercise/screens/exercise_history_screen.dart';
import 'package:apphoctiengnnhat/features/exercise/screens/exercise_list_screen.dart';
import 'package:apphoctiengnnhat/features/exercise/screens/exercise_result_screen.dart';
import 'package:apphoctiengnnhat/features/flashcards/screens/create_flashcard_deck_screen.dart';
import 'package:apphoctiengnnhat/features/flashcards/screens/edit_flashcard_card_screen.dart';
import 'package:apphoctiengnnhat/features/flashcards/screens/flashcard_deck_detail_screen.dart';
import 'package:apphoctiengnnhat/features/flashcards/screens/flashcard_deck_list_screen.dart';
import 'package:apphoctiengnnhat/features/flashcards/screens/flashcard_study_screen.dart';
import 'package:apphoctiengnnhat/features/goals/screens/learning_goals_screen.dart';
import 'package:apphoctiengnnhat/features/grammar/screens/grammar_detail_screen.dart';
import 'package:apphoctiengnnhat/features/grammar/screens/grammar_list_screen.dart';
import 'package:apphoctiengnnhat/features/home/screens/home_screen.dart';
import 'package:apphoctiengnnhat/features/jlpt/screens/jlpt_exam_screen.dart';
import 'package:apphoctiengnnhat/features/jlpt/screens/jlpt_list_screen.dart';
import 'package:apphoctiengnnhat/features/jlpt/screens/jlpt_practice_screen.dart';
import 'package:apphoctiengnnhat/features/kanji/screens/kanji_detail_screen.dart';
import 'package:apphoctiengnnhat/features/kanji/screens/kanji_list_screen.dart';
import 'package:apphoctiengnnhat/features/lessons/screens/lesson_detail_screen.dart';
import 'package:apphoctiengnnhat/features/lessons/screens/lesson_list_screen.dart';
import 'package:apphoctiengnnhat/features/lessons/screens/lesson_study_screen.dart';
import 'package:apphoctiengnnhat/features/lessons/screens/lesson_transcript_editor_screen.dart';
import 'package:apphoctiengnnhat/features/news/screens/news_detail_screen.dart';
import 'package:apphoctiengnnhat/features/news/screens/news_list_screen.dart';
import 'package:apphoctiengnnhat/features/notebook/screens/notebook_detail_screen.dart';
import 'package:apphoctiengnnhat/features/notebook/screens/notebook_form_screen.dart';
import 'package:apphoctiengnnhat/features/notebook/screens/notebook_list_screen.dart';
import 'package:apphoctiengnnhat/features/notifications/screens/notifications_screen.dart';
import 'package:apphoctiengnnhat/features/profile/screens/profile_screen.dart';
import 'package:apphoctiengnnhat/features/progress/screens/learning_history_screen.dart';
import 'package:apphoctiengnnhat/features/progress/screens/progress_dashboard_screen.dart';
import 'package:apphoctiengnnhat/features/progress/screens/user_statistics_screen.dart';
import 'package:apphoctiengnnhat/features/reports/screens/my_reports_screen.dart';
import 'package:apphoctiengnnhat/features/reports/screens/report_screen.dart';
import 'package:apphoctiengnnhat/features/search/screens/search_screen.dart';
import 'package:apphoctiengnnhat/features/settings/screens/export_screen.dart';
import 'package:apphoctiengnnhat/features/settings/screens/help_screen.dart';
import 'package:apphoctiengnnhat/features/settings/screens/notification_settings_screen.dart';
import 'package:apphoctiengnnhat/features/settings/screens/offline_mode_screen.dart';
import 'package:apphoctiengnnhat/features/settings/screens/settings_screen.dart';
import 'package:apphoctiengnnhat/features/social/screens/friend_leaderboard_screen.dart';
import 'package:apphoctiengnnhat/features/srs/screens/srs_review_screen.dart';
import 'package:apphoctiengnnhat/features/streaks/screens/leaderboard_screen.dart';
import 'package:apphoctiengnnhat/features/streaks/screens/streak_calendar_screen.dart';
import 'package:apphoctiengnnhat/features/streaks/screens/streak_screen.dart';
import 'package:apphoctiengnnhat/features/study_groups/screens/create_group_screen.dart';
import 'package:apphoctiengnnhat/features/study_groups/screens/group_detail_screen.dart';
import 'package:apphoctiengnnhat/features/study_groups/screens/study_group_list_screen.dart';
import 'package:apphoctiengnnhat/features/study_groups/widgets/group_bottom_bar.dart';
import 'package:apphoctiengnnhat/features/vocabulary/screens/vocabulary_detail_screen.dart';
import 'package:apphoctiengnnhat/features/vocabulary/screens/vocabulary_main_screen.dart';
import 'package:apphoctiengnnhat/features/vocabulary/screens/vocabulary_set_screen.dart';
import 'package:apphoctiengnnhat/shared/widgets/async_view.dart';

/// Phản hồi API thật đã làm sạch: bớt phần tử, bỏ ảnh và dữ liệu cá nhân.
final _fixture = jsonDecode(
  File('test/fixtures/api_responses.json').readAsStringSync(),
) as Map<String, dynamic>;
final _responses = _fixture['responses'] as Map<String, dynamic>;
final _ids = _fixture['ids'] as Map<String, dynamic>;

String _id(String name) => _ids[name] as String;

final Map<String, Widget Function()> _screens = {
  'trang chủ': () => const HomeScreen(),
  'trang Học tập': () => const HubScreen(destinationPath: '/study'),
  'tìm kiếm': () => const SearchScreen(),
  'ôn tập SRS': () => const SrsReviewScreen(),
  'xếp hạng bạn bè': () => const FriendLeaderboardScreen(),
  'tạo ghi chú': () => const NotebookFormScreen(),
  'tạo bộ thẻ': () => const CreateFlashcardDeckScreen(),
  'tạo nhóm': () => const CreateGroupScreen(),
  'đăng nhập': () => const LoginScreen(),
  'đăng ký': () => const RegisterScreen(),
  'quên mật khẩu': () => const ForgotPasswordScreen(),
  'đặt lại mật khẩu': () => const ResetPasswordScreen(token: 'ma-dat-lai'),
  'đổi mật khẩu': () => const ChangePasswordScreen(),
  'gửi báo cáo': () => const ReportScreen(),
  'thanh toán': () => const PaymentScreen(),
  'trợ giúp': () => const HelpScreen(),
  'cài đặt': () => const SettingsScreen(),
  'hồ sơ': () => const ProfileScreen(),
  'cài đặt thông báo': () => const NotificationSettingsScreen(),
  'học offline': () => const OfflineModeScreen(),
  'xuất dữ liệu': () => const ExportScreen(),
  'bài học': () => const LessonListScreen(),
  'chi tiết bài học': () => LessonDetailScreen(lessonId: _id('lesson')),
  'học bài': () => LessonStudyScreen(lessonId: _id('lesson')),
  'soạn lời thoại': () => LessonTranscriptEditorScreen(lessonId: _id('lesson')),
  'từ vựng': () => const VocabularyMainScreen(),
  'chi tiết từ vựng': () =>
      VocabularyDetailScreen(vocabularyId: _id('vocabulary')),
  'bộ từ vựng': () => VocabularySetScreen(setId: _id('vocabularySet')),
  'kanji': () => const KanjiListScreen(),
  'chi tiết kanji': () => KanjiDetailScreen(kanjiId: _id('kanji')),
  'ngữ pháp': () => const GrammarListScreen(),
  'chi tiết ngữ pháp': () => GrammarDetailScreen(grammarId: _id('grammar')),
  'bài tập': () => const ExerciseListScreen(),
  'làm bài tập': () => ExerciseDetailScreen(exerciseId: _id('exercise')),
  'lịch sử làm bài': () => const ExerciseHistoryScreen(),
  'kết quả làm bài': () => ExerciseResultScreen(resultId: _id('exerciseResult')),
  'đề JLPT': () => const JLPTListScreen(),
  'luyện nhanh JLPT': () => const JLPTPracticeScreen(),
  'làm đề JLPT': () =>
      JLPTExamScreen(examId: _id('jlpt'), title: 'Đề mẫu JLPT N4'),
  'tin tức': () => const NewsListScreen(),
  'chi tiết tin tức': () => NewsDetailScreen(newsId: _id('news')),
  'bộ thẻ': () => const FlashcardDeckListScreen(),
  'chi tiết bộ thẻ': () => FlashcardDeckDetailScreen(deckId: _id('deck')),
  'thêm thẻ': () => EditFlashcardCardScreen(deckId: _id('deck')),
  'học thẻ': () => const FlashcardStudyScreen(level: 'N5'),
  'chuỗi ngày': () => const StreakScreen(),
  'lịch học': () => const StreakCalendarScreen(),
  'thành tích': () => const AchievementScreen(),
  'bảng xếp hạng': () => const LeaderboardScreen(),
  'sổ tay': () => const NotebookListScreen(),
  'chi tiết ghi chú': () => NotebookDetailScreen(noteId: _id('note')),
  'nhóm học': () => const StudyGroupListScreen(),
  'chi tiết nhóm': () => GroupDetailScreen(groupId: _id('group')),
  'tiến độ': () => const ProgressDashboardScreen(),
  'lịch sử học': () => const LearningHistoryScreen(),
  'thống kê chi tiết': () => const UserStatisticsScreen(),
  'mục tiêu': () => const LearningGoalsScreen(),
  'thông báo': () => const NotificationsScreen(),
  'báo cáo của tôi': () => const MyReportsScreen(),
  'quản trị tổng quan': () => const AdminDashboardScreen(),
  'quản trị người dùng': () => const AdminUserManagementScreen(),
  'quản trị nội dung': () => const AdminContentManagementScreen(),
  'quản trị báo cáo': () => const AdminReportManagementScreen(),
  'quản trị thành tích': () => const AdminAchievementManagementScreen(),
  'quản trị thống kê': () => const AdminAnalyticsScreen(),
  'quản trị giao dịch': () => const AdminTransactionScreen(),
};

/// Điện thoại nhỏ nhất, điện thoại phổ biến khi phóng to chữ, và màn rộng.
const _sizes = [
  (width: 320.0, textScale: 1.0),
  (width: 360.0, textScale: 1.0),
  (width: 360.0, textScale: 1.3),
  (width: 360.0, textScale: 1.5),
  (width: 360.0, textScale: 2.0),
  (width: 1280.0, textScale: 1.0),
];

Object? _responseFor(Uri url) {
  final path = url.path.replaceFirst(RegExp(r'^/api'), '');
  final exact = _responses[url.hasQuery ? '$path?${url.query}' : path];
  if (exact != null) return exact;
  // Cùng đường dẫn, khác tham số (năm, tháng, cấp độ).
  for (final MapEntry(:key, :value) in _responses.entries) {
    if (key == path || key.startsWith('$path?')) return value;
  }
  return const {'data': []};
}

http.Client _client() => MockClient((request) async => http.Response.bytes(
      utf8.encode(jsonEncode(_responseFor(request.url))),
      200,
      headers: const {'content-type': 'application/json; charset=utf-8'},
    ));

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

/// Một dòng đủ để sửa: lỗi gì, ở dòng code nào.
String _describe(FlutterErrorDetails details) {
  final message = details.exceptionAsString().split('\n').first;
  final where = RegExp(r'lib/[\w/]+\.dart:\d+').firstMatch(details.toString());
  return '$message @ ${where?.group(0) ?? 'không rõ vị trí'}';
}

/// Row không có `mainAxisSize: min` trong Wrap chiếm trọn một dòng, nên các mục
/// xếp chồng ngay cả khi đủ chỗ. Không tràn nên không có lỗi nào báo ra.
Iterable<String> _rowsFillingWrap(WidgetTester tester) sync* {
  for (final wrap in tester.allRenderObjects.whereType<RenderWrap>()) {
    final rows = <RenderFlex>[];
    wrap.visitChildren((child) {
      if (child is RenderFlex &&
          child.direction == Axis.horizontal &&
          child.mainAxisSize == MainAxisSize.max) {
        rows.add(child);
      }
    });
    for (final row in rows) {
      yield 'Row chiếm trọn dòng trong Wrap: ${row.debugCreator}';
    }
  }
}

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  for (final size in _sizes) {
    group('rộng ${size.width.toInt()}, chữ ×${size.textScale}', () {
      for (final MapEntry(key: name, value: build) in _screens.entries) {
        testWidgets('$name không tràn bố cục', (tester) async {
          tester.view.physicalSize = Size(size.width, 800);
          tester.view.devicePixelRatio = 1;
          tester.platformDispatcher.textScaleFactorTestValue = size.textScale;
          addTearDown(tester.view.reset);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

          // Gom lỗi ngay lúc xảy ra: khi đó widget còn sống nên biết được dòng code gây tràn.
          final problems = <String>[];
          var errorViews = 0;
          final previous = FlutterError.onError;
          FlutterError.onError = (details) => problems.add(_describe(details));
          try {
            await http.runWithClient(() async {
              await tester.pumpWidget(_app(build()));
              for (var i = 0; i < 10; i += 1) {
                await tester.pump(const Duration(milliseconds: 60));
              }
              // Test chỉ có ý nghĩa khi màn đã dựng bằng dữ liệu thật, không phải nhánh lỗi.
              errorViews = find.byType(ErrorStateView).evaluate().length;
              problems.addAll(_rowsFillingWrap(tester));
              // Gỡ cây để bộ đếm giờ của màn (đề thi) dừng lại.
              await tester.pumpWidget(const SizedBox.shrink());
            }, _client);
          } finally {
            FlutterError.onError = previous;
          }

          printOnFailure(problems.toSet().join('\n'));
          expect(problems, isEmpty);
          expect(errorViews, 0, reason: 'Màn không dựng được từ dữ liệu mẫu');
        });
      }
    });
  }

  testWidgets('thanh hành động của nhóm chiếm hết bề ngang', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await http.runWithClient(() async {
      await tester.pumpWidget(_app(_screens['chi tiết nhóm']!()));
      for (var i = 0; i < 10; i += 1) {
        await tester.pump(const Duration(milliseconds: 60));
      }
      expect(tester.getSize(find.byType(GroupBottomBar)).width, 360);
      await tester.pumpWidget(const SizedBox.shrink());
    }, _client);
  });
}
