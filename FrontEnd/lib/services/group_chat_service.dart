import '../core/api_client.dart';
import '../models/group_message.dart';

class GroupChatService {
  final ApiClient _apiClient = ApiClient();

  // Lấy tin nhắn trong nhóm (có pagination)
  Future<List<GroupMessage>> getMessages({
    required String groupId,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final response = await _apiClient.get(
        '/group-chat/$groupId?page=$page&limit=$limit',
      );

      if (response != null && response['data'] != null) {
        return (response['data'] as List)
            .map((json) => GroupMessage.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error getting messages: $e');
      return [];
    }
  }

  // Gửi tin nhắn text
  Future<GroupMessage?> sendMessage({
    required String groupId,
    required String content,
    String? replyTo,
  }) async {
    try {
      final response = await _apiClient.post(
        '/group-chat/$groupId',
        {
          'content': content,
          if (replyTo != null) 'reply_to': replyTo,
        },
      );

      if (response['data'] != null) {
        return GroupMessage.fromJson(response['data']);
      }
      return null;
    } catch (e) {
      print('Error sending message: $e');
      return null;
    }
  }

  // Upload và gửi file
  Future<GroupMessage?> sendFile({
    required String groupId,
    required String filePath,
    String? caption,
  }) async {
    try {
      // TODO: Implement multipart file upload với /group-chat/:groupId/upload
      print('File upload not yet implemented');
      return null;
    } catch (e) {
      print('Error sending file: $e');
      return null;
    }
  }

  // Chỉnh sửa tin nhắn
  Future<GroupMessage?> editMessage({
    required String groupId,
    required String messageId,
    required String content,
  }) async {
    try {
      final response = await _apiClient.put(
        '/group-chat/$groupId/$messageId',
        {'content': content},
      );

      if (response['data'] != null) {
        return GroupMessage.fromJson(response['data']);
      }
      return null;
    } catch (e) {
      print('Error editing message: $e');
      return null;
    }
  }

  // Xóa tin nhắn
  Future<bool> deleteMessage({
    required String groupId,
    required String messageId,
  }) async {
    try {
      await _apiClient.delete('/group-chat/$groupId/$messageId');
      return true;
    } catch (e) {
      print('Error deleting message: $e');
      return false;
    }
  }

  // Tìm kiếm tin nhắn
  Future<List<GroupMessage>> searchMessages({
    required String groupId,
    required String keyword,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.get(
        '/group-chat/$groupId/search?keyword=$keyword&page=$page&limit=$limit',
      );

      if (response != null && response['data'] != null) {
        return (response['data'] as List)
            .map((json) => GroupMessage.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error searching messages: $e');
      return [];
    }
  }

  // Lấy file đã chia sẻ trong nhóm
  Future<List<GroupMessage>> getSharedFiles({
    required String groupId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      // Backend không có endpoint riêng cho files, dùng search với filter
      final response = await _apiClient.get(
        '/group-chat/$groupId/search?type=FILE&page=$page&limit=$limit',
      );

      if (response != null && response['data'] != null) {
        return (response['data'] as List)
            .map((json) => GroupMessage.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error getting shared files: $e');
      return [];
    }
  }
}
