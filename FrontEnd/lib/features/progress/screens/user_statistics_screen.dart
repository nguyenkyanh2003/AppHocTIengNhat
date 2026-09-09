import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/progress_provider.dart';
import '../../streaks/providers/streak_provider.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/content_pane.dart';

class UserStatisticsScreen extends StatefulWidget {
  const UserStatisticsScreen({Key? key}) : super(key: key);

  @override
  State<UserStatisticsScreen> createState() => _UserStatisticsScreenState();
}

class _UserStatisticsScreenState extends State<UserStatisticsScreen> {
  String _selectedPeriod = 'week'; // week, month, year

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final streakProvider = Provider.of<StreakProvider>(context, listen: false);
    final progressProvider =
        Provider.of<ProgressProvider>(context, listen: false);

    await Future.wait([
      streakProvider.loadStreak(),
      progressProvider.loadDashboardData(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Thống Kê Chi Tiết',
      body: ContentWidthLimit(
        child: Consumer2<ProgressProvider, StreakProvider>(
          builder: (context, progressProvider, streakProvider, _) {
            if (progressProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Period selector
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildPeriodButton('week', '1 Tuần'),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildPeriodButton('month', '1 Tháng'),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildPeriodButton('year', '1 Năm'),
                        ),
                      ],
                    ),
                  ),

                  // Key statistics
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Thống Kê Chính',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          children: [
                            _buildStatCard(
                              'Tổng Thời Gian Học',
                              '240h',
                              Icons.timer,
                              Colors.blue,
                            ),
                            _buildStatCard(
                              'Bài Học Hoàn Thành',
                              '45',
                              Icons.menu_book,
                              Colors.green,
                            ),
                            _buildStatCard(
                              'Từ Vựng Học',
                              '1,250',
                              Icons.spellcheck,
                              Colors.orange,
                            ),
                            _buildStatCard(
                              'Kanji Học',
                              '340',
                              Icons.draw_outlined,
                              Colors.red,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Streak info
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Chuỗi Học',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    Column(
                                      children: [
                                        const Icon(
                                          Icons.local_fire_department,
                                          size: 32,
                                          color: Colors.red,
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          'Streak Hiện Tại',
                                          style: TextStyle(
                                              fontSize: 12, color: Colors.grey),
                                        ),
                                        Text(
                                          '${streakProvider.currentStreak?.currentStreak ?? 0}',
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const Text('ngày'),
                                      ],
                                    ),
                                    Column(
                                      children: [
                                        const Icon(
                                          Icons.trending_up,
                                          size: 32,
                                          color: Colors.blue,
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          'Streak Dài Nhất',
                                          style: TextStyle(
                                              fontSize: 12, color: Colors.grey),
                                        ),
                                        Text(
                                          '${streakProvider.currentStreak?.longestStreak ?? 0}',
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const Text('ngày'),
                                      ],
                                    ),
                                    Column(
                                      children: [
                                        const Icon(
                                          Icons.star,
                                          size: 32,
                                          color: Colors.amber,
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          'Tổng XP',
                                          style: TextStyle(
                                              fontSize: 12, color: Colors.grey),
                                        ),
                                        Text(
                                          '${streakProvider.currentStreak?.totalXP ?? 0}',
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const Text('điểm'),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Learning breakdown
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Phân Tích Chi Tiết',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                _buildProgressItem(
                                  'N5 Hoàn Thành',
                                  75,
                                  Colors.green,
                                ),
                                const SizedBox(height: 12),
                                _buildProgressItem(
                                  'N4 Hoàn Thành',
                                  45,
                                  Colors.blue,
                                ),
                                const SizedBox(height: 12),
                                _buildProgressItem(
                                  'N3 Hoàn Thành',
                                  20,
                                  Colors.orange,
                                ),
                                const SizedBox(height: 12),
                                _buildProgressItem(
                                  'Bài Tập Đúng',
                                  68,
                                  Colors.purple,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Export & Share
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Tính năng sắp có...')),
                              );
                            },
                            icon: const Icon(Icons.download),
                            label: const Text('Xuất PDF'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Tính năng sắp có...')),
                              );
                            },
                            icon: const Icon(Icons.share),
                            label: const Text('Chia Sẻ'),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPeriodButton(String period, String label) {
    final isSelected = _selectedPeriod == period;
    return ElevatedButton(
      onPressed: () {
        setState(() => _selectedPeriod = period);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue : Colors.grey[300],
        foregroundColor: isSelected ? Colors.white : Colors.black,
      ),
      child: Text(label),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressItem(String label, int percentage, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              '$percentage%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage / 100,
            minHeight: 8,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
