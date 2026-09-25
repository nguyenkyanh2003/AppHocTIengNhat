import 'package:flutter_test/flutter_test.dart';

import 'package:apphoctiengnnhat/features/streaks/models/day_key.dart';
import 'package:apphoctiengnnhat/features/streaks/models/streak_settings.dart';
import 'package:apphoctiengnnhat/features/streaks/models/user_streak.dart';

void main() {
  group('khoá ngày Việt Nam', () {
    test('ranh giới nửa đêm theo UTC+7, không theo máy đang chạy', () {
      expect(vietnamDayKey(DateTime.utc(2026, 9, 25, 16, 59)), '2026-09-25');
      expect(vietnamDayKey(DateTime.utc(2026, 9, 25, 17)), '2026-09-26');
    });

    test('định dạng ngắn và cộng ngày qua tháng, qua năm', () {
      expect(formatDayKey('2026-09-06'), '06/09');
      expect(addDaysToKey('2026-09-30', 1), '2026-10-01');
      expect(addDaysToKey('2026-12-31', 1), '2027-01-01');
      expect(addDaysToKey('2026-03-01', -1), '2026-02-28');
    });
  });

  group('UserStreak', () {
    test('đọc đủ trường Phần B', () {
      final streak = UserStreak.fromJson({
        '_id': 's1',
        'user': 'u1',
        'current_streak': 5,
        'longest_streak': 9,
        'total_xp': 240,
        'level': 3,
        'xp_to_next_level': 60,
        'total_active_days': 12,
        'last_activity_day': '2026-09-23',
        'tracking_started_day': '2026-09-01',
        'first_day': '2026-08-20',
        'studied_today': false,
        'freezes_available': 2,
        'max_freezes': 2,
        'pending_frozen_days': ['2026-09-24'],
        'freezes_after_pending': 1,
        'daily_goal': {
          'target_xp': 20,
          'today_xp': 12,
          'reached': false,
          'next_target_xp': 30,
          'next_target_from': '2026-09-26',
        },
        'activity_dates': ['2026-09-23'],
      });

      expect(streak.totalActiveDays, 12);
      expect(streak.lastActivityDay, '2026-09-23');
      expect(streak.trackingStartedDay, '2026-09-01');
      expect(streak.firstDay, '2026-08-20');
      expect(streak.studiedToday, isFalse);
      expect(streak.freezesAvailable, 2);
      expect(streak.maxFreezes, 2);
      expect(streak.pendingFrozenDays, ['2026-09-24']);
      expect(streak.pendingFreezes, 1);
      expect(streak.freezesAfterPending, 1);
      expect(streak.dailyGoal.targetXp, 20);
      expect(streak.dailyGoal.todayXp, 12);
      expect(streak.dailyGoal.reached, isFalse);
      expect(streak.dailyGoal.remainingXp, 8);
      expect(streak.dailyGoal.ratio, closeTo(0.6, 1e-9));
      expect(streak.dailyGoal.nextTargetXp, 30);
      expect(streak.dailyGoal.nextTargetFrom, '2026-09-26');
    });

    test('server cũ không gửi trường mới thì dùng mặc định an toàn', () {
      final streak = UserStreak.fromJson({'current_streak': 3});

      expect(streak.freezesAvailable, 0);
      expect(streak.maxFreezes, 2);
      expect(streak.pendingFrozenDays, isEmpty);
      expect(streak.freezesAfterPending, 0);
      expect(streak.studiedToday, isFalse);
      expect(streak.dailyGoal.targetXp, 20);
      expect(streak.dailyGoal.todayXp, 0);
      expect(streak.dailyGoal.reached, isFalse);
    });

    test('vượt mục tiêu thì thanh tiến độ dừng ở đầy', () {
      const goal = DailyGoalProgress(targetXp: 10, todayXp: 26);
      expect(goal.reached, isTrue);
      expect(goal.ratio, 1.0);
      expect(goal.remainingXp, 0);
    });
  });

  group('StreakSettings', () {
    test('đọc cài đặt và mục tiêu đang chờ', () {
      final settings = StreakSettings.fromJson({
        'daily_goal_xp': 20,
        'next_daily_goal_xp': 50,
        'next_goal_from': '2026-09-26',
        'goal_options': [10, 20, 30, 50],
        'reminder_enabled': true,
        'reminder_time': '19:30',
        'reminder_window': {'start': '08:00', 'end': '21:59'},
        'revision': 3,
      });

      expect(settings.dailyGoalXp, 20);
      expect(settings.nextDailyGoalXp, 50);
      expect(settings.chosenGoalXp, 50);
      expect(settings.nextGoalFrom, '2026-09-26');
      expect(settings.goalOptions, [10, 20, 30, 50]);
      expect(settings.reminderEnabled, isTrue);
      expect(settings.reminderTime, '19:30');
      expect(settings.reminderWindowEnd, '21:59');
      expect(settings.revision, 3);
    });

    test('chưa có gì chờ thì lựa chọn hiện tại là mục tiêu hôm nay', () {
      final settings = StreakSettings.fromJson({'daily_goal_xp': 30});
      expect(settings.chosenGoalXp, 30);
      expect(settings.reminderEnabled, isFalse);
      expect(settings.reminderTime, '20:00');
    });

    test('mốc giờ nhắc cách 30 phút, nằm trong khung, có cả giờ đang đặt', () {
      const settings = StreakSettings(reminderTime: '20:15');
      final options = settings.reminderTimeOptions;

      expect(options.first, '08:00');
      expect(options.last, '21:30');
      expect(options, contains('20:15'));
      expect(options, isNot(contains('22:00')));
      expect(options, isNot(contains('07:30')));
      // Có thứ tự để danh sách chọn không nhảy lung tung.
      expect(options, [...options]..sort());
    });
  });
}
