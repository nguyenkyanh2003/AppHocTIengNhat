import 'day_key.dart';
import 'user_streak.dart';

/// Loại của một ô trên lịch học (spec §5.1).
enum CalendarDayKind {
  /// Có hoạt động học đã xác minh.
  studied,

  /// Nghỉ nhưng đã được băng che — đã ghi.
  frozen,

  /// Băng **sẽ** che khi người học quay lại — dự kiến, chưa ghi.
  pendingFrozen,

  /// Ngày dựng lại từ dữ liệu cũ, không chứng minh được là có học.
  legacy,

  /// Hôm nay, chưa học. Không phải ngày nghỉ: hôm nay chưa kết thúc.
  today,

  /// Ngày đã qua, trong thời gian theo dõi, không học và không được che.
  missed,

  /// Chưa tới. Không bao giờ tô là bỏ học.
  future,

  /// Trước khi bắt đầu theo dõi: không có dữ liệu để nói gì.
  untracked,
}

/// Phân loại một ngày. So khoá `YYYY-MM-DD` theo thứ tự chữ là so theo ngày.
CalendarDayKind classifyCalendarDay({
  required String dayKey,
  required String todayKey,
  StreakDay? record,
  Set<String> pendingFrozenDays = const {},
  String? trackingStartedDay,
}) {
  if (dayKey.compareTo(todayKey) > 0) return CalendarDayKind.future;
  if (record != null) {
    switch (record.status) {
      case 'studied':
        return CalendarDayKind.studied;
      case 'frozen':
        return CalendarDayKind.frozen;
      case 'legacy':
        return CalendarDayKind.legacy;
    }
  }
  if (pendingFrozenDays.contains(dayKey)) return CalendarDayKind.pendingFrozen;
  if (dayKey == todayKey) return CalendarDayKind.today;
  if (trackingStartedDay == null || dayKey.compareTo(trackingStartedDay) < 0) {
    return CalendarDayKind.untracked;
  }
  return CalendarDayKind.missed;
}

/// Các ô của một tháng, bắt đầu từ thứ Hai; `null` là ô trống trước ngày 1.
List<String?> monthCells(int year, int month) {
  final first = DateTime.utc(year, month);
  final daysInMonth = DateTime.utc(year, month + 1, 0).day;
  final leading = first.weekday - DateTime.monday;
  return [
    for (var i = 0; i < leading; i++) null,
    for (var day = 1; day <= daysInMonth; day++) dayKeyOf(DateTime.utc(year, month, day)),
  ];
}

/// Câu mô tả một ngày khi người dùng chạm vào ô.
String describeCalendarDay(CalendarDayKind kind, StreakDay? record) => switch (kind) {
      CalendarDayKind.studied =>
        'Đã học · ${record?.directXp ?? 0} XP${(record?.reviewCount ?? 0) > 0 ? ' · ${record!.reviewCount} lượt ôn' : ''}',
      CalendarDayKind.frozen => 'Nghỉ, được băng bảo vệ chuỗi.',
      CalendarDayKind.pendingFrozen => 'Nghỉ. Băng sẽ che ngày này khi bạn học lại (dự kiến).',
      CalendarDayKind.legacy => 'Ngày từ dữ liệu cũ, chưa xác minh là có học.',
      CalendarDayKind.today => 'Hôm nay bạn chưa học.',
      CalendarDayKind.missed => 'Nghỉ.',
      CalendarDayKind.future => 'Chưa tới.',
      CalendarDayKind.untracked => 'Trước khi bắt đầu theo dõi chuỗi.',
    };
