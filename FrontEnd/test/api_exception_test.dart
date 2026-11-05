import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:apphoctiengnnhat/core/network/api_client.dart';

const _json = {'content-type': 'application/json; charset=utf-8'};

void main() {
  test('mất kết nối: thông báo không lộ tên exception và địa chỉ máy chủ', () async {
    await http.runWithClient(() async {
      await expectLater(
        ApiClient().get('/test-network'),
        throwsA(isA<NetworkException>().having(
          (e) => e.message,
          'message',
          allOf(
            contains('Không thể kết nối'),
            isNot(contains('ClientException')),
            isNot(contains('http')),
          ),
        )),
      );
    }, () => MockClient((request) async => throw http.ClientException('Failed to fetch', request.url)));
  });

  test('message-only constructors remain compatible', () {
    final error = ApiException('Lỗi');
    expect(error.message, 'Lỗi');
    expect(error.code, isNull);
  });

  for (final status in [400, 401, 403, 404, 409, 500]) {
    test('HTTP $status preserves status, business code and details', () async {
      await http.runWithClient(() async {
        await expectLater(
          ApiClient().get('/test-error'),
          throwsA(isA<ApiException>()
              .having((e) => e.statusCode, 'status', status)
              .having((e) => e.code, 'code', 'SRS_PROGRESS_CHANGED')
              .having((e) => e.details?['current_progress']['box'], 'box', 2)),
        );
      },
          () => MockClient((_) async => http.Response.bytes(
              utf8.encode(jsonEncode({
                'message': 'Lịch đã đổi',
                'code': 'SRS_PROGRESS_CHANGED',
                'details': {
                  'current_progress': {'box': 2}
                },
              })),
              status,
              headers: _json)));
    });
  }
}
