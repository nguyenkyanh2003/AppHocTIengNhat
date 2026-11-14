import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:apphoctiengnnhat/core/network/api_client.dart';
import 'package:apphoctiengnnhat/features/reports/services/report_service.dart';

http.Response _json(Object body, [int status = 200]) => http.Response.bytes(utf8.encode(jsonEncode(body)), status,
    headers: const {'content-type': 'application/json; charset=utf-8'});

const _report = {
  '_id': 'r1',
  'type': 'bug',
  'title': 'Lỗi mở bài',
  'description': 'Không mở được bài học',
  'priority': 'medium',
  'status': 'pending',
  'createdAt': '2026-11-14T03:00:00.000Z',
};

void main() {
  test('gửi báo cáo: body đúng hợp đồng, đọc lại báo cáo trong `data`', () async {
    late Map<String, dynamic> sent;
    final report = await http.runWithClient(
      () => ReportService().create(type: 'bug', title: 'Lỗi mở bài', description: 'Không mở được bài học'),
      () => MockClient((request) async {
        expect('${request.method} ${request.url.path}', 'POST /api/report/create');
        sent = jsonDecode(request.body) as Map<String, dynamic>;
        return _json({'data': _report, 'message': 'ok'}, 201);
      }),
    );

    expect(sent, {'type': 'bug', 'title': 'Lỗi mở bài', 'description': 'Không mở được bài học', 'priority': 'medium'});
    expect((report.id, report.status), ('r1', 'pending'));
  });

  test('báo cáo của tôi là một trang theo contract phân trang', () async {
    late Uri url;
    final page = await http.runWithClient(
      () => ReportService().listMine(page: 2),
      () => MockClient((request) async {
        url = request.url;
        return _json({'data': [_report], 'page': 2, 'limit': 20, 'total': 21, 'totalPages': 2});
      }),
    );

    expect(url.queryParameters, {'page': '2', 'limit': '20'});
    expect((page.items.single.title, page.hasMore), ('Lỗi mở bài', false));
  });

  test('response thiếu `data` là lỗi rõ ràng', () async {
    await expectLater(
      http.runWithClient(() => ReportService().listMine(), () => MockClient((_) async => _json({'reports': []}))),
      throwsA(isA<ServerException>()),
    );
  });
}
