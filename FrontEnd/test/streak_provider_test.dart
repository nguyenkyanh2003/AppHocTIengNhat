import 'package:flutter_test/flutter_test.dart';

import 'package:apphoctiengnnhat/core/network/api_client.dart';
import 'package:apphoctiengnnhat/core/state/view_state.dart';
import 'package:apphoctiengnnhat/features/streaks/models/streak_settings.dart';
import 'package:apphoctiengnnhat/features/streaks/models/user_streak.dart';
import 'package:apphoctiengnnhat/features/streaks/providers/streak_provider.dart';
import 'package:apphoctiengnnhat/features/streaks/services/streak_service.dart';

/// Service giả: trả dữ liệu cấu hình sẵn, ghi lại mọi lần lưu.
class _FakeStreakService extends StreakService {
  UserStreak streak = UserStreak.fromJson({'current_streak': 4});
  Object? streakError;
  StreakSettings settings = const StreakSettings();
  Object? saveError;
  int summaryCalls = 0;
  final List<Map<String, Object?>> saves = [];

  @override
  Future<UserStreak> getMyStreak() async {
    summaryCalls += 1;
    if (streakError != null) throw streakError!;
    return streak;
  }

  @override
  Future<StreakSettings> getSettings() async => settings;

  @override
  Future<StreakSettings> updateSettings({
    int? dailyGoalXp,
    bool? reminderEnabled,
    String? reminderTime,
  }) async {
    saves.add({
      'daily_goal_xp': dailyGoalXp,
      'reminder_enabled': reminderEnabled,
      'reminder_time': reminderTime,
    });
    if (saveError != null) throw saveError!;
    return settings = StreakSettings(
      dailyGoalXp: settings.dailyGoalXp,
      nextDailyGoalXp: dailyGoalXp,
      reminderEnabled: reminderEnabled ?? settings.reminderEnabled,
      reminderTime: reminderTime ?? settings.reminderTime,
    );
  }
}

void main() {
  test('tải tóm tắt thành công trả true', () async {
    final service = _FakeStreakService();
    final provider = StreakProvider(service: service);

    expect(await provider.loadStreak(), isTrue);
    expect(provider.currentStreak?.currentStreak, 4);
    expect(provider.error, isNull);
  });

  test('lỗi mạng giữ nguyên dữ liệu đang có và trả false', () async {
    final service = _FakeStreakService();
    final provider = StreakProvider(service: service);
    await provider.loadStreak();

    service.streakError = NetworkException('Mất kết nối');
    expect(await provider.loadStreak(), isFalse);

    expect(provider.currentStreak?.currentStreak, 4,
        reason: 'mất mạng một lần không được xoá trắng màn hình');
    expect(provider.error, isNotNull);
  });

  test('tải cài đặt đưa về ViewState có dữ liệu', () async {
    final service = _FakeStreakService()..settings = const StreakSettings(dailyGoalXp: 30);
    final provider = StreakProvider(service: service);

    await provider.loadSettings();

    expect(provider.settings.valueOrNull?.dailyGoalXp, 30);
  });

  test('lưu cài đặt thành công cập nhật cài đặt và tải lại tóm tắt', () async {
    final service = _FakeStreakService();
    final provider = StreakProvider(service: service);
    await provider.loadSettings();

    final error = await provider.saveSettings(dailyGoalXp: 50, reminderEnabled: true);

    expect(error, isNull);
    expect(service.saves.single, {
      'daily_goal_xp': 50,
      'reminder_enabled': true,
      'reminder_time': null,
    });
    expect(provider.settings.valueOrNull?.nextDailyGoalXp, 50);
    expect(service.summaryCalls, 1, reason: 'thẻ mục tiêu đọc từ tóm tắt nên phải tải lại');
  });

  test('server từ chối thì trả câu báo lỗi và giữ cài đặt cũ', () async {
    final service = _FakeStreakService()
      ..saveError = BadRequestException('Giờ nhắc phải trong khoảng 08:00–21:59.');
    final provider = StreakProvider(service: service);
    await provider.loadSettings();

    final error = await provider.saveSettings(reminderTime: '22:30');

    expect(error, 'Giờ nhắc phải trong khoảng 08:00–21:59.');
    expect(provider.settings.valueOrNull?.reminderTime, '20:00');
    expect(service.summaryCalls, 0);
  });

  test('đăng xuất xoá cả cài đặt', () async {
    final provider = StreakProvider(service: _FakeStreakService());
    await provider.loadSettings();

    provider.clear();

    expect(provider.settings, isA<ViewIdle<StreakSettings>>());
    expect(provider.currentStreak, isNull);
  });
}
