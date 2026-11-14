import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:apphoctiengnnhat/shared/widgets/load_more_footer.dart';
import 'package:apphoctiengnnhat/shared/widgets/paged_list_view.dart';

final _items = List.generate(40, (index) => 'Mục $index');

Widget _host({required bool hasMore, required VoidCallback onLoadMore}) => MaterialApp(
      home: Scaffold(
        body: PagedListView<String>(
          items: _items,
          hasMore: hasMore,
          isLoadingMore: false,
          loadMoreError: null,
          onLoadMore: onLoadMore,
          itemBuilder: (context, item) => SizedBox(height: 60, child: Text(item)),
        ),
      ),
    );

void main() {
  testWidgets('cuộn gần cuối thì xin trang sau, ô cuối hiện vòng xoay', (tester) async {
    var loads = 0;
    await tester.pumpWidget(_host(hasMore: true, onLoadMore: () => loads++));

    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(loads, 0, reason: 'còn xa cuối danh sách');

    await tester.drag(find.byType(ListView), const Offset(0, -20000));
    await tester.pump(const Duration(seconds: 1));
    expect(loads, greaterThan(0));
    expect(find.byType(LoadMoreFooter), findsOneWidget);
  });

  testWidgets('hết trang thì không xin thêm và không có ô cuối', (tester) async {
    var loads = 0;
    await tester.pumpWidget(_host(hasMore: false, onLoadMore: () => loads++));

    await tester.drag(find.byType(ListView), const Offset(0, -20000));
    await tester.pumpAndSettle();

    expect(loads, 0);
    expect(find.byType(LoadMoreFooter), findsNothing);
    expect(find.text('Mục 39'), findsOneWidget);
  });
}
