import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/chunky_card.dart';
import '../../../shared/widgets/content_pane.dart';
import '../../auth/providers/auth_provider.dart';
import '../../news/widgets/news_carousel_widget.dart';
import '../../streaks/providers/streak_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _ExploreItem {
  const _ExploreItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
  final Color color;
}

class _HomeScreenState extends State<HomeScreen> {
  /// Bề rộng tối đa một ô trong lưới khám phá. Lưới chia cột theo con số này,
  /// nên ô giữ kích thước dễ bấm ở mọi bề rộng cửa sổ thay vì phình ra.
  static const double _exploreTileMaxWidth = 220;
  static const double _statIconSize = 28;
  static const double _heroLogoSize = 72;

  String? _lastLoadedUserId;

  List<_ExploreItem> _getExploreItems(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return [
      _ExploreItem(
        icon: Icons.menu_book,
        title: l10n.menuLesson,
        subtitle: l10n.menuLessonSubtitle,
        route: '/lessons',
        color: AppColors.lesson,
      ),
      _ExploreItem(
        icon: Icons.spellcheck,
        title: l10n.menuVocabulary,
        subtitle: l10n.menuVocabularySubtitle,
        route: '/vocabulary',
        color: AppColors.vocabulary,
      ),
      _ExploreItem(
        icon: Icons.draw_outlined,
        title: l10n.menuKanji,
        subtitle: l10n.menuKanjiSubtitle,
        route: '/kanji',
        color: AppColors.kanji,
      ),
      _ExploreItem(
        icon: Icons.quiz_outlined,
        title: l10n.menuExercise,
        subtitle: l10n.menuExerciseSubtitle,
        route: '/exercise',
        color: AppColors.exercise,
      ),
      _ExploreItem(
        icon: Icons.workspace_premium_outlined,
        title: l10n.menuJlpt,
        subtitle: l10n.menuJlptSubtitle,
        route: '/jlpt',
        color: AppColors.jlpt,
      ),
      _ExploreItem(
        icon: Icons.newspaper,
        title: l10n.menuNews,
        subtitle: l10n.menuNewsSubtitle,
        route: '/news',
        color: AppColors.news,
      ),
      _ExploreItem(
        icon: Icons.group,
        title: l10n.menuStudyGroup,
        subtitle: l10n.menuStudyGroupSubtitle,
        route: '/study-groups',
        color: AppColors.group,
      ),
      _ExploreItem(
        icon: Icons.edit_note,
        title: l10n.menuNotebook,
        subtitle: l10n.menuNotebookSubtitle,
        route: '/notebook',
        color: AppColors.notebook,
      ),
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

  void _showPronunciationComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tính năng phát âm sắp ra mắt')),
    );
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
      body: _buildHomeContent(context),
    );
  }

  Widget _buildHomeContent(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final user = context.watch<AuthProvider>().user;
    final name = user?.fullName ?? user?.username;

    // Trên web, nội dung bó lại đúng một cột đọc được rồi căn giữa. Trải hết bề
    // ngang cửa sổ thì mỗi thẻ thành một dải trống, chữ nằm lọt thỏm bên trái.
    return SingleChildScrollView(
      child: ContentPane(
        maxWidth: AppContentWidth.reading,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name == null
                  ? '${l10n.homeGreeting}! \u{1F44B}'
                  : '${l10n.homeGreeting}, $name! \u{1F44B}',
              style: AppTypography.heroDisplay(
                size: AppTypography.headline,
                color: theme.textTheme.headlineLarge?.color,
              ),
            ),
            AppGap.lg,
            _buildStatRow(context, l10n),
            AppGap.xl,
            _buildHeroCard(context, l10n, theme),
            AppGap.xl,
            _buildWordOfDayCard(context, theme),
            AppGap.xl,
            // Lưới khám phá đứng trước tin tức: đây là đường đi tới mọi mảng
            // học, còn tin tức chỉ là thứ đọc thêm.
            _buildExploreSection(context, theme, l10n),
            AppGap.xl,
            const NewsCarouselWidget(),
          ],
        ),
      ),
    );
  }

  /// Hai thẻ chỉ số. Hai màu khác nhau để không nhìn thành một khối cam dài.
  Widget _buildStatRow(BuildContext context, AppLocalizations l10n) {
    return Consumer<StreakProvider>(
      builder: (context, streakProvider, child) {
        final streak = streakProvider.currentStreak;
        return Row(
          children: [
            Expanded(
              child: ChunkyCard(
                color: AppColors.streak,
                onTap: () => context.push('/streak'),
                child: _buildStatChip(
                  context,
                  l10n.streak,
                  '${streak?.currentStreak ?? 0} ${l10n.days}',
                  Icons.local_fire_department,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: ChunkyCard(
                color: AppColors.xp,
                onTap: () => context.push('/streak'),
                child: _buildStatChip(
                  context,
                  l10n.points,
                  '${streak?.totalXP ?? 0} ${l10n.xp}',
                  Icons.star,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Hành động chính trong ngày. Xanh lá để tách khỏi tím của thương hiệu.
  Widget _buildHeroCard(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    return ChunkyCard(
      color: AppColors.heroAction,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.continueLearning,
                  style: AppTypography.heroDisplay(
                    size: AppTypography.title,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ClipRRect(
                  borderRadius: AppRadius.pillAll,
                  child: LinearProgressIndicator(
                    // Chưa có nguồn dữ liệu "bài đang học dở" nên hiển thị một
                    // mốc minh hoạ, không phải tiến độ thật.
                    value: 0.4,
                    minHeight: AppSpacing.sm,
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                ChunkyCard(
                  color: AppColors.surface,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  onTap: () => context.push('/lessons'),
                  child: Text(
                    l10n.menuLesson,
                    style: theme.textTheme.labelLarge
                        ?.copyWith(color: AppColors.heroAction),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          ClipOval(
            child: Image.asset(
              'assets/images/logo.png',
              width: _heroLogoSize,
              height: _heroLogoSize,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.translate,
                size: _heroLogoSize,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWordOfDayCard(BuildContext context, ThemeData theme) {
    return ChunkyCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Từ mới hôm nay', style: theme.textTheme.titleSmall),
                const SizedBox(height: AppSpacing.sm),
                Text('猫', style: AppTypography.japaneseDisplay()),
                Text('ねこ', style: AppTypography.japaneseReading()),
                const SizedBox(height: AppSpacing.xs),
                Text('con mèo', style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
          IconButton(
            onPressed: _showPronunciationComingSoon,
            tooltip: 'Phát âm',
            icon: Icon(Icons.volume_up, color: theme.colorScheme.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildExploreSection(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    final items = _getExploreItems(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.explore, style: theme.textTheme.titleLarge),
        AppGap.lg,
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          // Ô co theo bề rộng thật: ba cột trên web, hai cột trên điện thoại,
          // thay vì hai ô khổng lồ khi cửa sổ rộng.
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: _exploreTileMaxWidth,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: 1.05,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) =>
              _buildExploreCard(context, items[index]),
        ),
      ],
    );
  }

  /// Chữ trên thẻ chỉ số dùng mực đậm: chữ trắng trên cam và hổ phách quá nhạt
  /// để đọc.
  Widget _buildStatChip(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: _statIconSize, color: AppColors.textPrimary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: AppColors.textPrimary),
              ),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExploreCard(BuildContext context, _ExploreItem item) {
    final theme = Theme.of(context);
    return ChunkyCard(
      onTap: () => context.push(item.route),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(item.icon, size: _statIconSize, color: item.color),
          ),
          const SizedBox(height: AppSpacing.md),
          // `Flexible` để khi người dùng phóng to cỡ chữ hệ thống, chữ rút bớt
          // dòng chứ không đẩy ô tràn khung thành sọc vàng.
          Flexible(
            child: Text(
              item.title,
              style: theme.textTheme.titleSmall,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Flexible(
            child: Text(
              item.subtitle,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
