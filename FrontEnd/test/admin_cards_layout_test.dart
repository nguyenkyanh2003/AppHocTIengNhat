import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:apphoctiengnnhat/app/theme/app_theme.dart';
import 'package:apphoctiengnnhat/features/admin/providers/admin_provider.dart';
import 'package:apphoctiengnnhat/features/admin/models/admin_achievement.dart';
import 'package:apphoctiengnnhat/features/admin/widgets/admin_achievement_card.dart';
import 'package:apphoctiengnnhat/features/admin/widgets/admin_report_card.dart';
import 'package:apphoctiengnnhat/features/admin/widgets/admin_user_card.dart';

/// Thẻ quản trị ở khổ điện thoại nhỏ, chữ dài và đã mở rộng: mọi lỗi tràn bố cục hay sai
/// kiểu dữ liệu đều làm test đỏ.
Future<void> _pumpExpanded(
    WidgetTester tester, Widget card, String tapText) async {
  tester.view.physicalSize = const Size(320, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ChangeNotifierProvider(
    create: (_) => AdminProvider(),
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(body: SingleChildScrollView(child: card)),
    ),
  ));
  await tester.tap(find.textContaining(tapText).first);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('thẻ người dùng: tên dài, trạng thái và nhãn ADMIN không tràn',
      (tester) async {
    await _pumpExpanded(
      tester,
      const AdminUserCard(user: {
        '_id': 'u1',
        'name': 'Nguyễn Thị Thuỳ Dương Hoàng Lan Anh',
        'email': 'mot.dia.chi.email.rat.dai.de.thu@example.invalid',
        'status': 'active',
        'role': 'admin',
        'joinDate': '2026-11-05T07:17:27.828Z',
        'lastActive': 'Chưa có',
        'totalXP': 10,
        'streak': 2,
      }),
      'Nguyễn',
    );

    expect(find.text('ADMIN'), findsOneWidget);
    expect(find.textContaining('T07:17'), findsNothing,
        reason: 'Ngày phải đọc được');
    expect(tester.takeException(), isNull);
  });

  testWidgets('thẻ thành tích: điều kiện là số vẫn hiện được', (tester) async {
    await _pumpExpanded(
      tester,
      AdminAchievementCard(
        achievement: AdminAchievement.fromJson(const {
          '_id': 'a1',
          'icon': '📝',
          'name_vi': 'Một thành tích có tên khá dài để thử bố cục',
          'description_vi': 'Học năm điểm ngữ pháp',
          'category': 'grammar',
          'rarity': 'legendary',
          'xp_reward': 50,
          'unlocked': 0,
          'requirement_value': 5,
        }),
      ),
      'Một thành tích',
    );

    expect(find.text('Số bài tập mẫu câu đã đạt: 5'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('thẻ báo cáo: hiện người gửi, ngày và phản hồi thật, không tràn',
      (tester) async {
    await _pumpExpanded(
      tester,
      AdminReportCard(
        updateStatus: (_, __) {},
        report: const {
          '_id': 'r1',
          'title': 'Báo cáo có tiêu đề khá dài để thử bố cục trên màn hẹp',
          'description': 'Mô tả',
          'type': 'bug',
          'priority': 'high',
          'status': 'in_progress',
          'createdAt': '2026-11-05T07:00:00.000Z',
          'admin_response': 'Đã ghi nhận',
          'user_id': {'HoTen': 'Lê Lan', 'Email': 'lan@example.invalid'},
        },
      ),
      'Báo cáo có tiêu đề',
    );

    expect(find.textContaining('Lê Lan'), findsOneWidget);
    expect(find.text('Đã ghi nhận'), findsOneWidget);
    expect(find.textContaining('null'), findsNothing);
    expect(find.textContaining('Cảm ơn bạn'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
