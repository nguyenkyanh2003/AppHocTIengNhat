import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:apphoctiengnnhat/core/network/api_client.dart';
import 'package:apphoctiengnnhat/core/state/view_state.dart';
import 'package:apphoctiengnnhat/shared/widgets/async_view.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void _bridgeTests() {
  group('ViewState.fromLegacy', () {
    ViewState<List<int>> bridge({bool loading = false, String? error, List<int>? value}) =>
        ViewState<List<int>>.fromLegacy(
          isLoading: loading,
          error: error,
          value: value,
          isEmpty: value?.isEmpty ?? true,
        );

    test('đang tải mà chưa có gì thì là loading', () {
      expect(bridge(loading: true, value: const []), isA<ViewLoading<List<int>>>());
    });

    test('lỗi mà chưa có gì thì là failure', () {
      expect(bridge(error: 'Mất mạng', value: const []).errorOrNull, 'Mất mạng');
    });

    test('tải xong rỗng thì là data rỗng, để AsyncView hiện trạng thái rỗng', () {
      expect(bridge(value: const []).valueOrNull, isEmpty);
    });

    test('đã có nội dung thì giữ nội dung khi tải lại hoặc tải lại lỗi', () {
      expect(bridge(loading: true, value: const [1]).valueOrNull, [1]);
      expect(bridge(error: 'Mất mạng', value: const [1]).valueOrNull, [1]);
    });

    test('chi tiết chưa tải xong (value null) không coi là rỗng', () {
      expect(bridge(), isA<ViewIdle<List<int>>>());
    });
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
  _bridgeTests();

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
