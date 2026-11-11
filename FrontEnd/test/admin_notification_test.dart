import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:apphoctiengnnhat/app/theme/app_theme.dart';
import 'package:apphoctiengnnhat/core/network/api_client.dart';
import 'package:apphoctiengnnhat/features/admin/providers/admin_provider.dart';
import 'package:apphoctiengnnhat/features/admin/screens/admin_user_management_screen.dart';
import 'package:apphoctiengnnhat/features/admin/services/admin_service.dart';
import 'package:apphoctiengnnhat/features/admin/widgets/send_notification_dialog.dart';
import 'package:apphoctiengnnhat/features/notifications/models/notification.dart';

http.Response _json(Object body, [int status = 200]) => http.Response(jsonEncode(body), status,
    headers: {'content-type': 'application/json; charset=utf-8'});

/// Service giả: một người dùng, ghi lại mọi lần gửi thông báo.
class _FakeAdminService extends AdminService {
  final sends = <String>[];
  Object? error;

  @override
  Future<List<dynamic>> getAllUsers({int page = 1, int limit = 20, String? search, String? status, String? role}) async => [
        {
          '_id': 'u1', 'id': 'u1', 'name': 'Nguyễn An', 'email': 'an@example.com', 'role': 'user', 'status': 'active',
          'joinDate': '01/09/2026', 'lastActive': 'Hôm nay', 'streak': 3, 'totalXP': 120,
        },
      ];

  @override
  Future<Map<String, dynamic>> getUserStats() async => {};

  @override
  Future<Map<String, dynamic>> sendNotification({
    required String recipientId,
    required String title,
    required String message,
    required NotificationType type,
  }) async {
    if (error != null) throw error!;
    sends.add('$recipientId|$title|$message|${type.key}');
    return {};
  }

  @override
  Future<int> broadcastNotification({required String title, required String message, required NotificationType type}) async {
    if (error != null) throw error!;
    sends.add('ALL|$title|$message|${type.key}');
    return 12;
  }
}

Future<void> _fill(WidgetTester tester, {String title = 'Lịch thi', String message = 'Thi thử N4 thứ Bảy'}) async {
  await tester.enterText(find.widgetWithText(TextFormField, 'Tiêu đề'), title);
  await tester.enterText(find.widgetWithText(TextFormField, 'Nội dung'), message);
}

Future<_FakeAdminService> _pumpUserScreen(WidgetTester tester) async {
  // Màn rộng (bố cục bảng) như admin thường dùng.
  tester.view.physicalSize = const Size(1280, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final service = _FakeAdminService();
  await tester.pumpWidget(ChangeNotifierProvider(
    create: (_) => AdminProvider(adminService: service),
    child: MaterialApp(theme: AppTheme.lightTheme, home: const AdminUserManagementScreen()),
  ));
  await tester.pumpAndSettle();
  return service;
}

void main() {
  test('service gửi đúng hợp đồng mới cho một người và cho tất cả', () async {
    final requests = <http.Request>[];
    late int sent;

    await http.runWithClient(() async {
      final service = AdminService();
      await service.sendNotification(recipientId: 'u1', title: 'Chào', message: 'Học tiếp', type: NotificationType.lesson);
      sent = await service.broadcastNotification(title: 'Bảo trì', message: 'Tối nay', type: NotificationType.system);
    }, () => MockClient((request) async {
      requests.add(request);
      return request.url.path.endsWith('/broadcast/all')
          ? _json({'data': {'sent': 12}}, 201)
          : _json({'data': {'id': 'n1'}}, 201);
    }));

    expect(requests.map((r) => '${r.method} ${r.url.path}'), ['POST /api/notifications', 'POST /api/notifications/broadcast/all']);
    expect(jsonDecode(requests[0].body), {'recipient_id': 'u1', 'title': 'Chào', 'message': 'Học tiếp', 'type': 'LESSON'});
    expect(jsonDecode(requests[1].body), {'title': 'Bảo trì', 'message': 'Tối nay', 'type': 'SYSTEM'});
    expect(sent, 12);
  });

  testWidgets('form chặn khi thiếu tiêu đề hoặc nội dung', (tester) async {
    var calls = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: SendNotificationDialog(onSend: (_, __, ___) async { calls++; return null; })),
    ));

    await tester.tap(find.text('Gửi'));
    await tester.pump();

    expect(find.text('Vui lòng nhập tiêu đề.'), findsOneWidget);
    expect(find.text('Vui lòng nhập nội dung.'), findsOneWidget);
    expect(calls, 0);
  });

  testWidgets('lỗi gửi hiện ngay trong form và giữ nội dung đã nhập', (tester) async {
    final service = await _pumpUserScreen(tester);
    service.error = ApiException('Không tìm thấy người nhận.');

    await tester.tap(find.byTooltip('Gửi thông báo cho tất cả'));
    await tester.pumpAndSettle();
    await _fill(tester);
    await tester.tap(find.text('Gửi'));
    await tester.pumpAndSettle();

    expect(find.text('Không tìm thấy người nhận.'), findsOneWidget);
    expect(find.text('Lịch thi'), findsOneWidget);
  });

  testWidgets('gửi cho tất cả từ màn Quản lý người dùng', (tester) async {
    final service = await _pumpUserScreen(tester);

    await tester.tap(find.byTooltip('Gửi thông báo cho tất cả'));
    await tester.pumpAndSettle();
    expect(find.text('Gửi tới: tất cả người học'), findsOneWidget);

    await _fill(tester);
    await tester.tap(find.byType(DropdownButtonFormField<NotificationType>));
    await tester.pumpAndSettle();
    expect(find.text('Thành tích'), findsNothing, reason: 'admin không gửi được thông báo huy hiệu');
    await tester.tap(find.text('Kỳ thi').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gửi'));
    await tester.pumpAndSettle();

    expect(service.sends, ['ALL|Lịch thi|Thi thử N4 thứ Bảy|EXAM']);
    expect(find.text('Đã gửi thông báo cho 12 người học.'), findsOneWidget);
    expect(find.byType(SendNotificationDialog), findsNothing);
  });

  testWidgets('gửi cho một người từ menu của người đó', (tester) async {
    final service = await _pumpUserScreen(tester);

    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gửi thông báo'));
    await tester.pumpAndSettle();
    expect(find.text('Gửi tới: Nguyễn An'), findsOneWidget);

    await _fill(tester, title: '  Chào An  ', message: 'Nhớ ôn bài nhé');
    await tester.tap(find.text('Gửi'));
    await tester.pumpAndSettle();

    expect(service.sends, ['u1|Chào An|Nhớ ôn bài nhé|SYSTEM']);
    expect(find.text('Đã gửi thông báo cho Nguyễn An.'), findsOneWidget);
  });
}
