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
  /// Bề rộng tối đa một ô trong lưới khám phá. Lưới chia cột theo con số này:
  /// hai cột như mockup ở cả web lẫn điện thoại, một cột khi màn quá hẹp.
  /// Số cột = trần(bề rộng cột ÷ (con số này + khe)), nên với cột 640px con số
  /// này phải từ 308 trở lên, không thì lưới nhảy sang ba cột.
  static const double _exploreTileMaxWidth = 320;

  /// Chiều cao cố định của ô, để mọi ô bằng nhau dù phụ đề dài ngắn khác nhau.
  static const double _exploreTileHeight = 168;

  /// Ô icon tô đặc màu mảng và icon trắng bên trong, theo mockup.
  static const double _exploreIconBox = 52;
  static const double _exploreIconSize = 28;

  /// Linh vật ở góc hero và phần thanh tiến độ chiếm trong hero, theo mockup.
  static const double _heroLogoSize = 96;
  static const double _heroBarWidthFactor = 0.64;

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
    final user = context.watch<AuthProvider>().user;
    final name = user?.fullName ?? user?.username;

    // Trên web, nội dung bó lại đúng một cột như trên điện thoại rồi căn giữa.
    // Trải hết bề ngang cửa sổ thì mỗi thẻ thành một dải trống.
    return SingleChildScrollView(
      child: ContentPane(
        maxWidth: AppContentWidth.feed,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGreeting(context, l10n, name),
            AppGap.lg,
            _buildStatRow(context, l10n),
            AppGap.lg,
            _buildHeroCard(context, l10n),
            AppGap.lg,
            _buildSectionLabel(context, l10n.wordOfDay),
            _buildWordOfDayCard(context),
            AppGap.lg,
            // Lưới khám phá đứng trước tin tức: đây là đường đi tới mọi mảng
            // học, còn tin tức chỉ là thứ đọc thêm.
            _buildSectionLabel(context, l10n.explore),
            _buildExploreSection(context),
            AppGap.xl,
            const NewsCarouselWidget(),
          ],
        ),
      ),
    );
  }

  /// Màu chữ phụ theo chế độ sáng/tối.
  Color _mutedText(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? AppColors.darkTextSecondary
          : AppColors.textSecondary;

  /// Màu chữ chính theo chế độ sáng/tối.
  Color _strongText(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? AppColors.darkTextPrimary
          : AppColors.textPrimary;

  Widget _buildGreeting(
    BuildContext context,
    AppLocalizations l10n,
    String? name,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name == null
              ? '${l10n.homeGreeting}! \u{1F44B}'
              : '${l10n.homeGreeting}, $name! \u{1F44B}',
          style: AppTypography.heroDisplay(
            size: AppTypography.headline,
            color: _strongText(context),
            height: 1.15,
          ),
        ),
        AppGap.xs,
        Text(
          l10n.homeSubtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: _mutedText(context),
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Text(
        text,
        style: AppTypography.heroDisplay(
          size: AppTypography.subtitle,
          color: _strongText(context),
        ),
      ),
    );
  }

  /// Hai chip chỉ số. Hai màu khác nhau để không nhìn thành một khối liền.
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
                  emoji: '\u{1F525}',
                  value: '${streak?.currentStreak ?? 0} ${l10n.days}',
                  label: l10n.streak,
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
                  emoji: '\u{26A1}',
                  value: '${streak?.totalXP ?? 0}',
                  label: '${l10n.points} ${l10n.xp}',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Chữ trên chip dùng mực đậm ở cả hai chế độ: nền chip luôn là cam/hổ phách
  /// sáng, chữ trắng trên đó quá nhạt để đọc.
  Widget _buildStatChip(
    BuildContext context, {
    required String emoji,
    required String value,
    required String label,
  }) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: AppTypography.title)),
        AppGap.sm,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: AppTypography.heroDisplay(
                  size: AppTypography.subtitle,
                  color: AppColors.textPrimary,
                  height: 1.1,
                ),
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: AppTypography.caption,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary.withValues(alpha: 0.75),
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Hành động chính trong ngày: xanh lá, tách hẳn khỏi tím của thương hiệu.
  ///
  /// Chưa có nguồn dữ liệu "bài đang học dở", nên tiêu đề là nhóm bài chứ không
  /// phải tên một bài cụ thể, và thanh tiến độ là mốc minh hoạ.
  Widget _buildHeroCard(BuildContext context, AppLocalizations l10n) {
    final textTheme = Theme.of(context).textTheme;
    const onHero = Colors.white;

    return ChunkyCard(
      color: AppColors.heroAction,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.continueEyebrow,
                  style: textTheme.labelMedium?.copyWith(
                    color: onHero.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
                AppGap.xs,
                Text(
                  l10n.continueTitle,
                  style: AppTypography.heroDisplay(
                    size: AppTypography.title,
                    color: onHero,
                    height: 1.15,
                  ),
                ),
                AppGap.xs,
                Text(
                  l10n.continueLearning,
                  style: textTheme.bodySmall?.copyWith(
                    color: onHero.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                AppGap.md,
                FractionallySizedBox(
                  widthFactor: _heroBarWidthFactor,
                  child: ClipRRect(
                    borderRadius: AppRadius.pillAll,
                    child: LinearProgressIndicator(
                      value: 0.6,
                      minHeight: AppSpacing.md,
                      backgroundColor: Colors.black.withValues(alpha: 0.16),
                      valueColor: const AlwaysStoppedAnimation<Color>(onHero),
                    ),
                  ),
                ),
                AppGap.md,
                ChunkyCard(
                  color: AppColors.surface,
                  borderRadius: AppRadius.lgAll,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.md,
                  ),
                  onTap: () => context.push('/lessons'),
                  child: Text(
                    '${l10n.continueCta} \u{2192}',
                    style: AppTypography.heroDisplay(
                      size: AppTypography.body,
                      color: ChunkyCard.edgeOf(AppColors.heroAction),
                    ),
                  ),
                ),
              ],
            ),
          ),
          AppGap.md,
          Image.asset(
            'assets/images/logo.png',
            width: _heroLogoSize,
            height: _heroLogoSize,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.translate,
              size: _heroLogoSize,
              color: onHero,
            ),
          ),
        ],
      ),
    );
  }

  /// Thẻ khoe chữ Nhật: kanji lớn tô màu mảng kanji, cách đọc, nghĩa, nhãn loại
  /// từ và nút phát âm tô màu.
  Widget _buildWordOfDayCard(BuildContext context) {
    final muted = _mutedText(context);
    final tagColor = ChunkyCard.edgeOf(AppColors.kanji);

    return ChunkyCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Text(
            '猫',
            style: AppTypography.japaneseDisplay(
              color: AppColors.kanji,
              weight: FontWeight.w900,
            ),
          ),
          AppGap.lg,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ねこ',
                  style: AppTypography.japaneseDisplay(
                    size: AppTypography.subtitle,
                    weight: FontWeight.w700,
                    color: muted,
                  ),
                ),
                Text(
                  'con mèo',
                  style: AppTypography.heroDisplay(
                    size: AppTypography.subtitle,
                    weight: FontWeight.w700,
                    color: _strongText(context),
                  ),
                ),
                AppGap.xs,
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.kanji.withValues(alpha: 0.14),
                    borderRadius: AppRadius.pillAll,
                  ),
                  child: Text(
                    'Danh từ · N5',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: tagColor,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ],
            ),
          ),
          Tooltip(
            message: 'Phát âm',
            child: ChunkyCard(
              color: AppColors.vocabulary,
              borderRadius: AppRadius.lgAll,
              padding: const EdgeInsets.all(AppSpacing.md),
              onTap: _showPronunciationComingSoon,
              child: const Icon(Icons.volume_up, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExploreSection(BuildContext context) {
    final items = _getExploreItems(context);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: _exploreTileMaxWidth,
        mainAxisExtent: _exploreTileHeight,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => _buildExploreCard(context, items[index]),
    );
  }

  /// Một ô khám phá: ô icon tô đặc màu mảng có mép riêng, tên mảng và phụ đề.
  Widget _buildExploreCard(BuildContext context, _ExploreItem item) {
    final muted = _mutedText(context);

    return ChunkyCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      onTap: () => context.push(item.route),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: _exploreIconBox,
            height: _exploreIconBox,
            decoration: BoxDecoration(
              color: item.color,
              borderRadius: AppRadius.lgAll,
              boxShadow: [
                BoxShadow(
                  color: ChunkyCard.edgeOf(item.color),
                  offset: const Offset(0, ChunkyCard.edgeDepth),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Icon(
              item.icon,
              size: _exploreIconSize,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppSpacing.md + ChunkyCard.edgeDepth),
          // `Flexible` để khi người dùng phóng to cỡ chữ hệ thống, chữ rút bớt
          // dòng chứ không đẩy ô tràn khung thành sọc vàng.
          Flexible(
            child: Text(
              item.title,
              style: AppTypography.heroDisplay(
                size: AppTypography.body,
                color: _strongText(context),
                height: 1.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          AppGap.xs,
          Flexible(
            child: Text(
              item.subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: AppTypography.caption,
                    fontWeight: FontWeight.w600,
                    color: muted,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
