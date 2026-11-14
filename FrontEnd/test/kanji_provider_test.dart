import 'package:flutter_test/flutter_test.dart';

import 'package:apphoctiengnnhat/core/network/api_client.dart';
import 'package:apphoctiengnnhat/core/network/api_envelope.dart';
import 'package:apphoctiengnnhat/core/state/view_state.dart';
import 'package:apphoctiengnnhat/features/kanji/models/kanji.dart';
import 'package:apphoctiengnnhat/features/kanji/providers/kanji_provider.dart';
import 'package:apphoctiengnnhat/features/kanji/services/kanji_service.dart';

class _FakeService extends KanjiService {
  final calls = <String>[];
  Object? failure;
  int totalPages = 1;

  @override
  Future<Paged<Kanji>> list({int page = 1, int limit = KanjiService.pageSize, String? level}) async {
    calls.add('list $page ${level ?? '*'}');
    if (failure != null) throw failure!;
    return Paged(items: [Kanji(id: 'p$page', character: '字')], page: page, limit: limit, total: 2, totalPages: totalPages);
  }

  @override
  Future<List<Kanji>> search(String keyword, {String? level}) async {
    calls.add('search $keyword ${level ?? '*'}');
    if (failure != null) throw failure!;
    return const [Kanji(id: 's1', character: '学')];
  }
}

void main() {
  late _FakeService service;
  late KanjiProvider provider;

  setUp(() {
    service = _FakeService();
    provider = KanjiProvider(service: service);
  });

  test('tải danh sách qua ViewState; chọn cấp độ tải lại từ trang đầu', () async {
    await provider.loadKanjis();
    await provider.filterByLevel('N4');

    expect(service.calls, ['list 1 *', 'list 1 N4']);
    expect(provider.kanjis.valueOrNull?.single.id, 'p1');
    expect(provider.selectedLevel, 'N4');
  });

  test('tải thêm nối trang sau vào danh sách đang có', () async {
    service.totalPages = 2;
    await provider.loadKanjis();

    await provider.loadMore();

    expect(provider.kanjis.valueOrNull?.map((kanji) => kanji.id), ['p1', 'p2']);
    expect(provider.hasMore, isFalse);
  });

  test('tìm trong cấp độ đang chọn, không có trang sau; xoá từ khoá thì về danh sách', () async {
    await provider.filterByLevel('N5');
    await provider.search('  学 ');

    expect(service.calls.last, 'search 学 N5');
    expect((provider.searchQuery, provider.hasMore), ('学', false));
    expect(provider.kanjis.valueOrNull?.single.id, 's1');

    await provider.search('');
    expect(service.calls.last, 'list 1 N5');
  });

  test('lỗi API hiện thành ViewFailure đọc được', () async {
    service.failure = ApiException('Mất kết nối');

    await provider.loadKanjis();

    expect(provider.kanjis.errorOrNull, 'Mất kết nối');
  });

  test('đăng xuất xoá sạch danh sách và bộ lọc', () async {
    await provider.filterByLevel('N3');
    await provider.search('学');

    provider.clear();

    expect(provider.kanjis, isA<ViewIdle<List<Kanji>>>());
    expect((provider.selectedLevel, provider.searchQuery), (null, ''));
  });
}
