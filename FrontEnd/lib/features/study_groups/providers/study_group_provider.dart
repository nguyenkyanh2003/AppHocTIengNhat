import 'package:flutter/foundation.dart';

import '../../../core/state/detail_state.dart';
import '../../../core/state/paged_list.dart';
import '../../../core/state/view_state.dart';
import '../models/study_group.dart';
import '../services/study_group_service.dart';

/// Nhóm học: nhóm của tôi, khám phá (tìm, lọc, tải thêm), nhóm đang mở kèm
/// thống kê, và các thao tác trên nhóm/thành viên.
///
/// Mọi thao tác ghi trả `null` khi xong hoặc câu báo lỗi để màn hiện. Xong thì
/// nhóm đang mở cập nhật theo bản server trả, các danh sách đã mở tải lại.
class StudyGroupProvider extends ChangeNotifier {
  StudyGroupProvider({StudyGroupService? service}) : _service = service ?? StudyGroupService();

  final StudyGroupService _service;
  ViewState<List<StudyGroup>> _myGroups = const ViewState.idle();
  int _myGeneration = 0;
  late final _allGroups = PagedList<StudyGroup>(onChanged: _notify);
  late final _detail = DetailState<StudyGroup>(idOf: (group) => group.id, onChanged: _notify);
  late final _stats = DetailState<GroupStats>(idOf: (stats) => stats.groupId, onChanged: _notify);
  String? _searchQuery;
  String? _levelFilter;
  bool _disposed = false;

  ViewState<List<StudyGroup>> get myGroups => _myGroups;
  ViewState<List<StudyGroup>> get allGroups => _allGroups.state;
  bool get hasMore => _allGroups.hasMore;
  bool get isLoadingMore => _allGroups.isLoadingMore;
  String? get loadMoreError => _allGroups.loadMoreError;
  String? get searchQuery => _searchQuery;
  String? get levelFilter => _levelFilter;

  ViewState<StudyGroup> detailOf(String groupId) => _detail.of(groupId);
  ViewState<GroupStats> statsOf(String groupId) => _stats.of(groupId);

  Future<void> loadMyGroups() async {
    final generation = ++_myGeneration;
    if (!_myGroups.hasData) {
      _myGroups = const ViewState.loading();
      _notify();
    }
    final result = await ViewState.guard(_service.mine);
    if (generation != _myGeneration) return;
    _myGroups = result;
    _notify();
  }

  /// Khám phá từ trang đầu với bộ lọc đang chọn.
  Future<void> loadAllGroups() {
    final search = _searchQuery;
    final level = _levelFilter;
    return _allGroups.load((page) => _service.list(page: page, search: search, level: level));
  }

  Future<void> loadMore() => _allGroups.loadMore();

  Future<void> setSearchQuery(String? query) {
    final trimmed = query?.trim();
    _searchQuery = trimmed == null || trimmed.isEmpty ? null : trimmed;
    return loadAllGroups();
  }

  Future<void> setLevelFilter(String? level) {
    _levelFilter = level;
    return loadAllGroups();
  }

  Future<void> clearFilters() {
    _searchQuery = null;
    _levelFilter = null;
    return loadAllGroups();
  }

  /// Chi tiết và thống kê tải song song; thống kê lỗi không chặn chi tiết.
  Future<void> loadGroupDetail(String groupId) => Future.wait([
        _detail.load(groupId, () => _service.detail(groupId)),
        _loadStats(groupId),
      ]);

  Future<void> _loadStats(String groupId) => _stats.load(groupId, () => _service.stats(groupId));

  Future<String?> createGroup(StudyGroupDraft draft) => _write(() => _service.create(draft));

  Future<String?> updateGroup(String groupId, StudyGroupDraft draft) => _write(() => _service.update(groupId, draft));

  Future<String?> uploadGroupAvatar(String groupId, List<int> bytes, String fileName) =>
      _write(() => _service.uploadAvatar(groupId, bytes, fileName));

  Future<String?> joinGroup(String groupId) => _write(() => _service.join(groupId));

  Future<String?> kickMember(String groupId, String userId) => _write(() => _service.kick(groupId, userId));

  Future<String?> promoteMember(String groupId, String userId) => _write(() => _service.promote(groupId, userId));

  Future<String?> demoteMember(String groupId, String userId) => _write(() => _service.demote(groupId, userId));

  Future<String?> leaveGroup(String groupId) => _close(groupId, () => _service.leave(groupId));

  Future<String?> deleteGroup(String groupId) => _close(groupId, () => _service.delete(groupId));

  /// Về trạng thái chưa tải (đăng xuất).
  void clear() {
    _myGeneration++;
    _myGroups = const ViewState.idle();
    _allGroups.clear();
    _detail.clear();
    _stats.clear();
    _searchQuery = null;
    _levelFilter = null;
    _notify();
  }

  Future<String?> _write(Future<StudyGroup> Function() action) async {
    final result = await ViewState.guard(action);
    final group = result.valueOrNull;
    if (group == null) return result.errorOrNull;
    _detail.replace(group);
    if (_stats.state is! ViewIdle) await _loadStats(group.id);
    _reloadLists();
    return null;
  }

  /// Rời hoặc xoá: nhóm đó không còn mở được nữa.
  Future<String?> _close(String groupId, Future<void> Function() action) async {
    final result = await ViewState.guard(action);
    if (!result.hasData) return result.errorOrNull;
    _detail.remove(groupId);
    _stats.remove(groupId);
    _reloadLists();
    return null;
  }

  void _reloadLists() {
    if (_myGroups is! ViewIdle) loadMyGroups();
    if (_allGroups.state is! ViewIdle) _allGroups.reload();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
