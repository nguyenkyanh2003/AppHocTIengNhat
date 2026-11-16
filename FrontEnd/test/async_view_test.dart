import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:apphoctiengnnhat/core/network/api_client.dart';
import 'package:apphoctiengnnhat/core/state/view_state.dart';
import 'package:apphoctiengnnhat/shared/widgets/async_view.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void _viewStateTests() {
  test('map đổi dữ liệu bên trong, giữ nguyên trạng thái tải và lỗi', () {
    expect(const ViewState<int>.data(2).map((value) => '$value').valueOrNull, '2');
    expect(const ViewState<int>.failure('Hỏng').map((value) => '$value').errorOrNull, 'Hỏng');
    expect(const ViewState<int>.loading().map((value) => '$value'), isA<ViewLoading<String>>());
    expect(const ViewState<int>.idle().map((value) => '$value'), isA<ViewIdle<String>>());
  });

  group('userMessageOf', () {
    test('lỗi API giữ câu của server, lỗi khác không lộ chi tiết', () {
      expect(userMessageOf(ApiException('Không có quyền')), 'Không có quyền');
      expect(userMessageOf(TypeError()), isNot(contains('TypeError')));
    });
  });
}

AsyncView<List<String>> _view(
  ViewState<List<String>> state, {
  Future<void> Function()? onRetry,
}) =>
    AsyncView<List<String>>(
      state: state,
      onRetry: onRetry,
      isEmpty: (items) => items.isEmpty,
      emptyTitle: 'Chưa có gì',
      builder: (context, items) => Column(
        children: items.map(Text.new).toList(),
      ),
    );

void main() {
  _viewStateTests();

  testWidgets('trạng thái idle hiển thị vòng quay chờ', (tester) async {
    await tester.pumpWidget(_host(_view(const ViewState.idle())));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('trạng thái loading hiển thị vòng quay chờ', (tester) async {
    await tester.pumpWidget(_host(_view(const ViewState.loading())));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('có dữ liệu thì dựng nội dung', (tester) async {
    await tester.pumpWidget(
      _host(_view(const ViewState.data(['một', 'hai']))),
    );

    expect(find.text('một'), findsOneWidget);
    expect(find.text('hai'), findsOneWidget);
  });

  testWidgets('dữ liệu rỗng hiển thị trạng thái rỗng, không phải lỗi',
      (tester) async {
    await tester.pumpWidget(_host(_view(const ViewState.data([]))));

    expect(find.text('Chưa có gì'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('lỗi hiển thị thông báo kèm nút thử lại', (tester) async {
    var retried = 0;

    await tester.pumpWidget(
      _host(
        _view(
          const ViewState.failure('Mất kết nối'),
          onRetry: () async => retried++,
        ),
      ),
    );

    expect(find.text('Mất kết nối'), findsOneWidget);

    await tester.tap(find.text('Thử lại'));
    await tester.pump();

    expect(retried, 1);
  });

  testWidgets('lỗi không có onRetry thì không hiện nút thử lại',
      (tester) async {
    await tester.pumpWidget(_host(_view(const ViewState.failure('Hỏng'))));

    expect(find.text('Hỏng'), findsOneWidget);
    expect(find.text('Thử lại'), findsNothing);
  });
}
