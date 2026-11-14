import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:apphoctiengnnhat/core/network/api_client.dart';
import 'package:apphoctiengnnhat/core/network/api_envelope.dart';
import 'package:apphoctiengnnhat/core/state/paged_list.dart';
import 'package:apphoctiengnnhat/core/state/view_state.dart';

Paged<String> _page(List<String> items, {int page = 1, int totalPages = 1}) =>
    Paged(items: items, page: page, limit: items.length, total: items.length, totalPages: totalPages);

void main() {
  late int changes;
  late PagedList<String> list;
  late List<(String query, int page, Completer<Paged<String>>)> requests;

  Future<Paged<String>> Function(int page) fetcher(String query) => (page) {
        final reply = Completer<Paged<String>>();
        requests.add((query, page, reply));
        return reply.future;
      };

  setUp(() {
    changes = 0;
    requests = [];
    list = PagedList(onChanged: () => changes++);
  });

  test('trang đầu đi qua loading rồi data; lỗi là failure đọc được', () async {
    final loading = list.load(fetcher('a'));
    expect(list.state, isA<ViewLoading<List<String>>>());
    requests.single.$3.complete(_page(['x']));
    await loading;
    expect(list.state.valueOrNull, ['x']);
    expect(changes, 2);

    final failing = list.load(fetcher('a'));
    requests.last.$3.completeError(ApiException('Mất mạng'));
    await failing;
    expect(list.state.errorOrNull, 'Mất mạng');
  });

  test('phản hồi của truy vấn cũ về muộn không đè truy vấn mới', () async {
    final first = list.load(fetcher('cu'));
    final second = list.load(fetcher('moi'));
    requests[1].$3.complete(_page(['moi']));
    requests[0].$3.complete(_page(['cu']));
    await Future.wait([first, second]);

    expect(list.state.valueOrNull, ['moi']);
  });

  test('tải thêm nối trang sau bằng đúng truy vấn đang hiện; hết trang thì thôi', () async {
    final loading = list.load(fetcher('a'));
    requests.single.$3.complete(_page(['1'], totalPages: 2));
    await loading;

    final more = list.loadMore();
    expect(list.isLoadingMore, isTrue);
    await list.loadMore();
    expect(requests.length, 2, reason: 'đang tải thêm thì không gửi thêm yêu cầu');
    expect((requests.last.$1, requests.last.$2), ('a', 2));
    requests.last.$3.complete(_page(['2'], page: 2, totalPages: 2));
    await more;

    expect(list.state.valueOrNull, ['1', '2']);
    expect(list.hasMore, isFalse);
    await list.loadMore();
    expect(requests.length, 2);
  });

  test('tải thêm lỗi giữ danh sách và trang hiện có; thử lại đúng trang lỗi', () async {
    final loading = list.load(fetcher('a'));
    requests.single.$3.complete(_page(['1'], totalPages: 3));
    await loading;

    final failing = list.loadMore();
    requests.last.$3.completeError(ApiException('Mất mạng'));
    await failing;
    expect(list.loadMoreError, 'Mất mạng');
    expect(list.state.valueOrNull, ['1']);

    final retry = list.loadMore();
    expect(requests.last.$2, 2);
    requests.last.$3.complete(_page(['2'], page: 2, totalPages: 3));
    await retry;
    expect(list.loadMoreError, isNull);
  });

  test('đổi truy vấn giữa lúc tải thêm thì trang thêm về muộn bị bỏ', () async {
    final loading = list.load(fetcher('a'));
    requests.single.$3.complete(_page(['1'], totalPages: 2));
    await loading;

    final more = list.loadMore();
    final fresh = list.load(fetcher('b'));
    requests[2].$3.complete(_page(['b1']));
    requests[1].$3.complete(_page(['a2'], page: 2, totalPages: 2));
    await Future.wait([more, fresh]);

    expect(list.state.valueOrNull, ['b1']);
  });

  test('clear về trạng thái chưa tải và bỏ phản hồi đang chạy', () async {
    final loading = list.load(fetcher('a'));
    list.clear();
    requests.single.$3.complete(_page(['x']));
    await loading;

    expect(list.state, isA<ViewIdle<List<String>>>());
  });
}
