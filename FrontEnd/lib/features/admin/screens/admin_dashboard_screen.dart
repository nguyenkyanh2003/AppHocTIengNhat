import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadDashboardStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔐 Admin Dashboard'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<AdminProvider>().loadDashboardStats();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đang làm mới dữ liệu...')),
              );
            },
          ),
        ],
      ),
      body: Consumer<AdminProvider>(
        builder: (context, adminProvider, child) {
          if (adminProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final stats = adminProvider.dashboardStats;

          return SingleChildScrollView(
            child: Column(
              children: [
                // Stats Overview
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade700, Colors.blue.shade500],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tổng Quan Hệ Thống',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Cập nhật: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              '👥',
                              '${stats['totalUsers'] ?? 15234}',
                              'Users',
                              Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              '📚',
                              '${stats['totalContent'] ?? 2450}',
                              'Content',
                              Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              '📝',
                              '${stats['pendingReports'] ?? 342}',
                              'Reports',
                              Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              '🔥',
                              '${stats['uptime'] ?? '89.5%'}',
                              'Uptime',
                              Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Quick Actions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quản Lý Nhanh',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.3,
                        children: [
                          _buildActionCard(
                            context,
                            '👥 Users',
                            'Quản lý người dùng',
                            Colors.blue,
                            Icons.people,
                            () => Navigator.pushNamed(context, '/admin/users'),
                          ),
                          _buildActionCard(
                            context,
                            '📚 Content',
                            'Quản lý nội dung',
                            Colors.green,
                            Icons.book,
                            () =>
                                Navigator.pushNamed(context, '/admin/content'),
                          ),
                          _buildActionCard(
                            context,
                            '📝 Reports',
                            'Xử lý báo cáo',
                            Colors.orange,
                            Icons.report,
                            () =>
                                Navigator.pushNamed(context, '/admin/reports'),
                          ),
                          _buildActionCard(
                            context,
                            '🏆 Achievements',
                            'Quản lý thành tích',
                            Colors.purple,
                            Icons.emoji_events,
                            () => Navigator.pushNamed(
                                context, '/admin/achievements'),
                          ),
                          _buildActionCard(
                            context,
                            '💳 Transactions',
                            'Quản lý giao dịch',
                            Colors.teal,
                            Icons.payment,
                            () => Navigator.pushNamed(
                                context, '/admin/transactions'),
                          ),
                          _buildActionCard(
                            context,
                            '📊 Analytics',
                            'Thống kê hệ thống',
                            Colors.red,
                            Icons.analytics,
                            () => Navigator.pushNamed(
                                context, '/admin/analytics'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Recent Activities
                      const Text(
                        'Hoạt Động Gần Đây',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildActivityItem(
                        '👤 User mới đăng ký',
                        'nguyenvana@example.com',
                        '2 phút trước',
                        Colors.blue,
                      ),
                      _buildActivityItem(
                        '📝 Report mới',
                        'Bug trong bài học N5',
                        '15 phút trước',
                        Colors.orange,
                      ),
                      _buildActivityItem(
                        '💳 Thanh toán thành công',
                        'Premium - 199,000đ',
                        '1 giờ trước',
                        Colors.green,
                      ),
                      _buildActivityItem(
                        '🏆 Achievement mới được tạo',
                        'Học 100 từ vựng liên tiếp',
                        '3 giờ trước',
                        Colors.purple,
                      ),
                      _buildActivityItem(
                        '⚠️ Content được báo cáo',
                        'Từ vựng N4 - ID: 12345',
                        '5 giờ trước',
                        Colors.red,
                      ),

                      const SizedBox(height: 32),

                      // System Status
                      const Text(
                        'Trạng Thái Hệ Thống',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSystemStatus(
                          'Database', 'Hoạt động bình thường', true),
                      _buildSystemStatus(
                          'API Server', 'Hoạt động bình thường', true),
                      _buildSystemStatus('Storage', '85% sử dụng', true),
                      _buildSystemStatus('CDN', 'Hoạt động bình thường', true),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            icon,
            style: const TextStyle(fontSize: 28),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color.withValues(alpha: 0.9),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    String subtitle,
    Color color,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityItem(
    String title,
    String subtitle,
    String time,
    Color color,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.2),
          child: Icon(Icons.notification_important, color: color, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: Text(
          time,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildSystemStatus(String name, String status, bool isHealthy) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          isHealthy ? Icons.check_circle : Icons.error,
          color: isHealthy ? Colors.green : Colors.red,
        ),
        title: Text(name),
        subtitle: Text(status),
        trailing: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isHealthy ? Colors.green : Colors.red,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
