import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/content_pane.dart';
import '../../auth/providers/auth_provider.dart';
import '../../news/widgets/news_carousel_widget.dart';
import '../../streaks/providers/streak_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _lastLoadedUserId;

  List<Map<String, dynamic>> _getMenuItems(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return [
      {
        'icon': Icons.menu_book,
        'title': l10n.menuLesson,
        'subtitle': l10n.menuLessonSubtitle,
        'route': '/lessons',
      },
      {
        'icon': Icons.spellcheck,
        'title': l10n.menuVocabulary,
        'subtitle': l10n.menuVocabularySubtitle,
        'route': '/vocabulary',
      },
      {
        'icon': Icons.draw_outlined,
        'title': l10n.menuKanji,
        'subtitle': l10n.menuKanjiSubtitle,
        'route': '/kanji',
      },
      {
        'icon': Icons.quiz_outlined,
        'title': l10n.menuExercise,
        'subtitle': l10n.menuExerciseSubtitle,
        'route': '/exercise',
      },
      {
        'icon': Icons.workspace_premium_outlined,
        'title': l10n.menuJlpt,
        'subtitle': l10n.menuJlptSubtitle,
        'route': '/jlpt',
      },
      {
        'icon': Icons.newspaper,
        'title': l10n.menuNews,
        'subtitle': l10n.menuNewsSubtitle,
        'route': '/news',
      },
      {
        'icon': Icons.group,
        'title': l10n.menuStudyGroup,
        'subtitle': l10n.menuStudyGroupSubtitle,
        'route': '/study-groups',
      },
      {
        'icon': Icons.edit_note,
        'title': l10n.menuNotebook,
        'subtitle': l10n.menuNotebookSubtitle,
        'route': '/notebook',
      },
      {
        'icon': Icons.emoji_events,
        'title': l10n.menuStreak,
        'subtitle': l10n.menuStreakSubtitle,
        'route': '/streak',
      },
    ];
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload streak khi user ID thay đổi (đăng nhập tài khoản khác)
    final authProvider = Provider.of<AuthProvider>(context, listen: true);
    if (authProvider.isAuthenticated) {
      final currentUserId = authProvider.user?.id;
      if (currentUserId != null && currentUserId != _lastLoadedUserId) {
        debugPrint('🔄 User changed! Loading streak for user: $currentUserId');
        _lastLoadedUserId = currentUserId;
        _loadUserData();
      }
    } else {
      // User logged out, clear lastLoadedUserId
      _lastLoadedUserId = null;
    }
  }

  /// Tải lại dữ liệu cho nút làm mới trên `AppBar`.
  Future<void> _refresh() async {
    if (!mounted) return;
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated) return;
    await context.read<StreakProvider>().loadStreak();
  }

  void _loadUserData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        if (authProvider.isAuthenticated) {
          debugPrint(
              '📊 Loading streak for user: ${authProvider.user?.username} (${authProvider.user?.id})');
          final streakProvider =
              Provider.of<StreakProvider>(context, listen: false);
          streakProvider.loadStreak();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // Điều hướng chính (drawer + thanh dưới) đã chuyển sang `AppShell`. Trang
    // chủ chỉ còn là một trang nội dung, nên không tự dựng lối đi thứ hai.
    return AppScaffold(
      title: l10n.appName,
      onRefresh: _refresh,
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          tooltip: 'Thông báo',
          onPressed: () => context.push('/notifications'),
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          tooltip: 'Cài đặt',
          onPressed: () => context.push('/settings'),
        ),
      ],
      body: _buildHomeContent(),
    );
  }

  Widget _buildHomeContent() {
    final l10n = AppLocalizations.of(context);

    return SingleChildScrollView(
      child: ContentPane(
        maxWidth: AppContentWidth.dashboard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Lời chào: một khối phẳng màu thương hiệu, không đổ bóng màu —
            // bóng xanh mờ dưới mọi thẻ là dấu hiệu rõ nhất của giao diện
            // dựng vội.
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${l10n.welcomeBack} 👋',
                          style: Theme.of(context)
                              .textTheme
                              .headlineLarge
                              ?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          l10n.continueLearning,
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.85)),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 96,
                    height: 96,
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.translate,
                            size: 40,
                            color: AppColors.primary,
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Quick stats
            Consumer<StreakProvider>(
              builder: (context, streakProvider, child) {
                final streak = streakProvider.currentStreak;
                return Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => context.push('/streak'),
                        child: _buildStatCard(
                          l10n.streak,
                          '${streak?.currentStreak ?? 0} ${l10n.days}',
                          Icons.local_fire_department,
                          Colors.orange,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () => context.push('/streak'),
                        child: _buildStatCard(
                          l10n.points,
                          '${streak?.totalXP ?? 0} ${l10n.xp}',
                          Icons.star,
                          Colors.amber,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // News Carousel
            const NewsCarouselWidget(),
            const SizedBox(height: 24),

            // Main menu
            Text(
              l10n.lessons,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                // --- SỬA TỶ LỆ ĐỂ KHÔNG BỊ TRÀN CHỮ ---
                childAspectRatio: 0.9,
                // --------------------------------------
              ),
              itemCount: _getMenuItems(context).length,
              itemBuilder: (context, index) {
                final item = _getMenuItems(context)[index];
                return _buildMenuCard(
                  icon: item['icon'],
                  title: item['title'],
                  subtitle: item['subtitle'],
                  // `/streak`, `/study-groups` và `/news` trước đây phải mở
                  // bằng `MaterialPageRoute` vì thiếu route; nay đã có đường dẫn
                  // thật nên mở như mọi mục khác.
                  onTap: () => context.push(item['route'] as String),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    // Con số là thứ người học tìm ở đây, nên nó được cỡ chữ lớn nhất khối;
    // viền mảnh thay bóng đổ để các thẻ không trôi nổi trên nền.
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(value, style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 28, color: AppColors.primary),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
