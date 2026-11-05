import 'dashboard.dart';

/// Tổng của các ngày trong một kỳ.
class TimelineSummary {
  const TimelineSummary({
    required this.xp,
    required this.exercises,
    required this.lessons,
    required this.seconds,
  });

  factory TimelineSummary.of(Iterable<TimelineData> days) {
    var xp = 0;
    var exercises = 0;
    var lessons = 0;
    var seconds = 0;
    for (final day in days) {
      xp += day.xp;
      exercises += day.exercises;
      lessons += day.lessons;
      seconds += day.time;
    }
    return TimelineSummary(
        xp: xp, exercises: exercises, lessons: lessons, seconds: seconds);
  }

  final int xp;
  final int exercises;
  final int lessons;
  final int seconds;
}

/// Một cột của biểu đồ hoạt động. [label] rỗng thì không ghi nhãn dưới cột.
class ChartBar {
  const ChartBar({required this.label, required this.xp});

  final String label;
  final int xp;
}

const _weekdays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

String _key(DateTime day) =>
    '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

/// Dựng cột biểu đồ từ dữ liệu theo ngày của server.
///
/// Server chỉ trả những ngày có hoạt động, nên ngày trống phải tự điền vào, nếu
/// không biểu đồ sẽ giấu đi những ngày nghỉ. Số ngày khớp với kỳ của server
/// (7, 30 và 365 ngày tính cả hôm nay); kỳ năm gộp theo tháng để cột đủ rộng.
List<ChartBar> chartBars(List<TimelineData> days,
    {required String period, required DateTime now}) {
  final today = DateTime(now.year, now.month, now.day);
  final xpByDay = <String, int>{for (final day in days) day.date: day.xp};

  if (period == 'year') {
    final xpByMonth = <String, int>{};
    for (final day in days) {
      if (day.date.length < 7) continue;
      final month = day.date.substring(0, 7);
      xpByMonth[month] = (xpByMonth[month] ?? 0) + day.xp;
    }
    return List.generate(12, (index) {
      final month = DateTime(today.year, today.month - 11 + index);
      return ChartBar(
        label: 'T${month.month}',
        xp: xpByMonth[_key(month).substring(0, 7)] ?? 0,
      );
    });
  }

  final count = period == 'month' ? 30 : 7;
  return List.generate(count, (index) {
    final day =
        DateTime(today.year, today.month, today.day - (count - 1 - index));
    final label = switch (period) {
      'month' => (count - 1 - index) % 7 == 0 ? '${day.day}/${day.month}' : '',
      _ => _weekdays[day.weekday - 1],
    };
    return ChartBar(label: label, xp: xpByDay[_key(day)] ?? 0);
  });
}
