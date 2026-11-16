import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:apphoctiengnnhat/core/network/api_client.dart';
import 'package:apphoctiengnnhat/features/study_groups/models/study_group.dart';
import 'package:apphoctiengnnhat/features/study_groups/services/study_group_service.dart';

http.Response _json(Object body) => http.Response.bytes(utf8.encode(jsonEncode(body)), 200,
    headers: const {'content-type': 'application/json; charset=utf-8'});

/// Nhóm đúng hình dạng server trả: người tạo và thành viên đã populate.
const _group = {
  '_id': 'g1',
  'name': 'Ôn N5',
  'level': 'N5',
  'creator_id': {'_id': 'u1', 'HoTen': 'Người tạo'},
  'members': [
    {'user_id': {'_id': 'u1', 'HoTen': 'Người tạo', 'TenDangNhap': 'creator'}, 'role': 'admin', 'joined_at': '2026-11-01T00:00:00.000Z'},
    {'user_id': {'_id': 'u2', 'TenDangNhap': 'hoc_vien'}, 'role': 'member', 'joined_at': '2026-11-02T00:00:00.000Z'},
  ],
  'member_count': 2,
  'max_members': 50,
  'is_private': false,
  'avatar': 'https://via.placeholder.com/150',
  'createdAt': '2026-11-01T00:00:00.000Z',
};

void main() {
  test('khám phá nhóm là một trang; bộ lọc dựng bằng query an toàn', () async {
    late Uri url;
    final page = await http.runWithClient(
      () => StudyGroupService().list(search: 'N5 & N4', level: 'N5'),
      () => MockClient((request) async {
        url = request.url;
        return _json({'data': [_group], 'page': 1, 'limit': 20, 'total': 1, 'totalPages': 1});
      }),
    );

    expect(url.queryParameters, {'page': '1', 'limit': '20', 'search': 'N5 & N4', 'level': 'N5'});
    final group = page.items.single;
    expect((group.name, group.creatorName, group.avatar), ('Ôn N5', 'Người tạo', null));
    expect(group.members.map((member) => (member.userId, member.isAdmin)), [('u1', true), ('u2', false)]);
  });

  test('tạo, sửa gửi cùng bản nháp; thao tác thành viên giữ đường dẫn cũ và đọc nhóm trong `data`', () async {
    final requests = <String>[];
    final bodies = <Object?>[];
    final service = StudyGroupService();
    const draft = StudyGroupDraft(name: 'Ôn N5', description: '', level: 'N5', isPrivate: true, maxMembers: 20);

    await http.runWithClient(
      () async {
        await service.create(draft);
        await service.update('g1', draft);
        await service.join('g1');
        await service.leave('g1');
        await service.kick('g1', 'u2');
        await service.promote('g1', 'u2');
        await service.demote('g1', 'u2');
        await service.delete('g1');
      },
      () => MockClient((request) async {
        requests.add('${request.method} ${request.url.path}');
        bodies.add(request.body.isEmpty ? null : jsonDecode(request.body));
        return _json({'data': _group});
      }),
    );

    expect(requests, [
      'POST /api/group',
      'PUT /api/group/g1',
      'POST /api/group/join/g1',
      'POST /api/group/leave/g1',
      'DELETE /api/group/kick/g1/u2',
      'PUT /api/group/promote/g1/u2',
      'PUT /api/group/demote/g1/u2',
      'DELETE /api/group/g1',
    ]);
    const body = {'name': 'Ôn N5', 'description': '', 'level': 'N5', 'is_private': true, 'max_members': 20};
    expect(bodies.take(2), [body, body]);
  });

  test('thống kê gắn với nhóm đã hỏi; response thiếu `data` là lỗi rõ ràng', () async {
    final stats = await http.runWithClient(
      () => StudyGroupService().stats('g1'),
      () => MockClient((_) async => _json({'data': {'member_count': 2, 'admin_count': 1, 'active_members': 1}})),
    );
    expect((stats.groupId, stats.memberCount, stats.adminCount, stats.activeMembers), ('g1', 2, 1, 1));

    await expectLater(
      http.runWithClient(() => StudyGroupService().detail('g1'), () => MockClient((_) async => _json(_group))),
      throwsA(isA<ServerException>()),
    );
  });
}
