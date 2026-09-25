import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/day_key.dart';
import '../models/streak_settings.dart';

/// Nhắc học trong ứng dụng khi đang mở (spec §5.3).
///
/// Phạm vi có chủ đích: không có thông báo khi app đóng (cần local
/// notification hoặc Web Push, ngoài nghiệm thu 1B), tối đa một lần mỗi ngày
/// trên mỗi thiết bị, và chỉ nhắc sau khi đã đồng bộ được "hôm nay học chưa"
/// với server.

sealed class ReminderDecision {
  const ReminderDecision();
}

/// Nhắc học đang tắt.
final class ReminderOff extends ReminderDecision {
  const ReminderOff();
}

/// Đã tới giờ và còn trong khung cho phép: kiểm tra rồi nhắc ngay.
final class ReminderShowNow extends ReminderDecision {
  const ReminderShowNow();
}

/// Chưa tới lúc: xét lại sau [delay].
final class ReminderWait extends ReminderDecision {
  const ReminderWait(this.delay);

  final Duration delay;
}

/// Thời điểm (UTC) ứng với giờ `HH:MM` Việt Nam của ngày [wall].
DateTime _instantAt(DateTime wall, String hhmm) {
  final parts = hhmm.split(':');
  return DateTime.utc(wall.year, wall.month, wall.day, int.parse(parts[0]), int.parse(parts[1]))
      .subtract(vietnamOffset);
}

/// Lúc nào nên nhắc.
///
/// - Trước giờ đã chọn: đợi tới đúng giờ.
/// - Mở app sau giờ đã chọn nhưng còn trong khung (tới hết [windowEnd]): nhắc
///   ngay, một lần.
/// - Sau khung, hoặc hôm nay đã xử lý: đợi tới giờ đó **ngày mai** — không
///   nhắc bù cho ngày đã qua.
ReminderDecision decideReminder({
  required DateTime now,
  required bool enabled,
  required String reminderTime,
  required String windowEnd,
  required bool handledToday,
}) {
  if (!enabled) return const ReminderOff();

  final nowUtc = now.toUtc();
  final wall = vietnamWallClock(nowUtc);
  final todayAt = _instantAt(wall, reminderTime);
  // Khung tính cả phút cuối: 21:59 nghĩa là còn nhắc được tới 21:59:59.
  final closesAt = _instantAt(wall, windowEnd).add(const Duration(minutes: 1));

  if (!handledToday) {
    if (nowUtc.isBefore(todayAt)) return ReminderWait(todayAt.difference(nowUtc));
    if (nowUtc.isBefore(closesAt)) return const ReminderShowNow();
  }
  return ReminderWait(todayAt.add(const Duration(days: 1)).difference(nowUtc));
}

typedef TimerFactory = Timer Function(Duration delay, void Function() callback);

/// Lập lịch nhắc cho một người dùng trên thiết bị này.
///
/// Không biết gì về widget: nhận cài đặt, cách đồng bộ và cách hiện lời nhắc
/// qua tham số, nên test dựng được mọi tình huống giờ giấc mà không cần UI.
class StreakReminderScheduler {
  StreakReminderScheduler({
    required this.userId,
    required this.readSettings,
    required this.syncStudiedToday,
    required this.showReminder,
    Future<SharedPreferences> Function()? preferences,
    DateTime Function()? clock,
    TimerFactory? timerFactory,
  })  : _preferences = preferences ?? SharedPreferences.getInstance,
        _clock = clock ?? DateTime.now,
        _timerFactory = timerFactory ?? Timer.new;

  final String userId;

  /// Cài đặt hiện có; `null` khi chưa tải xong.
  final StreakSettings? Function() readSettings;

  /// Đồng bộ với server rồi cho biết hôm nay đã học chưa; `null` khi không
  /// đồng bộ được — lúc đó không được coi là "chưa học".
  final Future<bool?> Function() syncStudiedToday;
  final void Function() showReminder;

  final Future<SharedPreferences> Function() _preferences;
  final DateTime Function() _clock;
  final TimerFactory _timerFactory;

  /// Mất mạng thì thử lại sau chừng này, không đánh dấu gì.
  static const retryDelay = Duration(minutes: 10);

  Timer? _timer;
  bool _disposed = false;

  /// Tăng ở mỗi lần xét lại; việc đang dở của lần xét cũ tự dừng, nên hai lần
  /// xét chồng nhau (đổi cài đặt đúng lúc đang đồng bộ) không nhắc hai lần.
  int _generation = 0;

  static String handledKey(String userId, String dayKey) => 'streak_reminder_handled:$userId:$dayKey';

  bool _stale(int generation) => _disposed || generation != _generation;

  /// Tính lại lịch nhắc từ đầu theo giờ thật lúc gọi.
  Future<void> reschedule() async {
    final generation = ++_generation;
    _timer?.cancel();
    _timer = null;

    final settings = readSettings();
    if (settings == null) return;
    final prefs = await _preferences();
    if (_stale(generation)) return;

    final now = _clock();
    final decision = decideReminder(
      now: now,
      enabled: settings.reminderEnabled,
      reminderTime: settings.reminderTime,
      windowEnd: settings.reminderWindowEnd,
      handledToday: prefs.getBool(handledKey(userId, vietnamDayKey(now))) ?? false,
    );

    switch (decision) {
      case ReminderOff():
        return;
      case ReminderWait(:final delay):
        // Hết giờ chờ thì xét lại chứ không nhắc thẳng: máy có thể đã ngủ qua
        // khung giờ, và lúc thức dậy có khi đã quá 22:00.
        _timer = _timerFactory(delay, reschedule);
      case ReminderShowNow():
        await _remindIfNotStudied(prefs, generation);
    }
  }

  Future<void> _remindIfNotStudied(SharedPreferences prefs, int generation) async {
    final dayKey = vietnamDayKey(_clock());
    final studied = await syncStudiedToday();
    if (_stale(generation)) return;

    if (studied == null) {
      _timer = _timerFactory(retryDelay, reschedule);
      return;
    }

    // Đánh dấu trước khi hiện: tải lại trang ngay sau đó không nhắc lần nữa.
    await prefs.setBool(handledKey(userId, dayKey), true);
    if (_stale(generation)) return;
    if (!studied) showReminder();
    await reschedule();
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
  }
}
