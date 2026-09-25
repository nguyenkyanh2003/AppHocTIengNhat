import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/content_pane.dart';
import '../models/calendar_day.dart';
import '../models/day_key.dart';
import '../models/user_streak.dart';
import '../providers/streak_calendar_provider.dart';
import '../providers/streak_provider.dart';
import '../services/streak_service.dart';
import '../widgets/calendar_month_grid.dart';

/// Lịch học theo tháng (spec §5.1): đã học, băng đã che, băng dự kiến, nghỉ,
/// ngày cũ chưa xác minh và hôm nay chưa học — tương lai không tô gì.
class StreakCalendarScreen extends StatelessWidget {
  const StreakCalendarScreen({super.key, this.service, this.clock});

  /// Mở ra cho test; mã chạy thật để trống.
  final StreakService? service;
  final DateTime Function()? clock;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => StreakCalendarProvider(service: service, clock: clock),
      child: const _CalendarView(),
    );
  }
}

class _CalendarView extends StatefulWidget {
  const _CalendarView();

  @override
  State<_CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<_CalendarView> {
  @override
  void initState() {
    super.initState();
    // Tải sau frame đầu để provider không báo listener giữa lúc cây đang dựng.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<StreakCalendarProvider>().load();
      final streak = context.read<StreakProvider>();
      if (streak.currentStreak == null) streak.loadStreak();
    });
  }

  void _showDay(String dayKey, CalendarDayKind kind, StreakDay? record) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('${formatDayKey(dayKey)}: ${describeCalendarDay(kind, record)}')),
      );
  }

  @override
  Widget build(BuildContext context) {
    final calendar = context.watch<StreakCalendarProvider>();
    final streak = context.watch<StreakProvider>().currentStreak;
    final earliest = _earliestDay(streak);
    final theme = Theme.of(context);

    return AppScaffold(
      title: 'Lịch học',
      body: SingleChildScrollView(
        child: ContentPane(
          maxWidth: AppContentWidth.form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Tháng trước',
                    icon: const Icon(Icons.chevron_left),
                    onPressed: calendar.canGoPrevious(earliest) ? calendar.showPrevious : null,
                  ),
                  Expanded(
                    child: Text(
                      'Tháng ${calendar.month.month}/${calendar.month.year}',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Tháng sau',
                    icon: const Icon(Icons.chevron_right),
                    onPressed: calendar.canGoNext ? calendar.showNext : null,
                  ),
                ],
              ),
              AppGap.sm,
              AsyncView<Map<String, StreakDay>>(
                state: calendar.days,
                onRetry: calendar.load,
                builder: (context, days) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CalendarMonthGrid(
                      year: calendar.month.year,
                      month: calendar.month.month,
                      todayKey: calendar.todayKey,
                      days: days,
                      pendingFrozenDays: {...?streak?.pendingFrozenDays},
                      trackingStartedDay: streak?.trackingStartedDay,
                      onTapDay: _showDay,
                    ),
                    AppGap.md,
                    Text(_monthSummary(days), style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
              AppGap.lg,
              const CalendarLegend(),
              AppGap.md,
              Text(
                'Chạm vào một ngày để xem chi tiết. Ngày chưa tới không bao giờ tính là nghỉ.',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Mốc lùi xa nhất: ngày sớm nhất trong lịch hoặc ngày bắt đầu theo dõi.
  String? _earliestDay(UserStreak? streak) {
    final candidates = [streak?.firstDay, streak?.trackingStartedDay].whereType<String>().toList()
      ..sort();
    return candidates.isEmpty ? null : candidates.first;
  }

  String _monthSummary(Map<String, StreakDay> days) {
    final studied = days.values.where((day) => day.status == 'studied').length;
    final frozen = days.values.where((day) => day.status == 'frozen').length;
    return 'Tháng này: $studied ngày học · $frozen ngày được băng che.';
  }
}
