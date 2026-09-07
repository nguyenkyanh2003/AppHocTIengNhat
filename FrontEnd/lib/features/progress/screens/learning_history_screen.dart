import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/progress_provider.dart';
import '../../streaks/providers/streak_provider.dart';
import '../../streaks/models/user_streak.dart';

class LearningHistoryScreen extends StatefulWidget {
  const LearningHistoryScreen({Key? key}) : super(key: key);

  @override
  State<LearningHistoryScreen> createState() => _LearningHistoryScreenState();
}

class _LearningHistoryScreenState extends State<LearningHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'all';
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  final DateFormat _timeFormat = DateFormat('HH:mm');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final streakProvider = Provider.of<StreakProvider>(context, listen: false);
    final progressProvider =
        Provider.of<ProgressProvider>(context, listen: false);

    await Future.wait([
      streakProvider.loadStreak(),
      streakProvider.loadXPHistory(),
      progressProvider.loadDashboardData(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử học tập'),
        backgroundColor: Colors.blue,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Tổng quan'),
            Tab(text: 'Hoạt động'),
            Tab(text: 'Thống kê'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildActivityTab(),
          _buildStatisticsTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return Consumer2<StreakProvider, ProgressProvider>(
      builder: (context, streakProvider, progressProvider, _) {
        final streak = streakProvider.currentStreak;

        return RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Streak Card
                _buildStreakSummaryCard(streak),
                const SizedBox(height: 16),

                // Learning Progress Cards
                _buildLearningProgressCards(progressProvider),
                const SizedBox(height: 16),

                // Weekly Calendar
                _buildWeeklyCalendar(streak),
                const SizedBox(height: 16),

                // Recent Achievements
                _buildRecentAchievements(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStreakSummaryCard(UserStreak? streak) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStreakStatItem(
                  icon: Icons.local_fire_department,
                  value: '${streak?.currentStreak ?? 0}',
                  label: 'Ngày liên tiếp',
                  iconColor: Colors.orange,
                ),
                Container(
                  width: 1,
                  height: 60,
                  color: Colors.white24,
                ),
                _buildStreakStatItem(
                  icon: Icons.emoji_events,
                  value: '${streak?.longestStreak ?? 0}',
                  label: 'Kỷ lục',
                  iconColor: Colors.amber,
                ),
                Container(
                  width: 1,
                  height: 60,
                  color: Colors.white24,
                ),
                _buildStreakStatItem(
                  icon: Icons.star,
                  value: '${streak?.totalXP ?? 0}',
                  label: 'Tổng XP',
                  iconColor: Colors.yellow,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Level Progress
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Level ${streak?.level ?? 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${streak?.xpToNextLevel ?? 100} XP đến level tiếp theo',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: streak?.xpProgress ?? 0,
                    minHeight: 8,
                    backgroundColor: Colors.white24,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color iconColor,
  }) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildLearningProgressCards(ProgressProvider progressProvider) {
    final stats = progressProvider.stats;

    return Row(
      children: [
        Expanded(
          child: _buildProgressCard(
            icon: Icons.book,
            title: 'Từ vựng',
            value: '${stats?.vocabularyLearned ?? 0}',
            subtitle: 'đã học',
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildProgressCard(
            icon: Icons.draw_outlined,
            title: 'Kanji',
            value: '${stats?.kanjiLearned ?? 0}',
            subtitle: 'đã học',
            color: Colors.red,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildProgressCard(
            icon: Icons.quiz,
            title: 'Bài tập',
            value: '${stats?.exercisesCompleted ?? 0}',
            subtitle: 'hoàn thành',
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyCalendar(UserStreak? streak) {
    final now = DateTime.now();
    final weekDays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    final activityDates = streak?.activityDates ?? [];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Lịch học tuần này',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _getWeekRange(),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (index) {
                final date =
                    now.subtract(Duration(days: now.weekday - 1 - index));
                final hasActivity = activityDates.any((d) =>
                    d.year == date.year &&
                    d.month == date.month &&
                    d.day == date.day);
                final isToday = date.day == now.day &&
                    date.month == now.month &&
                    date.year == now.year;

                return Column(
                  children: [
                    Text(
                      weekDays[index],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: hasActivity
                            ? Colors.green
                            : (isToday
                                ? Colors.blue.withValues(alpha: 0.2)
                                : Colors.grey[200]),
                        borderRadius: BorderRadius.circular(8),
                        border: isToday
                            ? Border.all(color: Colors.blue, width: 2)
                            : null,
                      ),
                      child: Center(
                        child: hasActivity
                            ? const Icon(Icons.check,
                                color: Colors.white, size: 20)
                            : Text(
                                '${date.day}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isToday
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color:
                                      isToday ? Colors.blue : Colors.grey[700],
                                ),
                              ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  String _getWeekRange() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return '${_dateFormat.format(startOfWeek)} - ${_dateFormat.format(endOfWeek)}';
  }

  Widget _buildRecentAchievements() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Thành tích gần đây',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to achievements
                  },
                  child: const Text('Xem tất cả'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildAchievementItem(
              icon: Icons.local_fire_department,
              title: 'Chuỗi 7 ngày',
              description: 'Duy trì streak 7 ngày liên tiếp',
              xp: 100,
              color: Colors.orange,
            ),
            const SizedBox(height: 8),
            _buildAchievementItem(
              icon: Icons.school,
              title: 'Học sinh chăm chỉ',
              description: 'Hoàn thành 10 bài học',
              xp: 200,
              color: Colors.blue,
            ),
            const SizedBox(height: 8),
            _buildAchievementItem(
              icon: Icons.auto_awesome,
              title: 'Bậc thầy từ vựng',
              description: 'Học thuộc 100 từ vựng',
              xp: 150,
              color: Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementItem({
    required IconData icon,
    required String title,
    required String description,
    required int xp,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text(
                  '+$xp XP',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTab() {
    return Consumer<StreakProvider>(
      builder: (context, streakProvider, _) {
        final xpHistory = streakProvider.xpHistory;

        return RefreshIndicator(
          onRefresh: _loadData,
          child: Column(
            children: [
              // Filter Chips
              Container(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('all', 'Tất cả'),
                      const SizedBox(width: 8),
                      _buildFilterChip('lesson', 'Bài học'),
                      const SizedBox(width: 8),
                      _buildFilterChip('exercise', 'Bài tập'),
                      const SizedBox(width: 8),
                      _buildFilterChip('vocabulary', 'Từ vựng'),
                      const SizedBox(width: 8),
                      _buildFilterChip('kanji', 'Kanji'),
                    ],
                  ),
                ),
              ),

              // Activity List
              Expanded(
                child: xpHistory.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Chưa có hoạt động nào',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Bắt đầu học để ghi lại hoạt động!',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: xpHistory.length,
                        itemBuilder: (context, index) {
                          final item = xpHistory[index];
                          return _buildActivityItem(item);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      selectedColor: Colors.blue.withValues(alpha: 0.2),
      checkmarkColor: Colors.blue,
      labelStyle: TextStyle(
        color: isSelected ? Colors.blue : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildActivityItem(XPHistory item) {
    IconData icon;
    Color color;

    switch (item.reason.toLowerCase()) {
      case 'lesson':
      case 'bài học':
        icon = Icons.menu_book;
        color = Colors.blue;
        break;
      case 'exercise':
      case 'bài tập':
        icon = Icons.quiz;
        color = Colors.green;
        break;
      case 'vocabulary':
      case 'từ vựng':
        icon = Icons.spellcheck;
        color = Colors.orange;
        break;
      case 'kanji':
        icon = Icons.draw_outlined;
        color = Colors.red;
        break;
      case 'streak':
        icon = Icons.local_fire_department;
        color = Colors.deepOrange;
        break;
      default:
        icon = Icons.star;
        color = Colors.purple;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.reason,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_dateFormat.format(item.earnedAt)} lúc ${_timeFormat.format(item.earnedAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add, color: Colors.amber, size: 14),
                  const SizedBox(width: 2),
                  Text(
                    '${item.amount} XP',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsTab() {
    return Consumer<ProgressProvider>(
      builder: (context, progressProvider, _) {
        final timeline = progressProvider.timeline;
        final stats = progressProvider.stats;

        return RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Period Selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildPeriodButton('week', 'Tuần'),
                    const SizedBox(width: 8),
                    _buildPeriodButton('month', 'Tháng'),
                    const SizedBox(width: 8),
                    _buildPeriodButton('year', 'Năm'),
                  ],
                ),

                const SizedBox(height: 24),

                // Study Time Card
                _buildStudyTimeCard(stats),

                const SizedBox(height: 16),

                // Daily Activity Chart
                _buildDailyActivityChart(timeline),

                const SizedBox(height: 16),

                // Breakdown by Category
                _buildCategoryBreakdown(progressProvider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPeriodButton(String period, String label) {
    final progressProvider = Provider.of<ProgressProvider>(context);
    final isSelected = progressProvider.selectedPeriod == period;

    return ElevatedButton(
      onPressed: () {
        progressProvider.changePeriod(period);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue : Colors.grey[300],
        foregroundColor: isSelected ? Colors.white : Colors.black87,
        elevation: isSelected ? 2 : 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Text(label),
    );
  }

  Widget _buildStudyTimeCard(stats) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thời gian học tập',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTimeStatItem(
                  label: 'Hôm nay',
                  value: '45 phút',
                  icon: Icons.today,
                  color: Colors.blue,
                ),
                _buildTimeStatItem(
                  label: 'Tuần này',
                  value: '5.2 giờ',
                  icon: Icons.calendar_view_week,
                  color: Colors.green,
                ),
                _buildTimeStatItem(
                  label: 'Tổng cộng',
                  value: stats?.formattedStudyTime ?? '0 phút',
                  icon: Icons.access_time,
                  color: Colors.purple,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeStatItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildDailyActivityChart(List timeline) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hoạt động theo ngày',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 150,
              child: timeline.isEmpty
                  ? Center(
                      child: Text(
                        'Chưa có dữ liệu',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(7, (index) {
                        final height = (index + 1) * 18.0; // Placeholder height
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              width: 30,
                              height: height,
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'][index],
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBreakdown(ProgressProvider progressProvider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Phân bố học tập',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildBreakdownItem('Từ vựng', 40, Colors.blue),
            const SizedBox(height: 12),
            _buildBreakdownItem('Kanji', 25, Colors.red),
            const SizedBox(height: 12),
            _buildBreakdownItem('Ngữ pháp', 20, Colors.green),
            const SizedBox(height: 12),
            _buildBreakdownItem('Bài tập', 15, Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownItem(String label, int percentage, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            Text(
              '$percentage%',
              style: TextStyle(
                fontSize: 14,
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
            minHeight: 6,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
