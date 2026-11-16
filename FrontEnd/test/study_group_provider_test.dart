import 'package:flutter_test/flutter_test.dart';

import 'package:apphoctiengnnhat/core/network/api_client.dart';
import 'package:apphoctiengnnhat/core/network/api_envelope.dart';
import 'package:apphoctiengnnhat/core/state/view_state.dart';
import 'package:apphoctiengnnhat/features/study_groups/models/study_group.dart';
import 'package:apphoctiengnnhat/features/study_groups/providers/study_group_provider.dart';
import 'package:apphoctiengnnhat/features/study_groups/services/study_group_service.dart';

StudyGroup _group(String id, {String name = 'Nhóm', int members = 1}) =>
    StudyGroup(id: id, name: name, creatorId: 'u1', memberCount: members);

class _FakeService extends StudyGroupService {
  final calls = <String>[];
  Object? failure;

  Future<T> _answer<T>(String call, T value) async {
    calls.add(call);
    if (failure != null) throw failure!;
    return value;
  }

  @override
  Future<Paged<StudyGroup>> list({int page = 1, int limit = StudyGroupService.pageSize, String? search, String? level}) =>
      _answer('list $page ${search ?? '-'} ${level ?? '-'}',
          Paged(items: [_group('p$page')], page: page, limit: limit, total: 2, totalPages: 2));

  @override
  Future<List<StudyGroup>> mine() => _answer('mine', [_group('g1')]);

  @override
  Future<StudyGroup> detail(String id) => _answer('detail $id', _group(id));

  @override
  Future<GroupStats> stats(String id) => _answer('stats $id', GroupStats(groupId: id, memberCount: 1));

  @override
  Future<StudyGroup> create(StudyGroupDraft draft) => _answer('create ${draft.name}', _group('moi', name: draft.name));

  @override
  Future<StudyGroup> join(String id) => _answer('join $id', _group(id, members: 2));

  @override
  Future<void> leave(String id) => _answer('leave $id', null);

  @override
  Future<StudyGroup> kick(String id, String userId) => _answer('kick $id $userId', _group(id, members: 1));

  @override
  Future<void> delete(String id) => _answer('delete $id', null);
}

void main() {
  late _FakeService service;
  late StudyGroupProvider provider;

  setUp(() {
    service = _FakeService();
    provider = StudyGroupProvider(service: service);
  });

  test('nhóm của tôi và khám phá (phân trang, tìm, lọc) đều qua ViewState', () async {
    await provider.loadMyGroups();
    await provider.loadAllGroups();
    await provider.loadMore();
    await provider.setSearchQuery('N5');
    await provider.setLevelFilter('N4');
    await provider.clearFilters();

    expect(provider.myGroups.valueOrNull?.single.id, 'g1');
    expect(service.calls.where((call) => call.startsWith('list')), [
      'list 1 - -',
      'list 2 - -',
      'list 1 N5 -',
      'list 1 N5 N4',
      'list 1 - -',
    ]);
  });

  test('mở nhóm tải chi tiết và thống kê; mục khác còn sót coi như đang tải', () async {
    await provider.loadGroupDetail('g1');

    expect(provider.detailOf('g1').valueOrNull?.id, 'g1');
    expect(provider.statsOf('g1').valueOrNull?.memberCount, 1);
    expect(provider.detailOf('g2').isLoading, isTrue);
  });

  test('tham gia, mời ra cập nhật nhóm đang mở, thống kê và nhóm của tôi', () async {
    await provider.loadMyGroups();
    await provider.loadGroupDetail('g1');

    expect(await provider.joinGroup('g1'), isNull);
    expect(provider.detailOf('g1').valueOrNull?.memberCount, 2);
    expect(await provider.kickMember('g1', 'u2'), isNull);
    expect(provider.detailOf('g1').valueOrNull?.memberCount, 1);

    expect(service.calls.where((call) => call == 'mine'), hasLength(3));
    expect(service.calls.where((call) => call == 'stats g1'), hasLength(3));
  });

  test('rời hay xoá nhóm đang mở thì bỏ chi tiết; lỗi trả câu báo lỗi', () async {
    await provider.loadGroupDetail('g1');
    expect(await provider.leaveGroup('g1'), isNull);
    expect(provider.detailOf('g1').isLoading, isTrue);

    service.failure = ApiException('Chỉ người tạo nhóm mới có thể xóa nhóm.');
    expect(await provider.deleteGroup('g1'), 'Chỉ người tạo nhóm mới có thể xóa nhóm.');
  });

  test('tạo nhóm xong thì nhóm của tôi tải lại', () async {
    await provider.loadMyGroups();

    expect(await provider.createGroup(const StudyGroupDraft(name: 'Ôn N4')), isNull);

    expect(service.calls, ['mine', 'create Ôn N4', 'mine']);
  });

  test('đăng xuất xoá sạch', () async {
    await provider.loadMyGroups();
    await provider.setSearchQuery('N5');

    provider.clear();

    expect(provider.myGroups, isA<ViewIdle<List<StudyGroup>>>());
    expect(provider.searchQuery, isNull);
  });
}
