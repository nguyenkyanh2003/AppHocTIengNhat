import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:apphoctiengnnhat/core/network/api_client.dart';
import 'package:apphoctiengnnhat/core/state/detail_state.dart';
import 'package:apphoctiengnnhat/core/state/view_state.dart';

typedef _Item = ({String id, String name});

void main() {
  late int changes;
  late DetailState<_Item> detail;

  setUp(() {
    changes = 0;
    detail = DetailState(idOf: (item) => item.id, onChanged: () => changes++);
  });

  test('tải đi qua loading rồi data; lỗi là failure đọc được', () async {
    final pending = detail.load('a', () async => (id: 'a', name: 'A'));
    expect(detail.of('a').isLoading, isTrue);
    await pending;
    expect(detail.of('a').valueOrNull?.name, 'A');

    await detail.load('b', () async => throw ApiException('Mất kết nối'));
    expect(detail.of('b').errorOrNull, 'Mất kết nối');
    expect(changes, 4);
  });

  test('dữ liệu của mục mở trước coi như đang tải khi hỏi một mục khác', () async {
    await detail.load('a', () async => (id: 'a', name: 'A'));

    expect(detail.of('b').isLoading, isTrue);
    expect(detail.of('a').hasData, isTrue);
  });

  test('phản hồi của lần tải cũ về muộn không đè lên mục đang mở', () async {
    final slow = Completer<_Item>();
    final first = detail.load('a', () => slow.future);
    await detail.load('b', () async => (id: 'b', name: 'B'));

    slow.complete((id: 'a', name: 'A cũ'));
    await first;

    expect(detail.of('b').valueOrNull?.name, 'B');
  });

  test('bản server trả sau khi ghi chỉ thay mục đang mở; xoá mục đang mở về idle', () async {
    await detail.load('a', () async => (id: 'a', name: 'A'));

    detail.replace((id: 'x', name: 'mục khác'));
    expect(detail.of('a').valueOrNull?.name, 'A');

    detail.replace((id: 'a', name: 'A mới'));
    expect(detail.of('a').valueOrNull?.name, 'A mới');

    detail.remove('x');
    expect(detail.state.hasData, isTrue);
    detail.remove('a');
    expect(detail.state, isA<ViewIdle<_Item>>());
  });

  test('clear bỏ cả phản hồi đang chạy', () async {
    final slow = Completer<_Item>();
    final pending = detail.load('a', () => slow.future);

    detail.clear();
    slow.complete((id: 'a', name: 'A'));
    await pending;

    expect(detail.state, isA<ViewIdle<_Item>>());
  });
}
