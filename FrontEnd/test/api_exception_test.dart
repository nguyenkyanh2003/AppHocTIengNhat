import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:apphoctiengnnhat/core/network/api_client.dart';

void main() {
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
      }, () => MockClient((_) async => http.Response(jsonEncode({
            'message': 'Lịch đã đổi',
            'code': 'SRS_PROGRESS_CHANGED',
            'details': {'current_progress': {'box': 2}},
          }), status)));
    });
  }
}
