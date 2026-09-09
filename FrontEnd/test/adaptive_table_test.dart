import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:apphoctiengnnhat/shared/widgets/adaptive_table.dart';

/// Bọc bảng trong một khung có bề rộng cố định để đo đúng ngưỡng chuyển.
Widget _host({required double width, required Widget child}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(width: width, height: 600, child: child),
      ),
    ),
  );
}

AdaptiveTable<String> _table({
  required List<AdaptiveColumn<String>> columns,
  void Function(String)? onRowTap,
}) {
  return AdaptiveTable<String>(
    items: const ['あ', 'い', 'う'],
    columns: columns,
    cardBuilder: (context, item) => ListTile(title: Text('thẻ $item')),
    onRowTap: onRowTap,
  );
}

List<AdaptiveColumn<String>> _columns(int count, {double minWidth = 140}) {
  return [
    for (var i = 0; i < count; i++)
      AdaptiveColumn<String>(
        label: 'Cột $i',
        minWidth: minWidth,
        cell: (context, item) => Text('$item-$i'),
      ),
  ];
}

void main() {
  group('AdaptiveTable', () {
    testWidgets('vùng hẹp dựng thẻ, không dựng bảng', (tester) async {
      await tester.pumpWidget(
        _host(width: 360, child: _table(columns: _columns(3))),
      );

      expect(find.text('thẻ あ'), findsOneWidget);
      expect(find.text('Cột 0'), findsNothing);
    });

    testWidgets('vùng rộng dựng bảng có tiêu đề cột', (tester) async {
      await tester.pumpWidget(
        _host(width: 1000, child: _table(columns: _columns(3))),
      );

      expect(find.text('Cột 0'), findsOneWidget);
      expect(find.text('Cột 2'), findsOneWidget);
      expect(find.text('あ-0'), findsOneWidget);
      expect(find.text('thẻ あ'), findsNothing);
    });

    testWidgets('ngưỡng chuyển suy từ chính các cột, không phải số cố định', (
      tester,
    ) async {
      // 3 cột × 140 + lề 32 = 452 → 500px đủ chỗ cho bảng.
      await tester.pumpWidget(
        _host(width: 500, child: _table(columns: _columns(3))),
      );
      expect(find.text('Cột 0'), findsOneWidget);

      // Cùng bề rộng đó, 6 cột cần 872 → phải lùi về thẻ.
      await tester.pumpWidget(
        _host(width: 500, child: _table(columns: _columns(6))),
      );
      await tester.pumpAndSettle();
      expect(find.text('Cột 0'), findsNothing);
      expect(find.text('thẻ あ'), findsOneWidget);
    });

    testWidgets('bấm một dòng của bảng trả về đúng bản ghi', (tester) async {
      final tapped = <String>[];
      await tester.pumpWidget(
        _host(
          width: 1000,
          child: _table(columns: _columns(3), onRowTap: tapped.add),
        ),
      );

      await tester.tap(find.text('い-0'));
      await tester.pumpAndSettle();
      expect(tapped, ['い']);
    });

    testWidgets('cột rộng cố định giữ nguyên bề rộng khi vùng giãn ra', (
      tester,
    ) async {
      final columns = [
        AdaptiveColumn<String>(
          label: 'Cố định',
          width: 200,
          cell: (context, item) => Text('co-dinh-$item'),
        ),
        AdaptiveColumn<String>(
          label: 'Co giãn',
          cell: (context, item) => Text('co-gian-$item'),
        ),
      ];

      await tester.pumpWidget(
        _host(width: 1200, child: _table(columns: columns)),
      );

      final fixed = tester.getSize(
        find
            .ancestor(
              of: find.text('co-dinh-あ'),
              matching: find.byType(SizedBox),
            )
            .first,
      );
      expect(fixed.width, 200);
    });

    testWidgets('kéo-để-làm-mới gắn vào danh sách dọc ở cả hai chế độ', (
      tester,
    ) async {
      Future<void> noop() async {}

      for (final width in [360.0, 1000.0]) {
        await tester.pumpWidget(
          _host(
            width: width,
            child: AdaptiveTable<String>(
              items: const ['あ'],
              columns: _columns(3),
              onRefresh: noop,
              cardBuilder: (context, item) =>
                  ListTile(title: Text('thẻ $item')),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Ở chế độ bảng, vùng cuộn gần nhất là vùng cuộn **ngang**; chỉ dựng
        // đúng khi RefreshIndicator nằm quanh danh sách dọc bên trong.
        final refresh = find.byType(RefreshIndicator);
        expect(refresh, findsOneWidget, reason: 'ở bề rộng $width');
        expect(
          find.descendant(of: refresh, matching: find.byType(ListView)),
          findsOneWidget,
          reason: 'ở bề rộng $width',
        );
      }
    });

    testWidgets('không tràn bố cục ở các bề rộng đã chốt', (tester) async {
      for (final width in [360.0, 599.0, 600.0, 601.0, 840.0, 1440.0, 1920.0]) {
        await tester.pumpWidget(
          _host(width: width, child: _table(columns: _columns(4))),
        );
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: 'tràn bố cục ở bề rộng $width',
        );
      }
    });
  });
}
