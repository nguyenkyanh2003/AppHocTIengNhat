import '../../../core/network/api_client.dart';
import '../../../core/network/api_envelope.dart';
import '../models/study_group.dart';

/// Nhóm học. Thao tác trên nhóm và thành viên trả lại nhóm sau khi đổi.
class StudyGroupService {
  StudyGroupService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  static const pageSize = 20;

  /// Nhóm đang hoạt động, mới tạo trước; [search] khớp nguyên văn tên hoặc mô tả.
  Future<Paged<StudyGroup>> list({int page = 1, int limit = pageSize, String? search, String? level}) async {
    final query = Uri(queryParameters: {
      'page': '$page',
      'limit': '$limit',
      if (search != null) 'search': search,
      if (level != null) 'level': level,
    }).query;
    return Paged.fromJson(await _client.get('/group?$query'), StudyGroup.fromJson);
  }

  /// Nhóm người đang đăng nhập là thành viên.
  Future<List<StudyGroup>> mine() async => listOf(await _client.get('/group/me'), StudyGroup.fromJson);

  Future<StudyGroup> detail(String id) async => _groupOf(await _client.get('/group/$id'));

  Future<GroupStats> stats(String id) async =>
      objectOf(await _client.get('/group/$id/stats'), (json) => GroupStats.fromJson(id, json));

  Future<StudyGroup> create(StudyGroupDraft draft) async => _groupOf(await _client.post('/group', draft.toJson()));

  Future<StudyGroup> update(String id, StudyGroupDraft draft) async =>
      _groupOf(await _client.put('/group/$id', draft.toJson()));

  Future<StudyGroup> uploadAvatar(String id, List<int> bytes, String fileName) async =>
      _groupOf(await _client.putMultipart('/group/$id/avatar', const {}, 'avatar', bytes, fileName));

  Future<StudyGroup> join(String id) async => _groupOf(await _client.post('/group/join/$id', const {}));

  Future<void> leave(String id) => _client.post('/group/leave/$id', const {});

  Future<StudyGroup> kick(String id, String userId) async => _groupOf(await _client.delete('/group/kick/$id/$userId'));

  Future<StudyGroup> promote(String id, String userId) async =>
      _groupOf(await _client.put('/group/promote/$id/$userId', const {}));

  Future<StudyGroup> demote(String id, String userId) async =>
      _groupOf(await _client.put('/group/demote/$id/$userId', const {}));

  /// Chỉ người tạo nhóm mới xoá được.
  Future<void> delete(String id) => _client.delete('/group/$id');

  static StudyGroup _groupOf(Object? response) => objectOf(response, StudyGroup.fromJson);
}
