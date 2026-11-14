import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:apphoctiengnnhat/core/network/api_client.dart';
import 'package:apphoctiengnnhat/features/grammar/models/grammar.dart';
import 'package:apphoctiengnnhat/features/grammar/services/grammar_service.dart';

http.Response _json(Object body) => http.Response.bytes(utf8.encode(jsonEncode(body)), 200,
    headers: const {'content-type': 'application/json; charset=utf-8'});

/// Đúng hình dạng backend trả: bài học được populate thành object.
const _grammar = {
  '_id': 'g1',
  'title': 'が (ga)',
  'structure': 'N + が',
  'meaning': 'Trợ từ chỉ chủ ngữ',
  'level': 'N5',
  'lesson_id': {'_id': 'l1', 'title': 'Tự giới thiệu', 'level': 'N5'},
  'examples': [
    {'sentence': '誰が来ましたか。', 'meaning': 'Ai đã đến?'},
  ],
  'view_count': 4,
};

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('một trang ngữ pháp: query dựng bằng Uri, bỏ tham số trống; đọc đủ thông tin trang', () async {
    late Uri url;
    final page = await http.runWithClient(
      () => GrammarService().list(page: 2, level: 'N5', search: 'が は', sort: GrammarSort.popular),
      () => MockClient((request) async {
        url = request.url;
        return _json({'data': [_grammar], 'page': 2, 'limit': 20, 'total': 21, 'totalPages': 2});
      }),
    );

    expect(url.path, '/api/grammar');
    expect(url.queryParameters, {'page': '2', 'limit': '20', 'level': 'N5', 'search': 'が は', 'sortBy': 'popular'});
    expect((page.page, page.total, page.hasMore), (2, 21, false));

    final grammar = page.items.single;
    expect((grammar.id, grammar.pattern, grammar.lessonId, grammar.viewCount), ('g1', 'N + が', 'l1', 4));
    expect(grammar.examples, ['誰が来ましたか。\nAi đã đến?']);
  });

  test('chi tiết bóc `data`; response thiếu `data` là lỗi rõ ràng chứ không phải ngữ pháp rỗng', () async {
    final grammar = await http.runWithClient(
      () => GrammarService().detail('g1'),
      () => MockClient((request) async {
        expect(request.url.path, '/api/grammar/g1');
        return _json({'data': _grammar});
      }),
    );
    expect(grammar.title, 'が (ga)');

    await expectLater(
      http.runWithClient(() => GrammarService().detail('g1'), () => MockClient((_) async => _json(_grammar))),
      throwsA(isA<ServerException>()),
    );
  });
}
