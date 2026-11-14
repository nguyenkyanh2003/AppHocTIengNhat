import 'package:flutter_test/flutter_test.dart';

import 'package:apphoctiengnnhat/core/network/api_client.dart';
import 'package:apphoctiengnnhat/core/network/api_envelope.dart';

class _Item {
  const _Item(this.name);

  factory _Item.fromJson(Map<String, dynamic> json) => _Item(json['name'] as String);

  final String name;
}

void main() {
  test('dataOf bóc `data`; giá trị null hợp lệ vẫn là null', () {
    expect(dataOf({'data': 3, 'message': 'ok'}), 3);
    expect(dataOf({'data': null}), isNull);
  });

  test('response không có khoá `data` là lỗi máy chủ rõ ràng, không lặng lẽ thành rỗng', () {
    for (final response in [null, 'chuỗi', <dynamic>[], {'items': <dynamic>[]}]) {
      expect(() => dataOf(response), throwsA(isA<ServerException>()), reason: '$response');
    }
  });

  test('objectOf và listOf dựng model từ `data`', () {
    expect(objectOf({'data': {'name': 'a'}}, _Item.fromJson).name, 'a');
    expect(listOf({'data': [{'name': 'a'}, {'name': 'b'}], 'total': 2}, _Item.fromJson).map((item) => item.name), ['a', 'b']);
    expect(listOf({'data': <dynamic>[]}, _Item.fromJson), isEmpty);
  });

  test('`data` sai kiểu (danh sách thay cho object và ngược lại) cũng là lỗi máy chủ', () {
    expect(() => objectOf({'data': <dynamic>[]}, _Item.fromJson), throwsA(isA<ServerException>()));
    expect(() => listOf({'data': {'name': 'a'}}, _Item.fromJson), throwsA(isA<ServerException>()));
  });

  test('Paged đọc một trang và biết còn trang sau hay không', () {
    final page = Paged.fromJson(
      {'data': [{'name': 'a'}], 'page': 2, 'limit': 1, 'total': 3, 'totalPages': 3},
      _Item.fromJson,
    );

    expect((page.items.single.name, page.page, page.limit, page.total, page.totalPages), ('a', 2, 1, 3, 3));
    expect(page.hasMore, isTrue);
    expect(Paged.fromJson({'data': <dynamic>[], 'page': 1, 'limit': 20, 'total': 0, 'totalPages': 0}, _Item.fromJson).hasMore, isFalse);
  });
}
