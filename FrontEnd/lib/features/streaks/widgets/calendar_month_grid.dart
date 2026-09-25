import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../models/calendar_day.dart';
import '../models/user_streak.dart';

/// Cách tô từng loại ngày. Dùng chung cho ô lịch và chú thích.
class CalendarDayStyle {
  const CalendarDayStyle({required this.label, this.fill, this.border, this.foreground});

  final String label;
  final Color? fill;
  final Color? border;
  final Color? foreground;

  static CalendarDayStyle of(CalendarDayKind kind) => switch (kind) {
        CalendarDayKind.studied =>
          const CalendarDayStyle(label: 'Đã học', fill: AppColors.streak, foreground: AppColors.textPrimary),
        CalendarDayKind.frozen =>
          const CalendarDayStyle(label: 'Băng đã che', fill: AppColors.freeze, foreground: AppColors.textPrimary),
        CalendarDayKind.pendingFrozen => CalendarDayStyle(
            label: 'Băng sẽ che (dự kiến)',
            fill: AppColors.freeze.withValues(alpha: 0.15),
            border: AppColors.freeze,
          ),
        CalendarDayKind.legacy => CalendarDayStyle(
            label: 'Dữ liệu cũ, chưa xác minh',
            fill: AppColors.textDisabled.withValues(alpha: 0.25),
          ),
        CalendarDayKind.today => const CalendarDayStyle(label: 'Hôm nay chưa học', border: AppColors.primary),
        CalendarDayKind.missed => CalendarDayStyle(
            label: 'Nghỉ',
            fill: AppColors.error.withValues(alpha: 0.10),
            foreground: AppColors.error,
          ),
        CalendarDayKind.future => const CalendarDayStyle(label: 'Chưa tới', foreground: AppColors.textDisabled),
        CalendarDayKind.untracked => const CalendarDayStyle(label: 'Chưa theo dõi'),
      };
}

/// Lưới một tháng, bắt đầu từ thứ Hai.
class CalendarMonthGrid extends StatelessWidget {
  const CalendarMonthGrid({
    super.key,
    required this.year,
    required this.month,
    required this.todayKey,
    required this.days,
    required this.pendingFrozenDays,
    required this.trackingStartedDay,
    required this.onTapDay,
  });

  final int year;
  final int month;
  final String todayKey;
  final Map<String, StreakDay> days;
  final Set<String> pendingFrozenDays;
  final String? trackingStartedDay;
  final void Function(String dayKey, CalendarDayKind kind, StreakDay? record) onTapDay;

  static const weekdays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cells = monthCells(year, month);

    return Column(
      children: [
        Row(
          children: [
            for (final weekday in weekdays)
              Expanded(
                child: Center(child: Text(weekday, style: theme.textTheme.labelMedium)),
              ),
          ],
        ),
        AppGap.sm,
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.xs,
          crossAxisSpacing: AppSpacing.xs,
          children: [
            for (final dayKey in cells)
              if (dayKey == null) const SizedBox.shrink() else _cell(context, dayKey),
          ],
        ),
      ],
    );
  }

  Widget _cell(BuildContext context, String dayKey) {
    final record = days[dayKey];
    final kind = classifyCalendarDay(
      dayKey: dayKey,
      todayKey: todayKey,
      record: record,
      pendingFrozenDays: pendingFrozenDays,
      trackingStartedDay: trackingStartedDay,
    );
    final style = CalendarDayStyle.of(kind);
    final day = int.parse(dayKey.substring(8));

    return Semantics(
      button: true,
      label: 'Ngày $day tháng $month: ${style.label}',
      excludeSemantics: true,
      child: InkWell(
        key: ValueKey('calendar-$dayKey'),
        borderRadius: AppRadius.smAll,
        onTap: () => onTapDay(dayKey, kind, record),
        child: Container(
          decoration: BoxDecoration(
            color: style.fill,
            borderRadius: AppRadius.smAll,
            border: style.border == null ? null : Border.all(color: style.border!, width: 2),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$day',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: style.foreground,
                      fontWeight: kind == CalendarDayKind.studied ? FontWeight.w700 : null,
                    ),
              ),
              if (kind == CalendarDayKind.frozen || kind == CalendarDayKind.pendingFrozen)
                const Icon(Icons.ac_unit, size: 12, color: AppColors.textPrimary),
              if (kind == CalendarDayKind.legacy)
                Text('?', style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
        ),
      ),
    );
  }
}

/// Chú thích màu của lịch.
class CalendarLegend extends StatelessWidget {
  const CalendarLegend({super.key});

  static const _shown = [
    CalendarDayKind.studied,
    CalendarDayKind.frozen,
    CalendarDayKind.pendingFrozen,
    CalendarDayKind.legacy,
    CalendarDayKind.today,
    CalendarDayKind.missed,
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      children: [
        for (final kind in _shown)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: AppSpacing.lg,
                height: AppSpacing.lg,
                decoration: BoxDecoration(
                  color: CalendarDayStyle.of(kind).fill,
                  borderRadius: AppRadius.smAll,
                  border: CalendarDayStyle.of(kind).border == null
                      ? Border.all(color: AppColors.border)
                      : Border.all(color: CalendarDayStyle.of(kind).border!, width: 2),
                ),
              ),
              AppGap.xs,
              Text(CalendarDayStyle.of(kind).label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
      ],
    );
  }
}
