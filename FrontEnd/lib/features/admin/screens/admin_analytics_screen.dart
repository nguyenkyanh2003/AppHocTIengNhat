import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/admin_provider.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/content_pane.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  String _selectedPeriod = '7d';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAnalytics());
  }

  Future<void> _loadAnalytics() =>
      context.read<AdminProvider>().loadAnalytics(period: _selectedPeriod);

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Phân tích học tập',
      actions: [
        IconButton(
          onPressed: _loadAnalytics,
          icon: const Icon(Icons.refresh),
          tooltip: 'Tải lại',
        ),
      ],
      body: ContentWidthLimit(
        child: Consumer<AdminProvider>(
          builder: (context, provider, _) {
            final analytics = provider.analytics ?? const <String, dynamic>{};
            if (provider.isLoadingAnalytics && analytics.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (provider.error != null && analytics.isEmpty) {
              return _errorState(provider.error!);
            }
            final labels = _strings(analytics['labels']);
            return RefreshIndicator(
              onRefresh: _loadAnalytics,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _periodSelector(),
                  const SizedBox(height: 20),
                  _metrics(analytics['metrics']),
                  const SizedBox(height: 20),
                  _chart(
                    'Người dùng hoạt động',
                    Icons.people,
                    Colors.blue,
                    labels,
                    _numbers(analytics['daily_active_users']),
                  ),
                  _chart(
                    'Đăng ký mới',
                    Icons.person_add,
                    Colors.green,
                    labels,
                    _numbers(analytics['new_registrations']),
                  ),
                  _chart(
                    'Bài học hoàn thành',
                    Icons.school,
                    Colors.orange,
                    labels,
                    _numbers(analytics['lessons_completed']),
                  ),
                  _chart(
                    'Thời gian học (phút)',
                    Icons.timer,
                    Colors.purple,
                    labels,
                    _numbers(analytics['total_study_time']),
                  ),
                  _levelDistribution(analytics['level_distribution']),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _periodSelector() {
    const periods = {'7d': '7 ngày', '30d': '30 ngày', '90d': '90 ngày'};
    return Wrap(
      spacing: 8,
      children: periods.entries.map((entry) {
        return ChoiceChip(
          label: Text(entry.value),
          selected: _selectedPeriod == entry.key,
          onSelected: (selected) {
            if (!selected) return;
            setState(() => _selectedPeriod = entry.key);
            _loadAnalytics();
          },
        );
      }).toList(),
    );
  }

  Widget _metrics(dynamic rawMetrics) {
    final values = rawMetrics is Map
        ? Map<String, dynamic>.from(rawMetrics)
        : <String, dynamic>{};
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.55,
      children: [
        _metric('Tổng người dùng', values['total_users'], Icons.people,
            Colors.blue),
        _metric(
          'Hoạt động hôm nay',
          values['active_today'],
          Icons.trending_up,
          Colors.green,
        ),
        _metric(
          'Bài học hoàn thành',
          values['lessons_completed'],
          Icons.school,
          Colors.orange,
        ),
        _metric(
          'Tổng phút học',
          values['study_minutes'],
          Icons.timer,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _metric(String label, dynamic value, IconData icon, Color color) =>
      Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color),
              Text(
                '${value ?? 0}',
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Text(label, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      );

  Widget _chart(
    String title,
    IconData icon,
    Color color,
    List<String> labels,
    List<num> values,
  ) {
    final count = values.length < labels.length ? values.length : labels.length;
    final maxValue = values.isEmpty
        ? 1.0
        : values
            .fold<num>(0, (max, value) => value > max ? value : max)
            .toDouble();
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            if (count == 0)
              const SizedBox(
                height: 80,
                child:
                    Center(child: Text('Chưa có dữ liệu trong giai đoạn này.')),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                reverse: true,
                child: SizedBox(
                  width: count * 46.0,
                  height: 155,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(count, (index) {
                      final normalized =
                          maxValue == 0 ? 0.0 : values[index] / maxValue;
                      return SizedBox(
                        width: 46,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text('${values[index].round()}',
                                style: const TextStyle(fontSize: 10)),
                            const SizedBox(height: 4),
                            Container(
                              width: 24,
                              height: 8 + normalized * 95,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.8),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _shortDate(labels[index]),
                              style: const TextStyle(fontSize: 9),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _levelDistribution(dynamic rawDistribution) {
    final distribution = rawDistribution is Map
        ? Map<String, dynamic>.from(rawDistribution)
        : <String, dynamic>{};
    final total = distribution.values.fold<num>(
      0,
      (sum, value) => sum + ((value as num?) ?? 0),
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Phân bố trình độ',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            if (distribution.isEmpty)
              const Text('Chưa có dữ liệu trình độ.')
            else
              ...distribution.entries.map((entry) {
                final count = (entry.value as num?) ?? 0;
                final ratio = total == 0 ? 0.0 : count / total;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      SizedBox(width: 36, child: Text(entry.key)),
                      Expanded(child: LinearProgressIndicator(value: ratio)),
                      const SizedBox(width: 10),
                      Text('${count.round()} (${(ratio * 100).round()}%)'),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _errorState(String message) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
              TextButton(
                  onPressed: _loadAnalytics, child: const Text('Thử lại')),
            ],
          ),
        ),
      );

  List<String> _strings(dynamic value) =>
      value is List ? value.map((item) => item.toString()).toList() : const [];

  List<num> _numbers(dynamic value) => value is List
      ? value
          .map((item) => item is num ? item : num.tryParse('$item') ?? 0)
          .toList()
      : const [];

  String _shortDate(String value) {
    final date = DateTime.tryParse(value);
    return date == null ? value : '${date.day}/${date.month}';
  }
}
