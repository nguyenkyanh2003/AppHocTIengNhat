import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:apphoctiengnnhat/app/theme/app_theme.dart';
import 'package:apphoctiengnnhat/features/achievements/models/achievement.dart';
import 'package:apphoctiengnnhat/features/achievements/widgets/achievement_card.dart';
import 'package:apphoctiengnnhat/features/streaks/models/leaderboard.dart';
import 'package:apphoctiengnnhat/features/streaks/widgets/leaderboard_item.dart';

/// Điện thoại nhỏ nhất đang hỗ trợ. Lỗi tràn bố cục làm test đỏ.
Future<void> _pumpNarrow(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(320, 700);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.lightTheme,
    home: Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    ),
  ));
  await tester.pump();
}

void main() {
  testWidgets('thẻ thành tích đã đạt không tràn ở bề rộng 320', (tester) async {
    await _pumpNarrow(
      tester,
      AchievementCard(
        userAchievement: UserAchievement(
          id: 'u1',
          userId: 'x',
          earnedAt: DateTime(2026, 11, 5),
          progress: 1,
          isCompleted: true,
          achievement: Achievement.fromJson(const {
            '_id': 'a1',
            'name_vi': 'Bước chân đầu tiên trên hành trình học tiếng Nhật',
            'description_vi': 'Hoàn thành bài học đầu tiên',
            'xp_reward': 12000,
            'rarity': 'legendary',
          }),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  for (final rank in [1, 9, 120]) {
    testWidgets('dòng bảng xếp hạng hạng $rank không tràn ở bề rộng 320',
        (tester) async {
      await _pumpNarrow(
        tester,
        LeaderboardItem(
          entry: LeaderboardEntry.fromJson({
            'rank': rank,
            'user': const {
              '_id': 'u1',
              'TenDangNhap': 'lan',
              'HoTen': 'Nguyễn Thị Thuỳ Dương Hoàng Lan',
            },
            'total_xp': 1234567,
            'level': 120,
            'current_streak': 1000,
            'longest_streak': 1000,
          }),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  }
}
