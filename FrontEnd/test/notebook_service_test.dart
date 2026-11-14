import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:apphoctiengnnhat/core/network/api_client.dart';
import 'package:apphoctiengnnhat/features/notebook/models/notebook.dart';
import 'package:apphoctiengnnhat/features/notebook/services/notebook_service.dart';

http.Response _json(Object body, [int status = 200]) => http.Response.bytes(utf8.encode(jsonEncode(body)), status,
    headers: const {'content-type': 'application/json; charset=utf-8'});

const _note = {
  '_id': 'n1',
  'user_id': 'u1',
  'title': 'Trợ từ は',
  'content': 'Đánh dấu chủ đề',
  'type': 'grammar',
  'tags': ['N5'],
  'createdAt': '2026-11-14T03:00:00.000Z',
  'updatedAt': '2026-11-14T04:00:00.000Z',
};

void main() {
  test('danh sách là một trang theo contract phân trang, bộ lọc dựng bằng query an toàn', () async {
    late Uri url;
    final page = await http.runWithClient(
      () => NotebookService().list(page: 2, type: NoteType.grammar, search: 'は & が'),
      () => MockClient((request) async {
        url = request.url;
        return _json({'data': [_note], 'page': 2, 'limit': 20, 'total': 21, 'totalPages': 2});
      }),
    );

    expect(url.path, '/api/notebook');
    expect(url.queryParameters, {'page': '2', 'limit': '20', 'type': 'grammar', 'search': 'は & が'});
    final note = page.items.single;
    expect((note.id, note.type, page.hasMore), ('n1', NoteType.grammar, false));
    expect(note.tags, ['N5']);
    expect(note.updatedAt, DateTime.utc(2026, 11, 14, 4));
  });

  test('không lọc thì không gửi tham số lọc', () async {
    late Uri url;
    await http.runWithClient(
      () => NotebookService().list(),
      () => MockClient((request) async {
        url = request.url;
        return _json({'data': [], 'page': 1, 'limit': 20, 'total': 0, 'totalPages': 0});
      }),
    );
    expect(url.queryParameters, {'page': '1', 'limit': '20'});
  });

  test('tạo và sửa gửi cùng một bản nháp, đọc lại ghi chú trong `data`', () async {
    final requests = <String>[];
    final bodies = <Object?>[];
    const draft = NotebookDraft(title: 'Trợ từ は', content: 'Đánh dấu chủ đề', type: NoteType.grammar, tags: ['N5']);

    await http.runWithClient(
      () async {
        expect((await NotebookService().create(draft)).id, 'n1');
        expect((await NotebookService().update('n1', draft)).title, 'Trợ từ は');
        await NotebookService().delete('n1');
      },
      () => MockClient((request) async {
        requests.add('${request.method} ${request.url.path}');
        bodies.add(request.body.isEmpty ? null : jsonDecode(request.body));
        return request.method == 'DELETE'
            ? _json({'data': {'deleted': true}})
            : _json({'data': _note, 'message': 'ok'}, request.method == 'POST' ? 201 : 200);
      }),
    );

    expect(requests, ['POST /api/notebook', 'PUT /api/notebook/n1', 'DELETE /api/notebook/n1']);
    const body = {'title': 'Trợ từ は', 'content': 'Đánh dấu chủ đề', 'type': 'grammar', 'tags': ['N5']};
    expect(bodies.take(2), [body, body]);
  });

  test('loại lạ đọc thành ghi chú chung; response thiếu `data` là lỗi rõ ràng', () async {
    final note = await http.runWithClient(
      () => NotebookService().detail('n1'),
      () => MockClient((_) async => _json({'data': {..._note, 'type': 'diary'}})),
    );
    expect(note.type, NoteType.general);

    await expectLater(
      http.runWithClient(() => NotebookService().detail('n1'), () => MockClient((_) async => _json(_note))),
      throwsA(isA<ServerException>()),
    );
  });
}
