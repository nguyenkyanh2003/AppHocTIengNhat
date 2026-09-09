import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/achievements/screens/achievement_screen.dart';
import '../../features/admin/screens/admin_achievement_management_screen.dart';
import '../../features/admin/screens/admin_analytics_screen.dart';
import '../../features/admin/screens/admin_content_management_screen.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/admin/screens/admin_report_management_screen.dart';
import '../../features/admin/screens/admin_transaction_screen.dart';
import '../../features/admin/screens/admin_user_management_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/change_password_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/reset_password_screen.dart';
import '../../features/billing/screens/payment_screen.dart';
import '../../features/exercise/screens/exercise_detail_screen.dart';
import '../../features/exercise/screens/exercise_history_screen.dart';
import '../../features/exercise/screens/exercise_list_screen.dart';
import '../../features/exercise/screens/exercise_result_screen.dart';
import '../../features/flashcards/models/flashcard_deck.dart';
import '../../features/flashcards/screens/create_flashcard_deck_screen.dart';
import '../../features/flashcards/screens/edit_flashcard_card_screen.dart';
import '../../features/flashcards/screens/flashcard_deck_detail_screen.dart';
import '../../features/flashcards/screens/flashcard_study_screen.dart';
import '../../features/grammar/screens/grammar_detail_screen.dart';
import '../../features/grammar/screens/grammar_list_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/jlpt/screens/jlpt_exam_screen.dart';
import '../../features/jlpt/screens/jlpt_list_screen.dart';
import '../../features/jlpt/screens/jlpt_practice_screen.dart';
import '../../features/kanji/screens/kanji_detail_screen.dart';
import '../../features/kanji/screens/kanji_list_screen.dart';
import '../../features/lessons/screens/lesson_detail_screen.dart';
import '../../features/lessons/screens/lesson_list_screen.dart';
import '../../features/lessons/screens/lesson_study_screen.dart';
import '../../features/news/screens/news_detail_screen.dart';
import '../../features/news/screens/news_list_screen.dart';
import '../../features/notebook/screens/notebook_detail_screen.dart';
import '../../features/notebook/screens/notebook_form_screen.dart';
import '../../features/notebook/screens/notebook_list_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/progress/screens/learning_goals_screen.dart';
import '../../features/progress/screens/learning_history_screen.dart';
import '../../features/progress/screens/progress_dashboard_screen.dart';
import '../../features/progress/screens/user_statistics_screen.dart';
import '../../features/reports/screens/report_screen.dart';
import '../../features/search/screens/search_screen.dart';
import '../../features/settings/screens/export_screen.dart';
import '../../features/settings/screens/help_screen.dart';
import '../../features/settings/screens/notification_settings_screen.dart';
import '../../features/settings/screens/offline_mode_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/social/screens/friend_leaderboard_screen.dart';
import '../../features/streaks/screens/leaderboard_screen.dart';
import '../../features/streaks/screens/streak_screen.dart';
import '../../features/study_groups/screens/create_group_screen.dart';
import '../../features/study_groups/screens/group_detail_screen.dart';
import '../../features/study_groups/screens/study_group_list_screen.dart';
import '../../features/vocabulary/models/vocabulary.dart';
import '../../features/vocabulary/screens/vocabulary_detail_screen.dart';
import '../../features/vocabulary/screens/vocabulary_main_screen.dart';
import '../shell/app_shell.dart';
import '../shell/hub_screen.dart';
import 'router_status_screens.dart';

/// Cấu hình điều hướng của ứng dụng.
///
/// ## Vì sao không còn `Map<String, WidgetBuilder>`
///
/// Map cũ chỉ diễn đạt được "tên → widget". Nó không mang tham số URL, quyền
/// truy cập, shell điều hướng, redirect hay quan hệ cha–con — nên mọi thứ đó
/// trước đây phải nằm rải rác trong `onGenerateRoute` và trong từng screen.
/// Cấu hình dưới đây gom cả năm thứ về một chỗ.
///
/// ## Chiến lược URL
///
/// Giữ **hash URL** (mặc định của Flutter web, không gọi `usePathUrlStrategy`).
/// Backend dựng link đặt lại mật khẩu dạng `<base>/#/reset-password?token=...`
/// trong `user-auth.service.js`; bỏ dấu `#` sẽ làm hỏng mọi link đã gửi trong
/// email, nên đổi chiến lược phải sửa backend và cấu hình hosting cùng lúc.
abstract final class AppRouter {
  /// Các trang mở được khi chưa đăng nhập.
  static const publicPaths = {
    '/login',
    '/register',
    '/forgot-password',
    '/reset-password',
  };

  /// Đường dẫn của mọi route có thể mở trực tiếp bằng URL.
  ///
  /// Dùng cho contract test. Route có tham số ghi ở dạng khuôn (`/kanji/:id`).
  static const contract = {
    // Xác thực và trạng thái
    '/splash',
    '/login',
    '/register',
    '/forgot-password',
    '/reset-password',
    '/forbidden',
    // Đích đến chính
    '/home',
    '/study',
    '/review',
    '/progress',
    '/account',
    '/admin',
    // Học tập
    '/lessons',
    '/lessons/:id',
    '/lessons/:id/study',
    '/vocabulary',
    '/vocabulary/study',
    '/vocabulary/:id',
    '/kanji',
    '/kanji/:id',
    '/grammar',
    '/grammar/:id',
    '/exercise',
    '/exercise/result/:resultId',
    '/exercise/:id',
    '/exercise-history',
    '/jlpt',
    '/jlpt-practice',
    '/jlpt/:examId/exam',
    '/news',
    '/news/:id',
    '/search',
    // Ôn tập
    '/flashcards',
    '/flashcards/new',
    '/flashcards/:deckId',
    '/flashcards/:deckId/study',
    '/flashcards/:deckId/cards/new',
    '/flashcards/:deckId/cards/:cardId/edit',
    '/streak',
    '/achievements',
    '/notebook',
    '/notebook/new',
    '/notebook/:id',
    '/notebook/:id/edit',
    '/study-groups',
    '/study-groups/new',
    '/study-groups/:id',
    // Tiến độ
    '/learning-history',
    '/statistics',
    '/goals',
    '/leaderboard',
    '/friend-leaderboard',
    // Tài khoản
    '/profile',
    '/settings',
    '/notifications',
    '/notification-settings',
    '/offline-mode',
    '/export',
    '/payment',
    '/report',
    '/help',
    '/change-password',
    // Quản trị
    '/admin/dashboard',
    '/admin/users',
    '/admin/content',
    '/admin/reports',
    '/admin/achievements',
    '/admin/analytics',
    '/admin/transactions',
  };

  /// Quyết định chuyển hướng.
  ///
  /// Thứ tự các nhánh là có chủ đích:
  ///
  /// 1. **Chờ khôi phục phiên xong** trước mọi quyết định khác. Thiếu bước này
  ///    thì lần tải đầu luôn thấy `isAuthenticated == false` và đá người dùng
  ///    đã đăng nhập về `/login`.
  /// 2. Chưa đăng nhập → về `/login`, **mang theo đích ban đầu** trong `from`.
  /// 3. Đã đăng nhập mà vào trang công khai → về `/home`, trừ
  ///    `/reset-password` (người đang đăng nhập vẫn có quyền đặt lại mật khẩu
  ///    bằng link trong email).
  /// 4. Thiếu quyền quản trị → `/forbidden`, không im lặng đá về `/home`.
  @visibleForTesting
  static String? resolveRedirect({
    required String location,
    required String? from,
    required bool sessionRestored,
    required bool isAuthenticated,
    required bool isAdmin,
  }) {
    if (!sessionRestored) {
      if (location == '/splash') return null;
      return Uri(
        path: '/splash',
        queryParameters: {'from': location},
      ).toString();
    }

    if (location == '/splash') {
      final target = from == null || from.isEmpty ? '/home' : from;
      return target == '/splash' ? '/home' : target;
    }

    final isPublic = publicPaths.contains(location);

    if (!isAuthenticated) {
      if (isPublic) return null;
      return Uri(
        path: '/login',
        queryParameters: {'from': location},
      ).toString();
    }

    if (isPublic && location != '/reset-password') return '/home';

    if (location.startsWith('/admin') && !isAdmin) return '/forbidden';

    return null;
  }

  static GoRouter create(AuthProvider auth) {
    return GoRouter(
      initialLocation: '/home',
      // Router tồn tại ổn định và chỉ **tính lại redirect** khi trạng thái
      // đăng nhập đổi. Nó không bị dựng lại, nên cây điều hướng và vị trí cuộn
      // của từng nhánh vẫn còn nguyên sau khi đăng nhập hay đổi quyền.
      refreshListenable: auth,
      redirect: (context, state) => resolveRedirect(
        location: state.uri.path,
        from: state.uri.queryParameters['from'],
        sessionRestored: auth.sessionRestored,
        isAuthenticated: auth.isAuthenticated,
        isAdmin: auth.isAdmin,
      ),
      errorBuilder: (context, state) =>
          NotFoundScreen(location: state.uri.toString()),
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/forbidden',
          builder: (context, state) => const ForbiddenScreen(),
        ),

        // --- Xác thực: ngoài shell, không có thanh điều hướng chính ---
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: '/reset-password',
          builder: (context, state) => ResetPasswordScreen(
            token: state.uri.queryParameters['token'],
          ),
        ),

        // --- Phiên học và phiên thi: chiếm toàn khung, cố ý không có rail ---
        GoRoute(
          path: '/lessons/:id/study',
          builder: (context, state) =>
              LessonStudyScreen(lessonId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/jlpt/:examId/exam',
          builder: (context, state) => JLPTExamScreen(
            examId: state.pathParameters['examId']!,
            title: state.uri.queryParameters['title'] ?? 'Đề thi JLPT',
          ),
        ),
        GoRoute(
          path: '/flashcards/:deckId/study',
          redirect: (context, state) {
            // Màn học thẻ cần đối tượng bộ thẻ. Mở thẳng URL này (F5, dán
            // link) thì không có gì để khôi phục, nên đưa về trang bộ thẻ —
            // nơi bấm "Học" một phát là vào lại được.
            if (state.extra is! FlashcardDeck) {
              return '/flashcards/${state.pathParameters['deckId']}';
            }
            return null;
          },
          builder: (context, state) =>
              FlashcardStudyScreen(flashcardDeck: state.extra as FlashcardDeck),
        ),
        // Phiên học thẻ dựng từ danh sách từ vựng đang lọc, không từ bộ thẻ.
        // Khai báo **trước** `ShellRoute` để không bị `/vocabulary/:id` bắt
        // nhầm "study" làm mã từ vựng.
        GoRoute(
          path: '/vocabulary/study',
          redirect: (context, state) =>
              state.extra is List<Vocabulary> ? null : '/vocabulary',
          builder: (context, state) => FlashcardStudyScreen(
            level: state.uri.queryParameters['level'],
            vocabularies: state.extra as List<Vocabulary>,
          ),
        ),

        // --- Mọi trang còn lại nằm trong shell điều hướng ---
        ShellRoute(
          builder: (context, state, child) => AppShell(child: child),
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
            ),
            GoRoute(
              path: '/study',
              builder: (context, state) =>
                  const HubScreen(destinationPath: '/study'),
            ),
            GoRoute(
              path: '/review',
              builder: (context, state) =>
                  const HubScreen(destinationPath: '/review'),
            ),
            GoRoute(
              path: '/account',
              builder: (context, state) =>
                  const HubScreen(destinationPath: '/account'),
            ),
            GoRoute(
              path: '/admin',
              builder: (context, state) =>
                  const HubScreen(destinationPath: '/admin'),
            ),

            // Học tập
            GoRoute(
              path: '/lessons',
              builder: (context, state) => const LessonListScreen(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (context, state) =>
                      LessonDetailScreen(lessonId: state.pathParameters['id']!),
                ),
              ],
            ),
            GoRoute(
              path: '/vocabulary',
              builder: (context, state) => const VocabularyMainScreen(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (context, state) => VocabularyDetailScreen(
                    vocabularyId: state.pathParameters['id']!,
                  ),
                ),
              ],
            ),
            GoRoute(
              path: '/kanji',
              builder: (context, state) => const KanjiListScreen(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (context, state) =>
                      KanjiDetailScreen(kanjiId: state.pathParameters['id']!),
                ),
              ],
            ),
            GoRoute(
              path: '/grammar',
              builder: (context, state) => GrammarListScreen(
                level: state.uri.queryParameters['level'],
              ),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (context, state) => GrammarDetailScreen(
                    grammarId: state.pathParameters['id']!,
                  ),
                ),
              ],
            ),
            GoRoute(
              path: '/exercise',
              builder: (context, state) => ExerciseListScreen(
                lessonId: state.uri.queryParameters['lessonId'],
                lessonTitle: state.uri.queryParameters['lessonTitle'],
              ),
              routes: [
                // Đặt trước `:id` để "result" không bị bắt làm mã bài tập.
                GoRoute(
                  path: 'result/:resultId',
                  builder: (context, state) => ExerciseResultScreen(
                    resultId: state.pathParameters['resultId']!,
                  ),
                ),
                GoRoute(
                  path: ':id',
                  builder: (context, state) => ExerciseDetailScreen(
                    exerciseId: state.pathParameters['id']!,
                  ),
                ),
              ],
            ),
            GoRoute(
              path: '/exercise-history',
              builder: (context, state) => const ExerciseHistoryScreen(),
            ),
            GoRoute(
              path: '/jlpt',
              builder: (context, state) => const JLPTListScreen(),
            ),
            GoRoute(
              path: '/jlpt-practice',
              builder: (context, state) => const JLPTPracticeScreen(),
            ),
            GoRoute(
              path: '/news',
              builder: (context, state) => const NewsListScreen(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (context, state) =>
                      NewsDetailScreen(newsId: state.pathParameters['id']!),
                ),
              ],
            ),
            GoRoute(
              path: '/search',
              builder: (context, state) => const SearchScreen(),
            ),

            // Ôn tập
            GoRoute(
              path: '/flashcards',
              builder: (context, state) =>
                  const HubScreen(destinationPath: '/review'),
              routes: [
                GoRoute(
                  path: 'new',
                  builder: (context, state) =>
                      const CreateFlashcardDeckScreen(),
                ),
                GoRoute(
                  path: ':deckId',
                  builder: (context, state) => FlashcardDeckDetailScreen(
                    deckId: state.pathParameters['deckId']!,
                  ),
                  routes: [
                    GoRoute(
                      path: 'cards/new',
                      builder: (context, state) => EditFlashcardCardScreen(
                        deckId: state.pathParameters['deckId']!,
                      ),
                    ),
                    GoRoute(
                      path: 'cards/:cardId/edit',
                      redirect: (context, state) => state.extra is FlashcardCard
                          ? null
                          : '/flashcards/${state.pathParameters['deckId']}',
                      builder: (context, state) => EditFlashcardCardScreen(
                        deckId: state.pathParameters['deckId']!,
                        card: state.extra as FlashcardCard,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            GoRoute(
              path: '/streak',
              builder: (context, state) => const StreakScreen(),
            ),
            GoRoute(
              path: '/achievements',
              builder: (context, state) => const AchievementScreen(),
            ),
            GoRoute(
              path: '/notebook',
              builder: (context, state) => const NotebookListScreen(),
              routes: [
                GoRoute(
                  path: 'new',
                  builder: (context, state) => const NotebookFormScreen(),
                ),
                GoRoute(
                  path: ':id',
                  builder: (context, state) =>
                      NotebookDetailScreen(noteId: state.pathParameters['id']!),
                  routes: [
                    GoRoute(
                      path: 'edit',
                      builder: (context, state) => NotebookFormScreen(
                        noteId: state.pathParameters['id'],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            GoRoute(
              path: '/study-groups',
              builder: (context, state) => const StudyGroupListScreen(),
              routes: [
                GoRoute(
                  path: 'new',
                  builder: (context, state) => const CreateGroupScreen(),
                ),
                GoRoute(
                  path: ':id',
                  builder: (context, state) =>
                      GroupDetailScreen(groupId: state.pathParameters['id']!),
                ),
              ],
            ),

            // Tiến độ
            GoRoute(
              path: '/progress',
              builder: (context, state) => const ProgressDashboardScreen(),
            ),
            GoRoute(
              path: '/learning-history',
              builder: (context, state) => const LearningHistoryScreen(),
            ),
            GoRoute(
              path: '/statistics',
              builder: (context, state) => const UserStatisticsScreen(),
            ),
            GoRoute(
              path: '/goals',
              builder: (context, state) => const LearningGoalsScreen(),
            ),
            GoRoute(
              path: '/leaderboard',
              builder: (context, state) => const LeaderboardScreen(),
            ),
            GoRoute(
              path: '/friend-leaderboard',
              builder: (context, state) => const FriendLeaderboardScreen(),
            ),

            // Tài khoản
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
            GoRoute(
              path: '/notifications',
              builder: (context, state) => const NotificationsScreen(),
            ),
            GoRoute(
              path: '/notification-settings',
              builder: (context, state) => const NotificationSettingsScreen(),
            ),
            GoRoute(
              path: '/offline-mode',
              builder: (context, state) => const OfflineModeScreen(),
            ),
            GoRoute(
              path: '/export',
              builder: (context, state) => const ExportScreen(),
            ),
            GoRoute(
              path: '/payment',
              builder: (context, state) => const PaymentScreen(),
            ),
            GoRoute(
              path: '/report',
              builder: (context, state) => const ReportScreen(),
            ),
            GoRoute(
              path: '/help',
              builder: (context, state) => const HelpScreen(),
            ),
            GoRoute(
              path: '/change-password',
              builder: (context, state) => const ChangePasswordScreen(),
            ),

            // Quản trị
            GoRoute(
              path: '/admin/dashboard',
              builder: (context, state) => const AdminDashboardScreen(),
            ),
            GoRoute(
              path: '/admin/users',
              builder: (context, state) => const AdminUserManagementScreen(),
            ),
            GoRoute(
              path: '/admin/content',
              builder: (context, state) => const AdminContentManagementScreen(),
            ),
            GoRoute(
              path: '/admin/reports',
              builder: (context, state) => const AdminReportManagementScreen(),
            ),
            GoRoute(
              path: '/admin/achievements',
              builder: (context, state) =>
                  const AdminAchievementManagementScreen(),
            ),
            GoRoute(
              path: '/admin/analytics',
              builder: (context, state) => const AdminAnalyticsScreen(),
            ),
            GoRoute(
              path: '/admin/transactions',
              builder: (context, state) => const AdminTransactionScreen(),
            ),
          ],
        ),
      ],
    );
  }
}
