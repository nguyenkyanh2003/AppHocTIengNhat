import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:apphoctiengnnhat/core/network/api_client.dart';
import 'package:apphoctiengnnhat/core/network/api_envelope.dart';
import 'package:apphoctiengnnhat/features/news/models/news.dart';
import 'package:apphoctiengnnhat/features/news/providers/news_provider.dart';
import 'package:apphoctiengnnhat/features/news/services/news_service.dart';

News _news(String id) => News(
      id: id,
      title: 'Tin $id',
      description: '',
      contentHtml: '',
      views: 0,
      createdAt: DateTime(2026, 9, 1),
    );

class _FakeService implements NewsService {
  final listCalls = <({int page, String? level, String? search})>[];
  Object? relatedFailure;
  Completer<News>? pendingDetail;

  @override
  Future<Paged<News>> list({int page = 1, int limit = NewsService.pageSize, String? level, String? search}) async {
    listCalls.add((page: page, level: level, search: search));
    return Paged(items: [_news('p$page')], page: page, limit: limit, total: 2, totalPages: 2);
  }

  @override
  Future<News> detail(String id) => pendingDetail?.future ?? Future.value(_news(id));

  @override
  Future<List<News>> related(String id, {int limit = 5}) async {
    if (relatedFailure != null) throw relatedFailure!;
    return [_news('lien-quan')];
  }
}

void main() {
  late _FakeService service;
  late NewsProvider provider;

  setUp(() {
    service = _FakeService();
    provider = NewsProvider(service: service);
  });

  test('tải theo bộ lọc rồi tải thêm đúng bộ lọc đó; làm mới giữ bộ lọc', () async {
    await provider.load(level: 'N4', search: 'nhật');
    await provider.loadMore();
    await provider.refresh();

    expect(service.listCalls, [
      (page: 1, level: 'N4', search: 'nhật'),
      (page: 2, level: 'N4', search: 'nhật'),
      (page: 1, level: 'N4', search: 'nhật'),
    ]);
    expect(provider.newsList.map((news) => news.id), ['p1']);
  });

  test('chi tiết hiện ngay; tin liên quan tải hỏng thì khối đó ẩn, bài vẫn đọc được', () async {
    service.relatedFailure = ApiException('Mất mạng');

    await provider.loadDetail('n1');

    expect(provider.detailState.valueOrNull?.id, 'n1');
    expect(provider.related, isEmpty);
  });

  test('mở bài khác giữa chừng: bài cũ về muộn không đè bài mới', () async {
    final slow = Completer<News>();
    service.pendingDetail = slow;
    final first = provider.loadDetail('cu');
    service.pendingDetail = null;
    await provider.loadDetail('moi');
    slow.complete(_news('cu'));
    await first;

    expect(provider.detailState.valueOrNull?.id, 'moi');
    expect(provider.related.single.id, 'lien-quan');
  });

  test('đánh dấu yêu thích bật tắt và chỉ giữ trong phiên', () {
    provider.toggleBookmark('n1');
    expect(provider.isBookmarked('n1'), isTrue);
    provider.toggleBookmark('n1');
    expect(provider.isBookmarked('n1'), isFalse);
  });
}
