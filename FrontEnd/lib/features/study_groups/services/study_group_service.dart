import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../models/study_group.dart';

class StudyGroupService {
  final ApiClient _apiClient = ApiClient();

  // Tạo nhóm mới
  Future<StudyGroup?> createGroup({
    required String name,
    String? description,
    String? level,
    String? avatar,
    bool? isPrivate,
    int? maxMembers,
  }) async {
    try {
      final response = await _apiClient.post(
        '/group',
        {
          'name': name,
          if (description != null) 'description': description,
          if (level != null) 'level': level,
          if (avatar != null) 'avatar': avatar,
          if (isPrivate != null) 'is_private': isPrivate,
          if (maxMembers != null) 'max_members': maxMembers,
        },
      );

      if (response['data'] != null) {
        return StudyGroup.fromJson(response['data']);
      }
      return null;
    } catch (e) {
      debugPrint('Error creating group: $e');
      return null;
    }
  }

  // Lấy danh sách nhóm (có filter, search, pagination)
  Future<List<StudyGroup>> getGroups({
    int page = 1,
    int limit = 10,
    String? search,
    String? level,
    bool? isPrivate,
  }) async {
    try {
      String queryString = '?page=$page&limit=$limit';
      if (search != null && search.isNotEmpty) queryString += '&search=$search';
      if (level != null) queryString += '&level=$level';
      if (isPrivate != null) queryString += '&is_private=$isPrivate';

      final response = await _apiClient.get('/group$queryString');

      if (response != null && response['data'] != null) {
        return (response['data'] as List)
            .map((json) => StudyGroup.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error getting groups: $e');
      return [];
    }
  }

  // Lấy nhóm của tôi
  Future<List<StudyGroup>> getMyGroups() async {
    try {
      final response = await _apiClient.get('/group/me');

      if (response != null && response['data'] != null) {
        return (response['data'] as List)
            .map((json) => StudyGroup.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error getting my groups: $e');
      return [];
    }
  }

  // Lấy chi tiết nhóm
  Future<StudyGroup?> getGroupDetail(String groupId) async {
    try {
      final response = await _apiClient.get('/group/$groupId');

      if (response != null && response['data'] != null) {
        debugPrint('Group response: ${response['data']}');
        debugPrint('Members: ${response['data']['members']}');
        return StudyGroup.fromJson(response['data']);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting group detail: $e');
      return null;
    }
  }

  // Cập nhật thông tin nhóm
  Future<StudyGroup?> updateGroup({
    required String groupId,
    String? name,
    String? description,
    String? avatar,
    String? level,
    bool? isPrivate,
    int? maxMembers,
  }) async {
    try {
      final response = await _apiClient.put(
        '/group/$groupId',
        {
          if (name != null) 'name': name,
          if (description != null) 'description': description,
          if (avatar != null) 'avatar': avatar,
          if (level != null) 'level': level,
          if (isPrivate != null) 'is_private': isPrivate,
          if (maxMembers != null) 'max_members': maxMembers,
        },
      );

      if (response['data'] != null) {
        return StudyGroup.fromJson(response['data']);
      }
      return null;
    } catch (e) {
      debugPrint('Error updating group: $e');
      return null;
    }
  }

  // Upload group avatar
  Future<StudyGroup?> uploadGroupAvatar(
      String groupId, List<int> imageBytes, String fileName) async {
    try {
      final response = await _apiClient.putMultipart(
        '/group/$groupId/avatar',
        {},
        'avatar',
        imageBytes,
        fileName,
      );

      if (response['data'] != null) {
        return StudyGroup.fromJson(response['data']);
      }
      return null;
    } catch (e) {
      debugPrint('Error uploading group avatar: $e');
      return null;
    }
  }

  // Tham gia nhóm
  Future<bool> joinGroup(String groupId) async {
    try {
      await _apiClient.post('/group/join/$groupId', {});
      return true;
    } catch (e) {
      debugPrint('Error joining group: $e');
      return false;
    }
  }

  // Rời nhóm
  Future<bool> leaveGroup(String groupId) async {
    try {
      await _apiClient.post('/group/leave/$groupId', {});
      return true;
    } catch (e) {
      debugPrint('Error leaving group: $e');
      return false;
    }
  }

  // Kick thành viên (admin only)
  Future<bool> kickMember(String groupId, String userId) async {
    try {
      await _apiClient.delete('/group/kick/$groupId/$userId');
      return true;
    } catch (e) {
      debugPrint('Error kicking member: $e');
      return false;
    }
  }

  // Promote thành admin (admin only)
  Future<bool> promoteMember(String groupId, String userId) async {
    try {
      await _apiClient.put('/group/promote/$groupId/$userId', {});
      return true;
    } catch (e) {
      debugPrint('Error promoting member: $e');
      return false;
    }
  }

  // Demote về member (creator only)
  Future<bool> demoteMember(String groupId, String userId) async {
    try {
      await _apiClient.put('/group/demote/$groupId/$userId', {});
      return true;
    } catch (e) {
      debugPrint('Error demoting member: $e');
      return false;
    }
  }

  // Lấy thống kê nhóm
  Future<GroupStats?> getGroupStats(String groupId) async {
    try {
      final response = await _apiClient.get('/group/$groupId/stats');

      if (response != null && response['data'] != null) {
        return GroupStats.fromJson(response['data']);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting group stats: $e');
      return null;
    }
  }

  // Xóa nhóm (creator only)
  Future<bool> deleteGroup(String groupId) async {
    try {
      await _apiClient.delete('/group/$groupId');
      return true;
    } catch (e) {
      debugPrint('Error deleting group: $e');
      return false;
    }
  }
}
