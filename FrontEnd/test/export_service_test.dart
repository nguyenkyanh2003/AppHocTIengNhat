import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:apphoctiengnnhat/features/settings/services/export_service.dart';

http.Response _json(Object body, [int status = 200]) => http.Response(jsonEncode(body), status,
    headers: {'content-type': 'application/json; charset=utf-8'});

Map<String, dynamic> _xp(int i) =>
    {'amount': 2, 'reason': 'Ôn tập SRS', 'earned_at': '2026-09-${10 + i}T03:00:00.000Z', 'source': 'activity'};

/// Server giả cho phần streak: lịch sử XP 3 trang, lịch học 2 khoảng năm.
MockClient _server({required String? firstDay, bool failSecondHistoryPage = false, List<Uri>? log}) =>
    MockClient((request) async {
      log?.add(request.url);
      final query = request.url.queryParameters;
      switch (request.url.path) {
        case '/api/streak/my-streak':
          return _json({'current_streak': 2, 'first_day': firstDay});
        case '/api/streak/xp-history':
          return switch (query['cursor']) {
            null => _json({'data': [_xp(1), _xp(2)], 'next_cursor': 'c2', 'as_of': 'x'}),
            'c2' => failSecondHistoryPage
                ? _json({'message': 'Máy chủ lỗi'}, 500)
                : _json({'data': [_xp(3)], 'next_cursor': 'c3', 'as_of': 'x'}),
            _ => _json({'data': [_xp(4)], 'next_cursor': null, 'as_of': 'x'}),
          };
        case '/api/streak/days':
          if (query['to'] == null) {
            // Khoảng đầu: server tự chọn 366 ngày tới hôm nay, có hai trang.
            return query['cursor'] == null
                ? _json({
                    'data': [
                      {'day_key': '2026-09-19', 'status': 'studied'},
                    ],
                    'next_cursor': '2026-09-19',
                    'from': '2025-09-19',
                    'to': '2026-09-19',
                  })
                : _json({
                    'data': [
                      {'day_key': '2025-12-01', 'status': 'legacy', 'origin': 'legacy_unverified'},
                    ],
                    'next_cursor': null,
                    'from': '2025-09-19',
                    'to': '2026-09-19',
                  });
          }
          return _json({
            'data': [
              {'day_key': '2025-03-01', 'status': 'legacy'},
            ],
            'next_cursor': null,
            'from': query['from'],
            'to': query['to'],
          });
      }
      return _json({'message': 'không có'}, 404);
    });

void main() {
  test('streak export reads every history page and every calendar window back to the first day', () async {
    final log = <Uri>[];
    final data = await http.runWithClient(
      () => ExportService().load(ExportType.streaks),
      () => _server(firstDay: '2025-03-01', log: log),
    );

    expect((data['xp_history'] as List).map((row) => row['earned_at']), [
      '2026-09-11T03:00:00.000Z',
      '2026-09-12T03:00:00.000Z',
      '2026-09-13T03:00:00.000Z',
      '2026-09-14T03:00:00.000Z',
    ]);
    expect((data['streak_days'] as List).map((day) => day['day_key']), ['2026-09-19', '2025-12-01', '2025-03-01']);
    expect(data['streak']['current_streak'], 2);

    final older = log.lastWhere((uri) => uri.path == '/api/streak/days');
    expect(older.queryParameters['to'], '2025-09-18');
    expect(older.queryParameters['from'], '2024-09-18');
  });

  test('a user with no calendar yet exports no days and makes no calendar request', () async {
    final log = <Uri>[];
    final data = await http.runWithClient(
      () => ExportService().load(ExportType.streaks),
      () => _server(firstDay: null, log: log),
    );

    expect(data['streak_days'], isEmpty);
    expect(log.where((uri) => uri.path == '/api/streak/days'), isEmpty);
  });

  test('a failing page fails the whole export instead of returning a partial history', () async {
    await expectLater(
      http.runWithClient(
        () => ExportService().load(ExportType.streaks),
        () => _server(firstDay: '2026-01-01', failSecondHistoryPage: true),
      ),
      throwsA(isA<Exception>()),
    );
  });

  test('cancelling stops at the next page', () async {
    final log = <Uri>[];
    await expectLater(
      http.runWithClient(
        () => ExportService().load(ExportType.streaks, isCancelled: () => log.length >= 2),
        () => _server(firstDay: '2026-01-01', log: log),
      ),
      throwsA(isA<ExportCancelled>()),
    );
    expect(log, hasLength(2), reason: 'không đọc thêm trang nào sau khi huỷ');
  });

  test('day keys shift across month and year boundaries in UTC', () {
    expect(ExportService.shiftDay('2026-03-01', -1), '2026-02-28');
    expect(ExportService.shiftDay('2025-01-01', -1), '2024-12-31');
    expect(ExportService.shiftDay('2024-02-28', 1), '2024-02-29');
  });
}
