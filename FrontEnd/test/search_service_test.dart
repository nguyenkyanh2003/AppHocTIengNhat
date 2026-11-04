import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:apphoctiengnnhat/features/search/models/search_result.dart';
import 'package:apphoctiengnnhat/features/search/services/search_service.dart';

http.Response _json(Object body) => http.Response(jsonEncode(body), 200,
    headers: {'content-type': 'application/json; charset=utf-8'});

void main() {
  test('một request duy nhất, từ khoá có ký tự đặc biệt đến server nguyên vẹn', () async {
    const keywords = ['A&B', 'C++', '[', 'a#b', '50%', 'mặt trăng', '月'];
    final requests = <http.Request>[];

    await http.runWithClient(() async {
      for (final keyword in keywords) {
        await SearchService().search(keyword);
      }
    }, () => MockClient((request) async {
      requests.add(request);
      return _json({'data': [], 'total': 0});
    }));

    expect(requests.map((r) => '${r.method} ${r.url.path}').toSet(), {'GET /api/search'});
    expect(requests.map((r) => r.url.queryParameters['q']), keywords);
    expect(requests.map((r) => r.url.queryParameters['limit_per_type']).toSet(), {'5'});
  });

  test('đọc kết quả chung của mọi nhóm, Kanji lấy đúng chữ làm tiêu đề', () async {
    final results = await http.runWithClient(
      () => SearchService().search('月'),
      () => MockClient((_) async => _json({
            'data': [
              {'id': 'k1', 'type': 'kanji', 'title': '月', 'subtitle': 'Nguyệt', 'description': 'Mặt trăng',
                  'image_url': null, 'level': 'N5'},
              {'id': 'n1', 'type': 'news', 'title': '月の話', 'subtitle': null, 'description': null,
                  'image_url': 'https://img/n1.jpg', 'level': null},
            ],
            'total': 2,
          })),
    );

    expect(results.map((r) => (r.type, r.id, r.title)), [
      (SearchResultType.kanji, 'k1', '月'),
      (SearchResultType.news, 'n1', '月の話'),
    ]);
    expect(results.first.subtitle, 'Nguyệt');
    expect(results.first.level, 'N5');
    expect(results.last.imageUrl, 'https://img/n1.jpg');
    expect(results.last.description, isNull);
  });

  test('bỏ qua kết quả thuộc nhóm app chưa biết hoặc thiếu id', () {
    final results = SearchResult.listFromJson([
      {'id': 'v1', 'type': 'vocabulary', 'title': '月'},
      {'id': 'x1', 'type': 'video', 'title': 'Không mở được'},
      {'type': 'kanji', 'title': 'Thiếu id'},
    ]);

    expect(results.map((r) => r.id), ['v1']);
    expect(SearchResult.listFromJson(null), isEmpty);
  });

  test('lỗi server được ném ra để màn hình báo lỗi, không biến thành "không có kết quả"', () async {
    await http.runWithClient(() async {
      await expectLater(SearchService().search('月'), throwsA(anything));
    }, () => MockClient((_) async => http.Response(jsonEncode({'message': 'Lỗi máy chủ'}), 500)));
  });
}
