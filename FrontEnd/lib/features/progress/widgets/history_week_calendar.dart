import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../../streaks/models/user_streak.dart';

class HistoryWeekCalendar extends StatelessWidget {
  const HistoryWeekCalendar({super.key, required this.streak});

  final UserStreak streak;

  static const _weekdays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day - (now.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    final format = DateFormat('dd/MM/yyyy');
    final activityDates = streak.activityDates;

    return Card(
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: AppSpacing.sm,
              children: [
                const Text(
                  'Lịch học tuần này',
                  style: TextStyle(
                    fontSize: AppTypography.body,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${format.format(monday)} - ${format.format(sunday)}',
                  style: TextStyle(
                    fontSize: AppTypography.caption,
                    color: context.colors.textSecondary,
                  ),
                ),
              ],
            ),
            AppGap.lg,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (index) {
                final date =
                    DateTime(monday.year, monday.month, monday.day + index);
                final hasActivity = activityDates.any((d) =>
                    d.year == date.year &&
                    d.month == date.month &&
                    d.day == date.day);
                final isToday = date.year == now.year &&
                    date.month == now.month &&
                    date.day == now.day;
                return Flexible(
                  child: _DayCell(
                    weekday: _weekdays[index],
                    day: date.day,
                    hasActivity: hasActivity,
                    isToday: isToday,
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.weekday,
    required this.day,
    required this.hasActivity,
    required this.isToday,
  });

  final String weekday;
  final int day;
  final bool hasActivity;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          weekday,
          style: TextStyle(
            fontSize: AppTypography.caption,
            color: context.colors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 40),
          child: AspectRatio(
            aspectRatio: 1,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: hasActivity
                    ? AppColors.successStrong
                    : isToday
                        ? AppColors.primary.withValues(alpha: 0.2)
                        : context.colors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
                border: isToday
                    ? Border.all(color: context.colors.primary, width: 2)
                    : null,
              ),
              child: Center(
                child: hasActivity
                    ? const Icon(Icons.check, color: Colors.white, size: 18)
                    : FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '$day',
                          style: TextStyle(
                            fontSize: AppTypography.caption,
                            fontWeight:
                                isToday ? FontWeight.bold : FontWeight.normal,
                            color: isToday
                                ? context.colors.primary
                                : context.colors.textSecondary,
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
