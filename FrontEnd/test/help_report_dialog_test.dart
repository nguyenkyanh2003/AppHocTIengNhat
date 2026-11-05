import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

import 'package:apphoctiengnnhat/app/theme/app_theme.dart';
import 'package:apphoctiengnnhat/features/reports/providers/report_provider.dart';
import 'package:apphoctiengnnhat/features/settings/widgets/help_dialogs.dart';

const _headers = {'content-type': 'application/json; charset=utf-8'};

Widget _host(Future<void> Function(BuildContext) open) => ChangeNotifierProvider(
      create: (_) => ReportProvider(),
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => open(context),
              child: const Text('mở'),
            ),
          ),
        ),
      ),
    );

void main() {
  for (final (name, open, type) in [
    ('báo lỗi', showHelpBugReportDialog, 'bug'),
    ('góp ý', showHelpFeedbackDialog, 'suggestion'),
  ]) {
    testWidgets('$name: nội dung được gửi lên server, không bị bỏ đi', (tester) async {
      Map<String, dynamic>? sent;
      final client = MockClient((request) async {
        expect(request.url.path, endsWith('/report/create'));
        sent = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response.bytes(
          utf8.encode(jsonEncode({
            'message': 'ok',
            'data': {
              '_id': 'r1',
              'user_id': 'u1',
              'type': type,
              'title': sent!['title'],
              'description': sent!['description'],
              'priority': 'medium',
              'status': 'pending',
              'createdAt': '2026-11-05T00:00:00.000Z',
              'updatedAt': '2026-11-05T00:00:00.000Z',
            },
          })),
          201,
          headers: _headers,
        );
      });

      await http.runWithClient(() async {
        await tester.pumpWidget(_host(open));
        await tester.tap(find.text('mở'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'Nút nghe không phát âm');
        await tester.tap(find.widgetWithText(ElevatedButton, 'Gửi'));
        await tester.pumpAndSettle();
      }, () => client);

      expect(sent?['type'], type);
      expect(sent?['description'], 'Nút nghe không phát âm');
      expect(sent?['title'], isNotEmpty);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.textContaining('Cảm ơn'), findsOneWidget);
    });

    testWidgets('$name: chưa nhập gì thì không gửi', (tester) async {
      var calls = 0;
      await http.runWithClient(() async {
        await tester.pumpWidget(_host(open));
        await tester.tap(find.text('mở'));
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(ElevatedButton, 'Gửi'));
        await tester.pumpAndSettle();
      }, () => MockClient((_) async {
            calls += 1;
            return http.Response('{}', 200, headers: _headers);
          }));

      expect(calls, 0);
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('$name: gửi lỗi thì giữ hộp thoại và nội dung để gửi lại', (tester) async {
      await http.runWithClient(() async {
        await tester.pumpWidget(_host(open));
        await tester.tap(find.text('mở'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'Nội dung');
        await tester.tap(find.widgetWithText(ElevatedButton, 'Gửi'));
        await tester.pumpAndSettle();
      }, () => MockClient((request) async => throw http.ClientException('Failed to fetch', request.url)));

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Nội dung'), findsOneWidget);
      expect(find.textContaining('Không thể kết nối'), findsOneWidget);
      expect(find.textContaining('Cảm ơn'), findsNothing);
    });
  }
}
