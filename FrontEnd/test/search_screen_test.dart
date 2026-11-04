import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:apphoctiengnnhat/app/theme/app_theme.dart';
import 'package:apphoctiengnnhat/core/network/api_client.dart';
import 'package:apphoctiengnnhat/features/search/models/search_result.dart';
import 'package:apphoctiengnnhat/features/search/screens/search_screen.dart';
import 'package:apphoctiengnnhat/features/search/services/search_service.dart';
import 'package:apphoctiengnnhat/features/search/widgets/search_result_list.dart';

class _FakeSearchService extends SearchService {
  _FakeSearchService([this.answer = _all]);

  final List<SearchResult> Function(String query) answer;
  final calls = <String>[];

  @override
  Future<List<SearchResult>> search(String query) async {
    calls.add(query);
    return answer(query);
  }
}

const _results = [
  SearchResult(id: 'v1', type: SearchResultType.vocabulary, title: '月', subtitle: 'つき', description: 'Mặt trăng', level: 'N5'),
  SearchResult(id: 'k1', type: SearchResultType.kanji, title: '月', subtitle: 'Nguyệt', description: 'Mặt trăng, tháng'),
  SearchResult(id: 'l1', type: SearchResultType.lesson, title: 'Tình huống: Ngắm trăng'),
  SearchResult(id: 'g1', type: SearchResultType.grammar, title: '〜月に', subtitle: 'N + に'),
  SearchResult(id: 'n1', type: SearchResultType.news, title: '月の話'),
];

List<SearchResult> _all(String _) => _results;

/// Màn tìm kiếm qua GoRouter thật; mỗi màn chi tiết chỉ in ra đường dẫn đã mở.
Widget _app(SearchService service) {
  final router = GoRouter(
    initialLocation: '/search',
    routes: [
      GoRoute(path: '/search', builder: (context, state) => SearchScreen(service: service)),
      for (final path in ['/vocabulary/:id', '/kanji/:id', '/lessons/:id', '/grammar/:id', '/news/:id'])
        GoRoute(path: path, builder: (context, state) => Scaffold(body: Text('mở ${state.uri.path}'))),
    ],
  );
  return MaterialApp.router(theme: AppTheme.lightTheme, routerConfig: router);
}

Future<void> _search(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('ô trống hiện hướng dẫn; gõ xong thì hiện kết quả chia theo nhóm', (tester) async {
    final service = _FakeSearchService();
    await tester.pumpWidget(_app(service));
    expect(find.text('Tìm trong toàn bộ nội dung'), findsOneWidget);

    await _search(tester, '月');

    expect(service.calls, ['月']);
    for (final label in ['Từ vựng', 'Kanji', 'Bài học', 'Ngữ pháp']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('Tình huống: Ngắm trăng'), findsOneWidget);
    expect(find.text('Nguyệt · Mặt trăng, tháng'), findsOneWidget);
  });

  testWidgets('cả năm loại kết quả đều mở đúng màn chi tiết', (tester) async {
    const expected = {
      'vocabulary-v1': '/vocabulary/v1',
      'kanji-k1': '/kanji/k1',
      'lesson-l1': '/lessons/l1',
      'grammar-g1': '/grammar/g1',
      'news-n1': '/news/n1',
    };

    for (final MapEntry(key: key, value: path) in expected.entries) {
      await tester.pumpWidget(_app(_FakeSearchService()));
      await _search(tester, '月');

      final tile = find.byKey(ValueKey('search-result-$key'));
      await tester.scrollUntilVisible(tile, 200,
          scrollable: find.descendant(of: find.byType(SearchResultList), matching: find.byType(Scrollable)));
      await tester.ensureVisible(tile);
      await tester.pumpAndSettle();
      await tester.tap(tile);
      await tester.pumpAndSettle();

      expect(find.text('mở $path'), findsOneWidget, reason: key);
    }
  });

  testWidgets('không có kết quả thì báo rõ, không phải lỗi', (tester) async {
    await tester.pumpWidget(_app(_FakeSearchService((_) => const [])));
    await _search(tester, 'không-tồn-tại');

    expect(find.text('Không tìm thấy kết quả'), findsOneWidget);
    expect(find.textContaining('không-tồn-tại'), findsWidgets);
  });

  testWidgets('lỗi hiện thông báo kèm nút thử lại', (tester) async {
    var failing = true;
    final service = _FakeSearchService((_) => failing ? throw ApiException('Mất kết nối máy chủ') : _results);
    await tester.pumpWidget(_app(service));
    await _search(tester, '月');
    expect(find.text('Mất kết nối máy chủ'), findsOneWidget);

    failing = false;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();

    expect(service.calls, ['月', '月']);
    expect(find.text('Tình huống: Ngắm trăng'), findsOneWidget);
  });

  testWidgets('nút xoá đưa ô về trạng thái chờ', (tester) async {
    await tester.pumpWidget(_app(_FakeSearchService()));
    await _search(tester, '月');

    await tester.tap(find.byTooltip('Xoá từ khoá'));
    await tester.pumpAndSettle();

    expect(find.text('Tìm trong toàn bộ nội dung'), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, isEmpty);
  });
}
