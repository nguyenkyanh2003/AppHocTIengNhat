import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:apphoctiengnnhat/shared/widgets/app_dialog.dart';

Widget _host(void Function(BuildContext context) onPressed) {
  return MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => onPressed(context),
          child: const Text('mở'),
        ),
      ),
    ),
  );
}

void main() {
  group('đóng hộp thoại bằng bàn phím', () {
    testWidgets('showDialog mặc định: Esc đóng được', (tester) async {
      await tester.pumpWidget(
        _host(
          (context) => showDialog<void>(
            context: context,
            builder: (context) => const AlertDialog(title: Text('nội dung')),
          ),
        ),
      );

      await tester.tap(find.text('mở'));
      await tester.pumpAndSettle();
      expect(find.text('nội dung'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('nội dung'), findsNothing);
    });

    testWidgets('barrierDismissible: false chặn luôn cả Esc', (tester) async {
      // Đây là lý do `showAppDialog` tồn tại: biểu mẫu cần chặn bấm ra ngoài
      // để khỏi mất dữ liệu, nhưng chặn luôn bàn phím thì người dùng chỉ dùng
      // bàn phím sẽ mắc kẹt.
      await tester.pumpWidget(
        _host(
          (context) => showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (context) => const AlertDialog(title: Text('nội dung')),
          ),
        ),
      );

      await tester.tap(find.text('mở'));
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('nội dung'), findsOneWidget);
    });

    testWidgets('showAppDialog: chặn bấm ra ngoài nhưng Esc vẫn đóng', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          (context) => showAppDialog<void>(
            context: context,
            dismissOnBarrierTap: false,
            builder: (context) => const AlertDialog(title: Text('nội dung')),
          ),
        ),
      );

      await tester.tap(find.text('mở'));
      await tester.pumpAndSettle();
      expect(find.text('nội dung'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('nội dung'), findsNothing);
    });

    testWidgets('showAppDialog trả về null khi đóng bằng Esc', (tester) async {
      String? result = 'chưa đóng';
      await tester.pumpWidget(
        _host((context) async {
          result = await showAppDialog<String>(
            context: context,
            dismissOnBarrierTap: false,
            builder: (context) => const AlertDialog(title: Text('nội dung')),
          );
        }),
      );

      await tester.tap(find.text('mở'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(result, isNull);
    });
  });

  group('vòng focus', () {
    testWidgets('Tab đi qua các nút của hộp thoại', (tester) async {
      await tester.pumpWidget(
        _host(
          (context) => showAppDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('nội dung'),
              actions: [
                TextButton(onPressed: () {}, child: const Text('Hủy')),
                FilledButton(onPressed: () {}, child: const Text('Đồng ý')),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text('mở'));
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      final first = primaryFocus;
      expect(first, isNotNull);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(primaryFocus, isNot(same(first)));
    });
  });
}
