import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:apphoctiengnnhat/core/network/api_client.dart';
import 'package:apphoctiengnnhat/core/state/view_state.dart';
import 'package:apphoctiengnnhat/features/search/models/search_result.dart';
import 'package:apphoctiengnnhat/features/search/providers/search_provider.dart';
import 'package:apphoctiengnnhat/features/search/services/search_service.dart';

/// Service giả: mỗi lần tìm là một `Completer` để test tự quyết thứ tự trả lời.
class _FakeSearchService extends SearchService {
  final calls = <String>[];
  final pending = <Completer<List<SearchResult>>>[];

  @override
  Future<List<SearchResult>> search(String query) {
    calls.add(query);
    final completer = Completer<List<SearchResult>>();
    pending.add(completer);
    return completer.future;
  }
}

SearchResult _result(String title) =>
    SearchResult(id: title, type: SearchResultType.vocabulary, title: title);

const _debounce = Duration(milliseconds: 300);

void main() {
  late _FakeSearchService service;
  late SearchProvider provider;

  setUp(() {
    service = _FakeSearchService();
    provider = SearchProvider(service: service);
  });

  List<String> titles() => provider.results.valueOrNull?.map((r) => r.title).toList() ?? const [];

  testWidgets('chờ 300 ms sau lần gõ cuối mới tìm, và chỉ tìm từ khoá cuối', (tester) async {
    provider.updateQuery('月');
    await tester.pump(const Duration(milliseconds: 200));
    provider.updateQuery('月曜');
    await tester.pump(const Duration(milliseconds: 299));
    expect(service.calls, isEmpty);

    await tester.pump(const Duration(milliseconds: 1));
    expect(service.calls, ['月曜']);
    expect(provider.results.isLoading, isTrue);

    service.pending.single.complete([_result('月曜日')]);
    await tester.pump();
    expect(titles(), ['月曜日']);
  });

  testWidgets('cắt khoảng trắng; ô chỉ có khoảng trắng không gửi request', (tester) async {
    provider.updateQuery('   ');
    await tester.pump(_debounce);
    expect(service.calls, isEmpty);
    expect(provider.query, '');
    expect(provider.results, isA<ViewIdle<List<SearchResult>>>());

    provider.updateQuery(' 月 ');
    await tester.pump(_debounce);
    service.pending.single.complete([_result('月')]);
    await tester.pump();

    provider.updateQuery('月  ');
    await tester.pump(_debounce);
    expect(service.calls, ['月'], reason: 'thêm khoảng trắng không đổi từ khoá, không tìm lại');
    expect(titles(), ['月']);
  });

  testWidgets('phản hồi của lần tìm cũ về sau không ghi đè lần tìm mới', (tester) async {
    provider.updateQuery('a');
    await tester.pump(_debounce);
    provider.updateQuery('ab');
    await tester.pump(_debounce);
    expect(service.calls, ['a', 'ab']);

    service.pending[1].complete([_result('ab')]);
    await tester.pump();
    service.pending[0].complete([_result('a')]);
    await tester.pump();

    expect(titles(), ['ab']);
  });

  testWidgets('xoá ô khi đang tải: kết quả về sau bị bỏ, ô trở về trạng thái chờ', (tester) async {
    provider.updateQuery('月');
    await tester.pump(_debounce);
    provider.clear();

    service.pending.single.complete([_result('月')]);
    await tester.pump();

    expect(provider.query, '');
    expect(provider.results, isA<ViewIdle<List<SearchResult>>>());
  });

  testWidgets('xoá ô trong lúc chờ gõ thì không gửi request nào', (tester) async {
    provider.updateQuery('月');
    await tester.pump(const Duration(milliseconds: 100));
    provider.clear();
    await tester.pump(_debounce);

    expect(service.calls, isEmpty);
  });

  testWidgets('lỗi API hiện thông báo; thử lại thì tìm lại đúng từ khoá', (tester) async {
    provider.updateQuery('月');
    await tester.pump(_debounce);
    service.pending.single.completeError(ApiException('Mất kết nối máy chủ'));
    await tester.pump();
    expect(provider.results.errorOrNull, 'Mất kết nối máy chủ');

    final retry = provider.retry();
    expect(service.calls, ['月', '月']);
    service.pending.last.completeError(StateError('lạ'));
    await retry;
    expect(provider.results.errorOrNull, 'Đã có lỗi xảy ra. Vui lòng thử lại.');
  });

  testWidgets('không có kết quả là danh sách rỗng, không phải lỗi', (tester) async {
    provider.updateQuery('không-tồn-tại');
    await tester.pump(_debounce);
    service.pending.single.complete(const []);
    await tester.pump();

    expect(provider.results.valueOrNull, isEmpty);
  });

  testWidgets('rời màn khi đang chờ gõ thì không gọi service', (tester) async {
    provider.updateQuery('月');
    provider.dispose();
    await tester.pump(_debounce);

    expect(service.calls, isEmpty);
  });
}
