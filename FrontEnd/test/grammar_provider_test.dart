import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:apphoctiengnnhat/core/network/api_client.dart';
import 'package:apphoctiengnnhat/core/network/api_envelope.dart';
import 'package:apphoctiengnnhat/features/grammar/models/grammar.dart';
import 'package:apphoctiengnnhat/features/grammar/providers/grammar_provider.dart';
import 'package:apphoctiengnnhat/features/grammar/services/grammar_service.dart';

Grammar _grammar(String id) => Grammar(id: id, title: 'Ngữ pháp $id', pattern: 'N + $id', meaning: 'nghĩa', level: 'N5');

Paged<Grammar> _page(List<String> ids, {int page = 1, int totalPages = 1}) =>
    Paged(items: ids.map(_grammar).toList(), page: page, limit: ids.length, total: ids.length, totalPages: totalPages);

/// Service giả: mỗi lời gọi chờ một Completer để test quyết định thứ tự phản hồi.
class _FakeService implements GrammarService {
  final listCalls = <({int page, String? level, String? search, GrammarSort sort})>[];
  final listReplies = <Completer<Paged<Grammar>>>[];
  Object? detailFailure;

  @override
  Future<Paged<Grammar>> list({int page = 1, int limit = GrammarService.pageSize, String? level, String? search, GrammarSort sort = GrammarSort.title}) {
    listCalls.add((page: page, level: level, search: search, sort: sort));
    final reply = Completer<Paged<Grammar>>();
    listReplies.add(reply);
    return reply.future;
  }

  @override
  Future<Grammar> detail(String id) async {
    if (detailFailure != null) throw detailFailure!;
    return _grammar(id);
  }
}

void main() {
  late _FakeService service;
  late GrammarProvider provider;

  setUp(() {
    service = _FakeService();
    provider = GrammarProvider(service: service);
  });

  test('tải danh sách theo bộ lọc; thành công là dữ liệu, lỗi API là câu báo đọc được', () async {
    final loading = provider.load(level: 'N4', sort: GrammarSort.newest);
    expect(provider.listState.isLoading, isTrue);
    service.listReplies.single.complete(_page(['a', 'b']));
    await loading;

    expect(service.listCalls.single, (page: 1, level: 'N4', search: null, sort: GrammarSort.newest));
    expect(provider.listState.valueOrNull?.map((grammar) => grammar.id), ['a', 'b']);

    final failing = provider.load(level: 'N4');
    service.listReplies.last.completeError(ApiException('Máy chủ đang bận'));
    await failing;
    expect(provider.listState.errorOrNull, 'Máy chủ đang bận');
  });

  test('gõ nhanh nhiều từ khoá: phản hồi của từ khoá cũ về muộn không đè kết quả mới', () async {
    final first = provider.load(search: 'が');
    final second = provider.load(search: 'がは');
    service.listReplies[1].complete(_page(['moi']));
    service.listReplies[0].complete(_page(['cu']));
    await Future.wait([first, second]);

    expect(provider.listState.valueOrNull?.single.id, 'moi');
  });

  test('tải thêm nối trang sau vào danh sách, giữ nguyên bộ lọc; lỗi tải thêm không xoá danh sách đang có', () async {
    final loading = provider.load(level: 'N5');
    service.listReplies.single.complete(_page(['a'], totalPages: 3));
    await loading;
    expect(provider.hasMore, isTrue);

    final more = provider.loadMore();
    expect(provider.isLoadingMore, isTrue);
    service.listReplies.last.complete(_page(['b'], page: 2, totalPages: 3));
    await more;
    expect(service.listCalls.last.page, 2);
    expect(service.listCalls.last.level, 'N5');
    expect(provider.listState.valueOrNull?.map((grammar) => grammar.id), ['a', 'b']);

    final failing = provider.loadMore();
    service.listReplies.last.completeError(ApiException('Mất mạng'));
    await failing;
    expect(provider.loadMoreError, 'Mất mạng');
    expect(provider.listState.valueOrNull?.length, 2);
  });

  test('chi tiết: thành công là ngữ pháp, lỗi là câu báo kèm nút thử lại', () async {
    await provider.loadDetail('g1');
    expect(provider.detailState.valueOrNull?.id, 'g1');

    service.detailFailure = ApiException('Ngữ pháp không tồn tại.');
    await provider.loadDetail('g2');
    expect(provider.detailState.errorOrNull, 'Ngữ pháp không tồn tại.');
  });
}
