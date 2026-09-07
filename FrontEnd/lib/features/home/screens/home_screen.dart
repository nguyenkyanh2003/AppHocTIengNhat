import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../streaks/providers/streak_provider.dart';
import '../../../app/localization/locale_provider.dart';
import '../../../core/layout/responsive_helper.dart';
import '../../../app/localization/app_localizations.dart';
import '../../streaks/screens/streak_screen.dart';
import '../../progress/screens/progress_dashboard_screen.dart';
import '../../study_groups/screens/study_group_list_screen.dart';
import '../../news/screens/news_list_screen.dart';
import '../../news/widgets/news_carousel_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RouteAware {
  int _selectedIndex = 0;
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
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.pushNamed(context, '/notifications');
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context, user),
      body: _selectedIndex == 0
          ? _buildHomeContent()
          : _selectedIndex == 1
              ? _buildProgressContent()
              : _buildProfileContent(user),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: AppLocalizations.of(context).home,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.show_chart),
            label: AppLocalizations.of(context).progress,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: AppLocalizations.of(context).profile,
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, dynamic user) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isAdmin = authProvider.isAdmin;
    final userFromProvider = authProvider.user;

    // Debug: In ra role để check
    debugPrint('🔍 ========== DRAWER DEBUG ==========');
    debugPrint('🔍 user param role: ${user?.role}');
    debugPrint('🔍 authProvider.user.role: ${userFromProvider?.role}');
    debugPrint('🔍 isAdmin: $isAdmin');
    debugPrint('🔍 ====================================');

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[700]!, Colors.blue[500]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            accountName: Row(
              children: [
                Text(
                  user?.fullName ?? user?.username ?? 'Người dùng',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                if (isAdmin) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'ADMIN',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            accountEmail: Text(user?.email ?? ''),
            currentAccountPicture: GestureDetector(
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/profile');
              },
              child: CircleAvatar(
                backgroundColor: Colors.white,
                backgroundImage:
                    user?.avatar != null ? NetworkImage(user!.avatar!) : null,
                child: user?.avatar == null
                    ? Text(
                        user?.username?.substring(0, 1).toUpperCase() ?? 'U',
                        style: TextStyle(
                          fontSize: 40.0,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
            ),
          ),
          // Admin Panel Access - Chỉ hiển thị cho admin
          if (userFromProvider?.role == 'admin')
            Container(
              color: Colors.amber.shade50,
              child: ListTile(
                leading:
                    const Icon(Icons.admin_panel_settings, color: Colors.amber),
                title: const Text(
                  '🔐 Admin Panel',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/admin/dashboard');
                },
              ),
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Thông tin cá nhân'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/profile');
            },
          ),
          ListTile(
            leading: const Icon(Icons.analytics),
            title: const Text('Thống kê học tập'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/statistics');
            },
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Tiến độ học tập'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProgressDashboardScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Lịch sử học tập'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/learning-history');
            },
          ),
          ListTile(
            leading: const Icon(Icons.payment),
            title: const Text('Giao dịch'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/transactions');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Trợ giúp'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/help');
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Đăng xuất'),
            // --- SỬA LOGIC ĐĂNG XUẤT TẠI ĐÂY ---
            onTap: () async {
              Navigator.pop(context); // Đóng Drawer
              // Gọi hàm logout, main.dart sẽ tự chuyển màn hình
              await Provider.of<AuthProvider>(context, listen: false).logout();
            },
            // ------------------------------------
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    final l10n = AppLocalizations.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome banner hiện đại hơn
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.blue.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${l10n.welcomeBack} 👋',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.continueLearning,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 110,
                  height: 110,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.translate,
                          size: 40,
                          color: Colors.blue,
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Quick stats
          Consumer<StreakProvider>(
            builder: (context, streakProvider, child) {
              final streak = streakProvider.currentStreak;
              return Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const StreakScreen(),
                          ),
                        );
                      },
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
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const StreakScreen(),
                          ),
                        );
                      },
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
                onTap: () {
                  // Handle screens not in routes yet
                  if (item['route'] == '/streak') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StreakScreen(),
                      ),
                    );
                  } else if (item['route'] == '/study-groups') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StudyGroupListScreen(),
                      ),
                    );
                  } else if (item['route'] == '/news') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NewsListScreen(),
                      ),
                    );
                  } else {
                    Navigator.pushNamed(context, item['route']);
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 28, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
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
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [Colors.white, Colors.blue.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade400, Colors.blue.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, size: 32, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
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

  Widget _buildProgressContent() {
    final l10n = AppLocalizations.of(context);

    return Consumer<StreakProvider>(
      builder: (context, streakProvider, child) {
        final streak = streakProvider.currentStreak;
        final isLoading = streakProvider.isLoading;

        if (isLoading && streak == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: () async {
            await streakProvider.loadStreak();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Streak Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [Colors.orange[700]!, Colors.orange[400]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          '🔥 Streak hiện tại',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '${streak?.currentStreak ?? 0}',
                            style: const TextStyle(
                              fontSize: 56,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Text(
                          l10n.consecutiveDays,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStreakStat(
                              '🏆 Kỷ lục',
                              '${streak?.longestStreak ?? 0} ngày',
                            ),
                            _buildStreakStat(
                              '⭐ Tổng XP',
                              '${streak?.totalXP ?? 0}',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Progress Stats
                Text(
                  'Thống kê học tập',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: ResponsiveHelper.getGridColumns(context),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio:
                      ResponsiveHelper.getCardAspectRatio(context),
                  children: [
                    _buildProgressCard(
                      '📊',
                      'Level',
                      '${streak?.level ?? 1}',
                      Colors.blue,
                    ),
                    _buildProgressCard(
                      '🎯',
                      'XP tới level kế',
                      '${streak?.xpToNextLevel ?? 100}',
                      Colors.purple,
                    ),
                    _buildProgressCard(
                      '📅',
                      'Số ngày đã học',
                      '${streak?.activityDates.length ?? 0}',
                      Colors.green,
                    ),
                    _buildProgressCard(
                      '🔥',
                      'Streak dài nhất',
                      '${streak?.longestStreak ?? 0}',
                      Colors.orange,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Quick Actions
                Text(
                  'Chi tiết',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.dashboard, color: Colors.blue),
                    title: const Text('Tiến độ chi tiết'),
                    subtitle: const Text('Xem biểu đồ và thống kê đầy đủ'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProgressDashboardScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading:
                        const Icon(Icons.emoji_events, color: Colors.amber),
                    title: const Text('Streak & Thành tích'),
                    subtitle: const Text('Xem lịch sử XP và thành tích'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const StreakScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStreakStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white70,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildProgressCard(
      String emoji, String label, String value, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.1),
              color.withValues(alpha: 0.05)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey[600],
                ),
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent(dynamic user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Avatar with user image if available
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.blue,
            backgroundImage:
                user?.avatar != null ? NetworkImage(user.avatar!) : null,
            child: user?.avatar == null
                ? Text(
                    user?.username?.substring(0, 1).toUpperCase() ?? 'U',
                    style: const TextStyle(fontSize: 40, color: Colors.white),
                  )
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            user?.username ?? 'Người dùng',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            user?.email ?? '',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 32),
          _buildProfileOption(
            icon: Icons.person,
            title: 'Chỉnh sửa thông tin',
            onTap: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
          _buildProfileOption(
            icon: Icons.lock,
            title: 'Đổi mật khẩu',
            onTap: () {
              Navigator.pushNamed(context, '/change-password');
            },
          ),
          _buildProfileOption(
            icon: Icons.language,
            title: 'Ngôn ngữ',
            subtitle: _getCurrentLanguageName(),
            onTap: () {
              _showLanguageDialog();
            },
          ),
          _buildProfileOption(
            icon: Icons.notifications,
            title: 'Thông báo',
            onTap: () {
              Navigator.pushNamed(context, '/notification-settings');
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              await Provider.of<AuthProvider>(context, listen: false).logout();
            },
            icon: const Icon(Icons.logout),
            label: const Text('Đăng xuất'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  String _getCurrentLanguageName() {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final currentLocale = localeProvider.locale;

    switch (currentLocale.languageCode) {
      case 'vi':
        return 'Tiếng Việt';
      case 'en':
        return 'English';
      case 'ja':
        return '日本語';
      default:
        return 'Tiếng Việt';
    }
  }

  void _showLanguageDialog() {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final currentLocale = localeProvider.locale;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.language, color: Colors.blue[700]),
            const SizedBox(width: 8),
            const Text('Chọn ngôn ngữ'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption(
              'Tiếng Việt',
              '🇻🇳',
              const Locale('vi', 'VN'),
              currentLocale.languageCode == 'vi',
              localeProvider,
            ),
            const Divider(),
            _buildLanguageOption(
              'English',
              '🇺🇸',
              const Locale('en', 'US'),
              currentLocale.languageCode == 'en',
              localeProvider,
            ),
            const Divider(),
            _buildLanguageOption(
              '日本語',
              '🇯🇵',
              const Locale('ja', 'JP'),
              currentLocale.languageCode == 'ja',
              localeProvider,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(
    String name,
    String flag,
    Locale locale,
    bool isSelected,
    LocaleProvider localeProvider,
  ) {
    return ListTile(
      leading: Text(flag, style: const TextStyle(fontSize: 24)),
      title: Text(
        name,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.blue : null,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: Colors.blue)
          : null,
      onTap: () {
        localeProvider.setLocale(locale);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã đổi ngôn ngữ sang $name'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      },
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title),
        subtitle: subtitle != null
            ? Text(subtitle, style: TextStyle(color: Colors.grey[600]))
            : null,
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
