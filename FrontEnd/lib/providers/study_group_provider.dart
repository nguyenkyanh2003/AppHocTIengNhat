import 'package:flutter/foundation.dart';
import '../models/study_group.dart';
import '../services/study_group_service.dart';

class StudyGroupProvider extends ChangeNotifier {
  final StudyGroupService _service = StudyGroupService();

  final List<StudyGroup> _allGroups = [];
  List<StudyGroup> _myGroups = [];
  StudyGroup? _currentGroup;
  GroupStats? _currentGroupStats;

  bool _isLoading = false;
  String? _error;

  // Filters
  String? _searchQuery;
  String? _levelFilter;
  bool? _privateFilter;

  // Pagination
  int _currentPage = 1;
  bool _hasMore = true;

  // Getters
  List<StudyGroup> get allGroups => _allGroups;
  List<StudyGroup> get myGroups => _myGroups;
  StudyGroup? get currentGroup => _currentGroup;
  GroupStats? get currentGroupStats => _currentGroupStats;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get searchQuery => _searchQuery;
  String? get levelFilter => _levelFilter;
  bool? get privateFilter => _privateFilter;
  bool get hasMore => _hasMore;

  // Load tất cả nhóm (public groups)
  Future<void> loadAllGroups({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _allGroups.clear();
    }

    if (!_hasMore) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final groups = await _service.getGroups(
        page: _currentPage,
        limit: 20,
        search: _searchQuery,
        level: _levelFilter,
        isPrivate: _privateFilter,
      );

      if (groups.isEmpty) {
        _hasMore = false;
      } else {
        _allGroups.addAll(groups);
        _currentPage++;
      }
    } catch (e) {
      _error = 'Lỗi khi tải danh sách nhóm: $e';
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load nhóm của tôi
  Future<void> loadMyGroups() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _myGroups = await _service.getMyGroups();
    } catch (e) {
      _error = 'Lỗi khi tải nhóm của bạn: $e';
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load chi tiết nhóm
  Future<void> loadGroupDetail(String groupId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentGroup = await _service.getGroupDetail(groupId);
      if (_currentGroup != null) {
        await loadGroupStats(groupId);
      }
    } catch (e) {
      _error = 'Lỗi khi tải thông tin nhóm: $e';
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load thống kê nhóm
  Future<void> loadGroupStats(String groupId) async {
    try {
      _currentGroupStats = await _service.getGroupStats(groupId);
      notifyListeners();
    } catch (e) {
      print('Error loading group stats: $e');
    }
  }

  // Tạo nhóm mới
  Future<StudyGroup?> createGroup({
    required String name,
    String? description,
    String? level,
    String? avatar,
    bool? isPrivate,
    int? maxMembers,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newGroup = await _service.createGroup(
        name: name,
        description: description,
        level: level,
        avatar: avatar,
        isPrivate: isPrivate,
        maxMembers: maxMembers,
      );

      if (newGroup != null) {
        _myGroups.insert(0, newGroup);
        _currentGroup = newGroup;
      }

      return newGroup;
    } catch (e) {
      _error = 'Lỗi khi tạo nhóm: $e';
      print(_error);
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cập nhật thông tin nhóm
  Future<bool> updateGroup({
    required String groupId,
    String? name,
    String? description,
    String? avatar,
    String? level,
    bool? isPrivate,
    int? maxMembers,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedGroup = await _service.updateGroup(
        groupId: groupId,
        name: name,
        description: description,
        avatar: avatar,
        level: level,
        isPrivate: isPrivate,
        maxMembers: maxMembers,
      );

      if (updatedGroup != null) {
        _currentGroup = updatedGroup;
        
        // Update in lists
        final myIndex = _myGroups.indexWhere((g) => g.id == groupId);
        if (myIndex != -1) _myGroups[myIndex] = updatedGroup;
        
        final allIndex = _allGroups.indexWhere((g) => g.id == groupId);
        if (allIndex != -1) _allGroups[allIndex] = updatedGroup;
        
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Lỗi khi cập nhật nhóm: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Upload group avatar
  Future<bool> uploadGroupAvatar(String groupId, List<int> imageBytes, String fileName) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedGroup = await _service.uploadGroupAvatar(groupId, imageBytes, fileName);

      if (updatedGroup != null) {
        _currentGroup = updatedGroup;
        
        // Update in lists
        final myIndex = _myGroups.indexWhere((g) => g.id == groupId);
        if (myIndex != -1) _myGroups[myIndex] = updatedGroup;
        
        final allIndex = _allGroups.indexWhere((g) => g.id == groupId);
        if (allIndex != -1) _allGroups[allIndex] = updatedGroup;
        
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Lỗi khi upload avatar: $e';
      print(_error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Tham gia nhóm
  Future<bool> joinGroup(String groupId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _service.joinGroup(groupId);
      if (success) {
        await loadGroupDetail(groupId);
        await loadMyGroups();
      }
      return success;
    } catch (e) {
      _error = 'Lỗi khi tham gia nhóm: $e';
      print(_error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Rời nhóm
  Future<bool> leaveGroup(String groupId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _service.leaveGroup(groupId);
      if (success) {
        _myGroups.removeWhere((g) => g.id == groupId);
        if (_currentGroup?.id == groupId) {
          _currentGroup = null;
        }
      }
      return success;
    } catch (e) {
      _error = 'Lỗi khi rời nhóm: $e';
      print(_error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Kick thành viên
  Future<bool> kickMember(String groupId, String userId) async {
    try {
      final success = await _service.kickMember(groupId, userId);
      if (success) {
        await loadGroupDetail(groupId);
      }
      return success;
    } catch (e) {
      _error = 'Lỗi khi kick thành viên: $e';
      print(_error);
      return false;
    }
  }

  // Promote thành admin
  Future<bool> promoteMember(String groupId, String userId) async {
    try {
      final success = await _service.promoteMember(groupId, userId);
      if (success) {
        await loadGroupDetail(groupId);
      }
      return success;
    } catch (e) {
      _error = 'Lỗi khi promote thành viên: $e';
      print(_error);
      return false;
    }
  }

  // Demote về member
  Future<bool> demoteMember(String groupId, String userId) async {
    try {
      final success = await _service.demoteMember(groupId, userId);
      if (success) {
        await loadGroupDetail(groupId);
      }
      return success;
    } catch (e) {
      _error = 'Lỗi khi demote thành viên: $e';
      print(_error);
      return false;
    }
  }

  // Xóa nhóm
  Future<bool> deleteGroup(String groupId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _service.deleteGroup(groupId);
      if (success) {
        _myGroups.removeWhere((g) => g.id == groupId);
        _allGroups.removeWhere((g) => g.id == groupId);
        if (_currentGroup?.id == groupId) {
          _currentGroup = null;
        }
      }
      return success;
    } catch (e) {
      _error = 'Lỗi khi xóa nhóm: $e';
      print(_error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Set filters
  void setSearchQuery(String? query) {
    _searchQuery = query;
    _currentPage = 1;
    _hasMore = true;
    _allGroups.clear();
    notifyListeners();
    loadAllGroups();
  }

  void setLevelFilter(String? level) {
    _levelFilter = level;
    _currentPage = 1;
    _hasMore = true;
    _allGroups.clear();
    notifyListeners();
    loadAllGroups();
  }

  void setPrivateFilter(bool? isPrivate) {
    _privateFilter = isPrivate;
    _currentPage = 1;
    _hasMore = true;
    _allGroups.clear();
    notifyListeners();
    loadAllGroups();
  }

  void clearFilters() {
    _searchQuery = null;
    _levelFilter = null;
    _privateFilter = null;
    _currentPage = 1;
    _hasMore = true;
    _allGroups.clear();
    notifyListeners();
    loadAllGroups();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearCurrentGroup() {
    _currentGroup = null;
    _currentGroupStats = null;
    notifyListeners();
  }

  // Clear all state
  void clear() {
    _allGroups.clear();
    _myGroups = [];
    _currentGroup = null;
    _currentGroupStats = null;
    _isLoading = false;
    _error = null;
    _searchQuery = null;
    _levelFilter = null;
    _privateFilter = null;
    _currentPage = 1;
    _hasMore = true;
    notifyListeners();
  }
}
