import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/calm_colors.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/content_pane.dart';
import '../../auth/providers/auth_provider.dart';
import '../../news/providers/news_provider.dart';
import '../../news/widgets/news_carousel_widget.dart';
import '../../streaks/providers/streak_provider.dart';
import '../providers/home_provider.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/home_greeting.dart';
import '../widgets/home_layout.dart';
import '../widgets/home_stat_cards.dart';
import '../widgets/next_lesson_card.dart';
import '../widgets/study_corner.dart';
import '../widgets/word_of_day_card.dart';

/// Trang chủ: lời chào, chỉ số, bài học tiếp theo, góc học tập, từ mới hôm nay
/// và tin tức mới — theo thứ tự đó, trên nền kem của bảng màu dịu.
///
/// Không có nút làm mới: kéo xuống để làm mới cả màn (kéo bằng chuột cũng được
/// trên web, để desktop không mất đường làm mới).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _loadedUserId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Nạp lại khi đổi tài khoản; đăng xuất thì quên người dùng cũ.
    final auth = context.watch<AuthProvider>();
    final userId = auth.isAuthenticated ? auth.user?.id : null;
    if (userId == _loadedUserId) return;
    _loadedUserId = userId;
    if (userId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }
  }

  Future<void> _load() async {
    if (!mounted) return;
    final level = context.read<AuthProvider>().user?.currentLevel;
    await Future.wait([
      context.read<StreakProvider>().loadStreak(),
      context.read<HomeProvider>().load(userLevel: level),
    ]);
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    final news = context.read<NewsProvider>();
    await Future.wait([_load(), news.loadNews(refresh: true)]);
  }

  @override
  Widget build(BuildContext context) {
    final calm = CalmColors.of(context);
    final l10n = AppLocalizations.of(context);
    final home = context.watch<HomeProvider>();
    final user = context.watch<AuthProvider>().user;
    final streak = context.watch<StreakProvider>().currentStreak;
    final fullName = user?.fullName?.trim();
    final name =
        fullName == null || fullName.isEmpty ? user?.username : fullName;
    final word = home.wordOfDay;

    return AppScaffold(
      title: l10n.appName,
      backgroundColor: calm.background,
      appBar: HomeAppBar(unreadNotifications: home.unreadNotifications),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: calm.green,
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context)
              .copyWith(dragDevices: {...PointerDeviceKind.values}),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ContentPane(
              maxWidth: AppContentWidth.feed,
              padding: const EdgeInsets.fromLTRB(
                  HomeLayout.gutter, 8, HomeLayout.gutter, HomeLayout.section),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  HomeGreeting(name: name, now: DateTime.now()),
                  const SizedBox(height: HomeLayout.block),
                  HomeStatCards(
                      streakDays: streak?.currentStreak ?? 0,
                      totalXp: streak?.totalXP ?? 0),
                  const SizedBox(height: HomeLayout.block),
                  NextLessonCard(state: home.nextLesson),
                  const SizedBox(height: HomeLayout.section),
                  HomeSectionHeader(title: l10n.studyCorner),
                  const StudyCorner(),
                  // Không có từ nào (lỗi mạng, trình độ chưa có từ) thì bỏ cả mục
                  // chứ không hiện một từ mẫu.
                  if (word.isLoading || word.valueOrNull != null) ...[
                    const SizedBox(height: HomeLayout.section),
                    HomeSectionHeader(
                        title: l10n.wordOfDay,
                        onSeeAll: () => context.push('/vocabulary')),
                    if (word.valueOrNull case final value?)
                      WordOfDayCard(word: value)
                    else
                      const WordOfDayPlaceholder(),
                  ],
                  NewsCarouselWidget(
                    header: Padding(
                      padding: const EdgeInsets.only(top: HomeLayout.section),
                      child: HomeSectionHeader(
                          title: l10n.latestNews,
                          onSeeAll: () => context.push('/news')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
