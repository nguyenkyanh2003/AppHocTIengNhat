import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Map<String, dynamic>> _menuItems = [
    {
      'icon': Icons.book,
      'title': 'Bài học',
      'subtitle': 'Học từ vựng và ngữ pháp',
      'route': '/lessons',
    },
    {
      'icon': Icons.style,
      'title': 'Kanji',
      'subtitle': 'Học chữ Hán',
      'route': '/kanji',
    },
    {
      'icon': Icons.quiz,
      'title': 'Luyện tập',
      'subtitle': 'Bài tập và kiểm tra',
      'route': '/exercises',
    },
    {
      'icon': Icons.school,
      'title': 'JLPT',
      'subtitle': 'Luyện thi năng lực',
      'route': '/jlpt',
    },
    {
      'icon': Icons.article,
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
      'icon': Icons.chat,
      'title': 'Trò chuyện',
      'subtitle': 'Chat với nhóm',
      'route': '/group-chat',
    },
    {
      'icon': Icons.book_outlined,
      'title': 'Sổ tay',
      'subtitle': 'Ghi chú của bạn',
      'route': '/notebook',
    },
  ];

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
            accountName: Text(user?.username ?? 'Người dùng'),
            accountEmail: Text(user?.email ?? ''),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                user?.username?.substring(0, 1).toUpperCase() ?? 'U',
                style: const TextStyle(fontSize: 40.0),
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
          // Welcome banner
          Card(
            elevation: 4,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade400, Colors.blue.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chào mừng trở lại!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Hãy tiếp tục hành trình học tiếng Nhật của bạn',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Quick stats
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Chuỗi học',
                  '0 ngày',
                  Icons.local_fire_department,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Điểm',
                  '0 XP',
                  Icons.star,
                  Colors.amber,
                ),
              ),
            ],
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
                  Navigator.pushNamed(context, item['route']);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.blue),
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
    );
  }

  Widget _buildProgressContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.show_chart, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Tiến độ học tập',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text('Tính năng đang phát triển'),
        ],
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