import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:apphoctiengnnhat/core/network/api_client.dart';
import 'package:apphoctiengnnhat/features/kanji/services/kanji_service.dart';

http.Response _json(Object body) => http.Response.bytes(utf8.encode(jsonEncode(body)), 200,
    headers: const {'content-type': 'application/json; charset=utf-8'});

const _kanji = {
  '_id': 'k1',
  'character': '学',
  'hanviet': 'HỌC',
  'onyomi': ['ガク'],
  'kunyomi': ['まな.ぶ'],
  'meaning': 'học',
  'level': 'N5',
  'createdAt': '2026-11-14T03:00:00.000Z',
};

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('danh sách là một trang theo contract phân trang, lọc bằng `level`', () async {
    late Uri url;
    final page = await http.runWithClient(
      () => KanjiService().list(page: 2, level: 'N5'),
      () => MockClient((request) async {
        url = request.url;
        return _json({'data': [_kanji], 'page': 2, 'limit': 20, 'total': 21, 'totalPages': 2});
      }),
    );

    expect(url.path, '/api/kanji');
    expect(url.queryParameters, {'page': '2', 'limit': '20', 'level': 'N5'});
    expect((page.items.single.character, page.items.single.hanviet, page.hasMore), ('学', 'HỌC', false));
  });

  test('tìm kiếm đọc `{ data, total }`, từ khoá được mã hoá an toàn trong query', () async {
    late Uri url;
    final results = await http.runWithClient(
      () => KanjiService().search('gaku & 学', level: 'N4'),
      () => MockClient((request) async {
        url = request.url;
        return _json({'data': [_kanji], 'total': 1});
      }),
    );

    expect(url.path, '/api/kanji/search');
    expect(url.queryParameters, {'keyword': 'gaku & 学', 'level': 'N4'});
    expect(results.single.id, 'k1');
  });

  test('response thiếu `data` là lỗi rõ ràng, không phải danh sách rỗng âm thầm', () async {
    await expectLater(
      http.runWithClient(() => KanjiService().search('学'), () => MockClient((_) async => _json([_kanji]))),
      throwsA(isA<ServerException>()),
    );
  });
}
