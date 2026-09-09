import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:apphoctiengnnhat/core/state/view_state.dart';
import 'package:apphoctiengnnhat/features/vocabulary/models/vocabulary.dart';
import 'package:apphoctiengnnhat/features/vocabulary/widgets/vocabulary_list_view.dart';

Vocabulary _word(int index) => Vocabulary(
      id: '$index',
      word: 'word-$index',
      hiragana: 'kana-$index',
      meaning: 'nghĩa $index',
      level: 'N5',
    );

final _items = List.generate(40, _word);

Widget _host({
  required bool isLoadingMore,
  String? loadMoreError,
  VoidCallback? onLoadMore,
}) {
  return MaterialApp(
    home: Scaffold(
      body: VocabularyListView(
        state: ViewState.data(_items),
        hasNextPage: true,
        isLoadingMore: isLoadingMore,
        loadMoreError: loadMoreError,
        onRefresh: () async {},
        onLoadMore: () async => onLoadMore?.call(),
        onOpen: (_) {},
      ),
    ),
  );
}

double _scrollOffset(WidgetTester tester) => tester
    .state<ScrollableState>(find.byType(Scrollable).first)
    .position
    .pixels;

void main() {
  testWidgets('bắt đầu tải thêm không tháo danh sách và giữ vị trí cuộn',
      (tester) async {
    await tester.pumpWidget(_host(isLoadingMore: false));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();

    final offsetBeforeLoading = _scrollOffset(tester);
    expect(offsetBeforeLoading, greaterThan(0));

    // Chuyển sang trạng thái đang tải thêm: danh sách phải còn nguyên tại chỗ.
    await tester.pumpWidget(_host(isLoadingMore: true));
    await tester.pump();

    expect(find.byType(ListView), findsOneWidget);
    expect(_scrollOffset(tester), offsetBeforeLoading);

    // Kết thúc tải thêm cũng không được đưa người dùng về đầu danh sách.
    await tester.pumpWidget(_host(isLoadingMore: false));
    await tester.pump();

    expect(_scrollOffset(tester), offsetBeforeLoading);
  });

  testWidgets('trạng thái loading toàn màn hình mới là thứ tháo danh sách',
      (tester) async {
    await tester.pumpWidget(_host(isLoadingMore: false));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(_scrollOffset(tester), greaterThan(0));

    // Đây là hành vi cũ mà bản sửa loại bỏ, giữ lại làm mốc so sánh.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VocabularyListView(
            state: const ViewState.loading(),
            hasNextPage: true,
            onRefresh: () async {},
            onLoadMore: () async {},
            onOpen: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(ListView), findsNothing);
  });

  testWidgets('lỗi tải thêm hiện ở cuối danh sách kèm nút thử lại',
      (tester) async {
    var retries = 0;

    await tester.pumpWidget(
      _host(
        isLoadingMore: false,
        loadMoreError: 'Mất kết nối',
        onLoadMore: () => retries++,
      ),
    );
    await tester.pumpAndSettle();

    // Danh sách vẫn còn, lỗi chỉ nằm ở cuối.
    expect(find.byType(ListView), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -20000));
    await tester.pumpAndSettle();

    expect(find.text('Mất kết nối'), findsOneWidget);

    // Cuộn tới cuối cũng phát tín hiệu tải thêm, nên chỉ tính phần chênh lệch
    // do thao tác bấm "Thử lại" gây ra.
    final beforeTap = retries;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();

    expect(retries, beforeTap + 1);
  });
}
