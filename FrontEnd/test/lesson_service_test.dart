import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:apphoctiengnnhat/core/network/api_client.dart';
import 'package:apphoctiengnnhat/features/lessons/services/lesson_progress_service.dart';
import 'package:apphoctiengnnhat/features/lessons/services/lesson_service.dart';

http.Response _json(Object? body) => http.Response.bytes(utf8.encode(jsonEncode(body)), 200,
    headers: const {'content-type': 'application/json; charset=utf-8'});

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('danh sách bài là một trang; bộ lọc dựng bằng query an toàn', () async {
    late Uri url;
    final page = await http.runWithClient(
      () => LessonService().list(level: 'N5', situation: 'train', search: 'ga & tàu'),
      () => MockClient((request) async {
        url = request.url;
        return _json({
          'data': [
            {'_id': 'l1', 'title': 'Đi tàu', 'level': 'N5'},
          ],
          'page': 1,
          'limit': 20,
          'total': 21,
          'totalPages': 2,
        });
      }),
    );

    expect(url.queryParameters, {'page': '1', 'limit': '20', 'level': 'N5', 'situation': 'train', 'search': 'ga & tàu'});
    expect((page.items.single.title, page.hasMore), ('Đi tàu', true));
  });

  test('chủ đề đọc `{ data, total }`; chi tiết đọc `{ data }`', () async {
    final service = LessonService();
    final (situations, detail) = await http.runWithClient(
      () async => (await service.situations(level: 'N5'), await service.detail('l1')),
      () => MockClient((request) async => request.url.path.endsWith('/situations')
          ? _json({'data': ['bus', 'train'], 'total': 2})
          : _json({'data': {'_id': 'l1', 'title': 'Đi tàu', 'level': 'N5'}})),
    );

    expect(situations, ['bus', 'train']);
    expect(detail.lesson.title, 'Đi tàu');
  });

  test('tiến độ: chưa bắt đầu là `null`; lỗi mạng ném ra, không lặng lẽ thành `null`', () async {
    expect(
      await http.runWithClient(
        () => LessonProgressService().getProgress('l1'),
        () => MockClient((_) async => _json({'data': null})),
      ),
      isNull,
    );

    await expectLater(
      http.runWithClient(
        () => LessonProgressService().completeLesson('l1'),
        () => MockClient((_) async => http.Response.bytes(utf8.encode('{"message":"Máy chủ bận"}'), 503)),
      ),
      throwsA(isA<ApiException>()),
    );
  });
}
