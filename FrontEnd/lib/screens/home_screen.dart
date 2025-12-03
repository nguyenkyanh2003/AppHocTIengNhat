import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/streak_provider.dart';
import '../core/responsive_helper.dart';
import 'streak/streak_screen.dart';
import 'progress/progress_dashboard_screen.dart';
import 'study_group/study_group_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RouteAware {
  int _selectedIndex = 0;
  String? _lastLoadedUserId;

  final List<Map<String, dynamic>> _menuItems = [
    {
      'icon': Icons.menu_book,
      'title': 'Bài học',
      'subtitle': 'Học từ vựng và ngữ pháp',
      'route': '/lessons',
    },
    {
      'icon': Icons.spellcheck,
      'title': 'Từ vựng',
      'subtitle': 'Học từ mới mỗi ngày',
      'route': '/vocabulary',
    },
    {
      'icon': Icons.draw_outlined,
      'title': 'Kanji',
      'subtitle': 'Học chữ Hán',
      'route': '/kanji',
    },
    {
      'icon': Icons.quiz_outlined,
      'title': 'Luyện tập',
      'subtitle': 'Bài tập và kiểm tra',
      'route': '/exercise',
    },
    {
      'icon': Icons.workspace_premium_outlined,
      'title': 'JLPT',
      'subtitle': 'Luyện thi năng lực',
      'route': '/jlpt',
    },
    {
      'icon': Icons.newspaper,
      'title': 'Tin tức',
      'subtitle': 'Đọc tin tiếng Nhật',
      'route': '/news',
    },
    {
      'icon': Icons.group,
      'title': 'Nhóm học',
      'subtitle': 'Học cùng bạn bè',
      'route': '/study-groups',
    },
    {
      'icon': Icons.edit_note,
      'title': 'Sổ tay',
      'subtitle': 'Ghi chú của bạn',
      'route': '/notebook',
    },
    {
      'icon': Icons.emoji_events,
      'title': 'Streak & Thành tích',
      'subtitle': 'Xem tiến độ và XP',
      'route': '/streak',
    },
  ];

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
          debugPrint('📊 Loading streak for user: ${authProvider.user?.username} (${authProvider.user?.id})');
          final streakProvider = Provider.of<StreakProvider>(context, listen: false);
          streakProvider.loadStreak();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Học Tiếng Nhật'),
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
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label: 'Tiến độ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Cá nhân',
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, dynamic user) {
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
            accountName: Text(
              user?.fullName ?? user?.username ?? 'Người dùng',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            accountEmail: Text(user?.email ?? ''),
            currentAccountPicture: GestureDetector(
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/profile');
              },
              child: CircleAvatar(
                backgroundColor: Colors.white,
                backgroundImage: user?.avatar != null
                    ? NetworkImage(user!.avatar!)
                    : null,
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
                  color: Colors.blue.withOpacity(0.3),
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
                      const Text(
                        'Chào mừng trở lại! 👋',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Hãy tiếp tục hành trình học tiếng Nhật',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
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
                        color: Colors.black.withOpacity(0.1),
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
                        'Chuỗi học',
                        '${streak?.currentStreak ?? 0} ngày',
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
                        'Điểm',
                        '${streak?.totalXP ?? 0} XP',
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

          // Main menu
          Text(
            'Học tập',
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
            itemCount: _menuItems.length,
            itemBuilder: (context, index) {
              final item = _menuItems[index];
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

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
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
              color: color.withOpacity(0.1),
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
            color: Colors.blue.withOpacity(0.15),
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
                        color: Colors.blue.withOpacity(0.3),
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
                        const Text(
                          'ngày liên tiếp',
                          style: TextStyle(
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
                  childAspectRatio: ResponsiveHelper.getCardAspectRatio(context),
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
                    leading: const Icon(Icons.emoji_events, color: Colors.amber),
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

  Widget _buildProgressCard(String emoji, String label, String value, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
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
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.blue,
            child: Text(
              user?.username?.substring(0, 1).toUpperCase() ?? 'U',
              style: const TextStyle(fontSize: 40, color: Colors.white),
            ),
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
              Navigator.pushNamed(context, '/profile-edit');
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
            onTap: () {
              // Show language picker
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
            // --- SỬA LOGIC ĐĂNG XUẤT TẠI ĐÂY ---
            onPressed: () async {
              await Provider.of<AuthProvider>(context, listen: false).logout();
              // Đã xóa phần Navigator chuyển trang thừa
            },
            // ------------------------------------
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

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}