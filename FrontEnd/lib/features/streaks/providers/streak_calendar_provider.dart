import 'package:flutter/foundation.dart';

import '../../../core/state/view_state.dart';
import '../models/day_key.dart';
import '../models/user_streak.dart';
import '../services/streak_service.dart';

/// Trạng thái của màn lịch: tháng đang xem và các ngày của tháng đó.
///
/// Sống cùng màn lịch chứ không toàn cục: rời màn là bỏ, không phải dọn khi
/// đăng xuất.
class StreakCalendarProvider extends ChangeNotifier {
  StreakCalendarProvider({StreakService? service, DateTime Function()? clock})
      : _service = service ?? StreakService(),
        _clock = clock ?? DateTime.now {
    final today = vietnamWallClock(_clock());
    _month = DateTime.utc(today.year, today.month);
  }

  final StreakService _service;
  final DateTime Function() _clock;
  late DateTime _month;
  ViewState<Map<String, StreakDay>> _days = const ViewState.idle();

  /// Tăng ở mỗi lần tải; phản hồi của lần tải cũ (tháng đã rời đi) bị bỏ.
  int _generation = 0;

  /// Ngày 1 của tháng đang xem (UTC, chỉ dùng năm/tháng).
  DateTime get month => _month;
  ViewState<Map<String, StreakDay>> get days => _days;
  String get todayKey => vietnamDayKey(_clock());

  DateTime get _currentMonth {
    final today = vietnamWallClock(_clock());
    return DateTime.utc(today.year, today.month);
  }

  /// Không xem được tháng tương lai: chưa có gì để hiện.
  bool get canGoNext => _month.isBefore(_currentMonth);

  /// Lùi được tới tháng có ngày sớm nhất trong lịch.
  bool canGoPrevious(String? earliestDay) {
    if (earliestDay == null) return false;
    final earliest = parseDayKey(earliestDay);
    return _month.isAfter(DateTime.utc(earliest.year, earliest.month));
  }

  Future<void> load() async {
    final generation = ++_generation;
    _days = const ViewState.loading();
    notifyListeners();

    final from = dayKeyOf(_month);
    final to = dayKeyOf(DateTime.utc(_month.year, _month.month + 1, 0));
    final result = await ViewState.guard(() async {
      // Một tháng tối đa 31 ngày, nằm gọn trong một trang (tối đa 100).
      final page = await _service.getDays(from: from, to: to);
      return {for (final day in page.days) day.dayKey: day};
    });

    if (generation != _generation) return;
    _days = result;
    notifyListeners();
  }

  Future<void> showPrevious() {
    _month = DateTime.utc(_month.year, _month.month - 1);
    return load();
  }

  Future<void> showNext() {
    if (!canGoNext) return Future.value();
    _month = DateTime.utc(_month.year, _month.month + 1);
    return load();
  }
}
