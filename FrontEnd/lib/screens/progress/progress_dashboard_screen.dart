import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../providers/progress_provider.dart';
import '../../core/responsive_helper.dart';

class ProgressDashboardScreen extends StatefulWidget {
  const ProgressDashboardScreen({Key? key}) : super(key: key);

  @override
  State<ProgressDashboardScreen> createState() =>
      _ProgressDashboardScreenState();
}

class _ProgressDashboardScreenState extends State<ProgressDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProgressProvider>(context, listen: false).loadDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tiến độ học tập'),
        elevation: 0,
      ),
      body: Consumer<ProgressProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.stats == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: provider.loadDashboardData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ResponsiveCenter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveHelper.getHorizontalPadding(context),
                    vertical: ResponsiveHelper.getVerticalPadding(context),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatsOverview(provider),
                      const SizedBox(height: 24),
                      _buildTimelineChart(provider),
                      const SizedBox(height: 24),
                      _buildBreakdownCharts(provider),
                      const SizedBox(height: 24),
                      _buildHeatmapCalendar(provider),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsOverview(ProgressProvider provider) {
    final stats = provider.stats;
    if (stats == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Thống kê tổng quan',
          style: TextStyle(
            fontSize: ResponsiveHelper.getHeadingFontSize(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: ResponsiveHelper.getGridColumns(context),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: ResponsiveHelper.getCardAspectRatio(context),
          children: [
            _buildStatCard(
              '📚',
              'Từ vựng',
              '${stats.vocabularyLearned}',
              Colors.blue,
            ),
            _buildStatCard(
              '🔤',
              'Kanji',
              '${stats.kanjiLearned}',
              Colors.purple,
            ),
            _buildStatCard(
              '✏️',
              'Bài tập',
              '${stats.exercisesCompleted}',
              Colors.green,
            ),
            _buildStatCard(
              '📖',
              'Bài học',
              '${stats.lessonsCompleted}',
              Colors.orange,
            ),
            _buildStatCard(
              '⏱️',
              'Thời gian',
              stats.formattedStudyTime,
              Colors.red,
            ),
            _buildStatCard(
              '🔥',
              'Streak',
              '${stats.currentStreak} ngày',
              Colors.deepOrange,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String emoji, String label, String value, Color color) {
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
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 3),
            Flexible(
              child: FittedBox(
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
            ),
            const SizedBox(height: 2),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineChart(ProgressProvider provider) {
    final timeline = provider.timeline;
    if (timeline.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Biểu đồ học tập',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            _buildPeriodSelector(provider),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= timeline.length) {
                            return const SizedBox.shrink();
                          }
                          final date = timeline[value.toInt()].dateTime;
                          return Text(
                            DateFormat('dd/MM').format(date),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: timeline
                          .asMap()
                          .entries
                          .map((e) => FlSpot(
                                e.key.toDouble(),
                                e.value.exercises.toDouble(),
                              ))
                          .toList(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withOpacity(0.1),
                      ),
                    ),
                    LineChartBarData(
                      spots: timeline
                          .asMap()
                          .entries
                          .map((e) => FlSpot(
                                e.key.toDouble(),
                                e.value.lessons.toDouble(),
                              ))
                          .toList(),
                      isCurved: true,
                      color: Colors.orange,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.orange.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem(Colors.blue, 'Bài tập'),
            const SizedBox(width: 24),
            _buildLegendItem(Colors.orange, 'Bài học'),
          ],
        ),
      ],
    );
  }

  Widget _buildPeriodSelector(ProgressProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButton<String>(
        value: provider.selectedPeriod,
        underline: const SizedBox.shrink(),
        items: const [
          DropdownMenuItem(value: 'week', child: Text('Tuần')),
          DropdownMenuItem(value: 'month', child: Text('Tháng')),
          DropdownMenuItem(value: 'year', child: Text('Năm')),
        ],
        onChanged: (value) {
          if (value != null) {
            provider.changePeriod(value);
          }
        },
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildBreakdownCharts(ProgressProvider provider) {
    final breakdown = provider.breakdown;
    final isLoading = provider.isLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Phân tích chi tiết',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        // Show loading state
        if (isLoading && breakdown == null) ...[
          const Card(
            elevation: 2,
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
        ]
        
        // Show empty state when no data
        else if (breakdown == null || 
                 (breakdown.lessonsByLevel.isEmpty && breakdown.exercisesByType.isEmpty)) ...[
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.analytics_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có dữ liệu phân tích',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bắt đầu học bài và làm bài tập để xem phân tích chi tiết',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ),
        ]
        
        // Show breakdown data
        else ...[
        if (breakdown.lessonsByLevel.isNotEmpty) ...[
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bài học theo cấp độ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...breakdown.lessonsByLevel.map((level) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(level.level),
                              Text(
                                '${level.completed}/${level.total}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: level.completionRate / 100,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getLevelColor(level.level),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (breakdown.exercisesByType.isNotEmpty)
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bài tập theo loại',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...breakdown.exercisesByType.map((type) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: _getTypeColor(type.type),
                        child: Text(
                          type.count.toString(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(type.type),
                      subtitle: Text(
                        'Điểm TB: ${type.averageScore.toStringAsFixed(1)}',
                      ),
                      trailing: Text(
                        '${type.passRate.toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: type.passRate >= 70
                              ? Colors.green
                              : Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ], // Close the else block for breakdown data
      ],
    );
  }

  Widget _buildHeatmapCalendar(ProgressProvider provider) {
    final heatmap = provider.heatmap;
    final isLoading = provider.isLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Lịch học tập',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        // Show loading state
        if (isLoading && heatmap.isEmpty) ...[
          const Card(
            elevation: 2,
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
        ]
        
        // Show empty state
        else if (heatmap.isEmpty) ...[
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.calendar_month_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có lịch sử học tập',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Học tập đều đặn để xây dựng lịch sử của bạn',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ),
        ]
        
        // Show heatmap data
        else ...[
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildHeatmapGrid(heatmap),
                  const SizedBox(height: 12),
                  _buildHeatmapLegend(),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildHeatmapGrid(List heatmap) {
    // Group by week
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);
    final daysInYear = DateTime(now.year, 12, 31).difference(startOfYear).inDays + 1;
    
    // Create map for quick lookup
    final heatmapMap = {for (var h in heatmap) h.date: h};

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: (daysInYear / 7).ceil(),
        itemBuilder: (context, weekIndex) {
          return Column(
            children: List.generate(7, (dayIndex) {
              final dayOffset = weekIndex * 7 + dayIndex;
              if (dayOffset >= daysInYear) {
                return const SizedBox(width: 12, height: 12);
              }
              
              final date = startOfYear.add(Duration(days: dayOffset));
              final dateStr = DateFormat('yyyy-MM-dd').format(date);
              final data = heatmapMap[dateStr];
              final intensity = data?.intensity ?? 0;

              return Padding(
                padding: const EdgeInsets.all(1),
                child: Tooltip(
                  message: data != null
                      ? '${DateFormat('dd/MM/yyyy').format(date)}\n${data.count} hoạt động'
                      : DateFormat('dd/MM/yyyy').format(date),
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getHeatmapColor(intensity),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  Widget _buildHeatmapLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Ít', style: TextStyle(fontSize: 12)),
        const SizedBox(width: 8),
        ...List.generate(5, (index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: _getHeatmapColor(index),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
        const SizedBox(width: 8),
        const Text('Nhiều', style: TextStyle(fontSize: 12)),
      ],
    );
  }

  Color _getHeatmapColor(int intensity) {
    switch (intensity) {
      case 0:
        return Colors.grey[200]!;
      case 1:
        return Colors.green[200]!;
      case 2:
        return Colors.green[400]!;
      case 3:
        return Colors.green[600]!;
      case 4:
        return Colors.green[800]!;
      default:
        return Colors.grey[200]!;
    }
  }

  Color _getLevelColor(String level) {
    switch (level) {
      case 'N1':
        return Colors.red;
      case 'N2':
        return Colors.orange;
      case 'N3':
        return Colors.yellow[700]!;
      case 'N4':
        return Colors.green;
      case 'N5':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'Từ vựng':
        return Colors.blue;
      case 'Ngữ pháp':
        return Colors.purple;
      case 'Kanji':
        return Colors.orange;
      case 'Tổng hợp':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
