import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:apphoctiengnnhat/core/state/view_state.dart';
import 'package:apphoctiengnnhat/features/lessons/providers/lesson_provider.dart';

/// Backend giả cho `GET /lesson/:id`: đếm request theo bài, cho phép trễ hoặc
/// lỗi theo từng bài để dựng lại cảnh mạng chậm và mạng rớt.
class _Backend {
  final requests = <String, int>{};
  final delays = <String, Duration>{};
  final failing = <String>{};

  MockClient get client => MockClient((request) async {
        final id = request.url.pathSegments.last;
        requests[id] = (requests[id] ?? 0) + 1;
        await Future<void>.delayed(delays[id] ?? Duration.zero);
        if (failing.contains(id)) return http.Response('{"message":"lỗi"}', 500);
        return http.Response(
          jsonEncode({'_id': id, 'title': 'Bài $id', 'level': 'N5'}),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('mở lại bài đã xem hiện ngay từ bộ nhớ, rồi mới làm mới từ server', () async {
    final backend = _Backend();
    await http.runWithClient(() async {
      final provider = LessonProvider();
      await provider.loadLessonDetail('a');
      await provider.loadLessonDetail('b');

      final reopening = provider.loadLessonDetail('a');
      // Chưa chờ mạng mà đã có nội dung: không vòng xoay.
      expect(provider.currentLessonDetail?.lesson.id, 'a');
      expect(provider.detailState, isA<ViewData>());

      await reopening;
      expect(backend.requests['a'], 2);
    }, () => backend.client);
  });

  test('response về muộn của bài mở trước không đè bài đang xem', () async {
    final backend = _Backend()..delays['a'] = const Duration(milliseconds: 50);
    await http.runWithClient(() async {
      final provider = LessonProvider();
      final first = provider.loadLessonDetail('a');
      await provider.loadLessonDetail('b');
      await first;

      expect(provider.currentLessonDetail?.lesson.id, 'b');
    }, () => backend.client);
  });

  test('làm mới lỗi mạng thì giữ bản đang hiện; bài chưa từng mở thì báo lỗi', () async {
    final backend = _Backend();
    await http.runWithClient(() async {
      final provider = LessonProvider();
      await provider.loadLessonDetail('a');

      backend.failing.addAll({'a', 'c'});
      await provider.loadLessonDetail('a');
      expect(provider.currentLessonDetail?.lesson.id, 'a');
      expect(provider.detailState, isA<ViewData>());

      await provider.loadLessonDetail('c');
      expect(provider.detailState, isA<ViewFailure>());
    }, () => backend.client);
  });
}
