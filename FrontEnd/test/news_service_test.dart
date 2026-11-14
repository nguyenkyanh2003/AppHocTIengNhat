import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:apphoctiengnnhat/core/network/api_client.dart';
import 'package:apphoctiengnnhat/features/news/services/news_service.dart';

http.Response _json(Object body) => http.Response.bytes(utf8.encode(jsonEncode(body)), 200,
    headers: const {'content-type': 'application/json; charset=utf-8'});

const _news = {
  '_id': 'n1',
  'title': '日本語の勉強',
  'description': 'Mẹo học',
  'content_html': '<p>本文</p>',
  'image_url': '/uploads/news/a.jpg',
  'level': 'N4',
  'views': 3,
  'createdAt': '2026-09-01T00:00:00.000Z',
};

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('một trang tin: query dựng bằng Uri, từ khoá có dấu cách vẫn đúng; ảnh thành địa chỉ đầy đủ', () async {
    late Uri url;
    final page = await http.runWithClient(
      () => NewsService().list(page: 2, level: 'N4', search: 'nhật bản'),
      () => MockClient((request) async {
        url = request.url;
        return _json({'data': [_news], 'page': 2, 'limit': 10, 'total': 11, 'totalPages': 2});
      }),
    );

    expect(url.path, '/api/news');
    expect(url.queryParameters, {'page': '2', 'limit': '10', 'level': 'N4', 'search': 'nhật bản'});
    expect((page.total, page.hasMore), (11, false));
    expect(page.items.single.imageUrl, endsWith('/uploads/news/a.jpg'));
    expect(page.items.single.imageUrl, startsWith('http'));
  });

  test('chi tiết và tin liên quan bóc `data`; thiếu `data` là lỗi rõ ràng', () async {
    final client = MockClient((request) async => request.url.path.endsWith('/related')
        ? _json({'data': [_news], 'total': 1})
        : _json({'data': _news}));

    final detail = await http.runWithClient(() => NewsService().detail('n1'), () => client);
    final related = await http.runWithClient(() => NewsService().related('n1'), () => client);
    expect((detail.id, related.single.title), ('n1', '日本語の勉強'));

    await expectLater(
      http.runWithClient(() => NewsService().detail('n1'), () => MockClient((_) async => _json(_news))),
      throwsA(isA<ServerException>()),
    );
  });
}
