import 'package:flutter/foundation.dart';
import '../models/group_message.dart';
import '../services/group_chat_service.dart';

class GroupChatProvider extends ChangeNotifier {
  final GroupChatService _service = GroupChatService();

  final Map<String, List<GroupMessage>> _messagesByGroup = {};
  final Map<String, bool> _loadingByGroup = {};
  final Map<String, int> _pageByGroup = {};
  final Map<String, bool> _hasMoreByGroup = {};
  
  String? _currentGroupId;
  String? _error;
  GroupMessage? _replyToMessage;

  // Getters
  List<GroupMessage> getMessages(String groupId) {
    return _messagesByGroup[groupId] ?? [];
  }

  bool isLoading(String groupId) {
    return _loadingByGroup[groupId] ?? false;
  }

  bool hasMore(String groupId) {
    return _hasMoreByGroup[groupId] ?? true;
  }

  String? get error => _error;
  String? get currentGroupId => _currentGroupId;
  GroupMessage? get replyToMessage => _replyToMessage;

  // Set current group
  void setCurrentGroup(String groupId) {
    _currentGroupId = groupId;
    notifyListeners();
  }

  // Load messages
  Future<void> loadMessages({
    required String groupId,
    bool refresh = false,
    bool silent = false, // Don't show loading indicator for background refresh
  }) async {
    if (refresh) {
      _messagesByGroup[groupId] = [];
      _pageByGroup[groupId] = 1;
      _hasMoreByGroup[groupId] = true;
    }

    if (!(_hasMoreByGroup[groupId] ?? true)) return;

    if (!silent) {
      _loadingByGroup[groupId] = true;
      _error = null;
      notifyListeners();
    }

    try {
      final page = _pageByGroup[groupId] ?? 1;
      final messages = await _service.getMessages(
        groupId: groupId,
        page: page,
        limit: 50,
      );

      if (messages.isEmpty) {
        _hasMoreByGroup[groupId] = false;
      } else {
        final existingMessages = _messagesByGroup[groupId] ?? [];
        
        // Reverse để tin nhắn mới nhất ở dưới cùng
        final reversedMessages = messages.reversed.toList();
        
        if (refresh) {
          _messagesByGroup[groupId] = reversedMessages;
        } else {
          // Add older messages at the beginning
          _messagesByGroup[groupId] = [...reversedMessages, ...existingMessages];
        }
        
        _pageByGroup[groupId] = page + 1;
      }
    } catch (e) {
      if (!silent) {
        _error = 'Lỗi khi tải tin nhắn: $e';
      }
      print('Error loading messages: $e');
    } finally {
      if (!silent) {
        _loadingByGroup[groupId] = false;
      }
      notifyListeners();
    }
  }

  // Send message
  Future<bool> sendMessage({
    required String groupId,
    required String content,
  }) async {
    try {
      final message = await _service.sendMessage(
        groupId: groupId,
        content: content,
        replyTo: _replyToMessage?.id,
      );

      if (message != null) {
        final messages = _messagesByGroup[groupId] ?? [];
        _messagesByGroup[groupId] = [...messages, message];
        
        // Clear reply after sending
        _replyToMessage = null;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Lỗi khi gửi tin nhắn: $e';
      print(_error);
      notifyListeners();
      return false;
    }
  }

  // Edit message
  Future<bool> editMessage({
    required String groupId,
    required String messageId,
    required String content,
  }) async {
    try {
      final updatedMessage = await _service.editMessage(
        groupId: groupId,
        messageId: messageId,
        content: content,
      );

      if (updatedMessage != null) {
        final messages = _messagesByGroup[groupId] ?? [];
        final index = messages.indexWhere((m) => m.id == messageId);
        if (index != -1) {
          messages[index] = updatedMessage;
          _messagesByGroup[groupId] = [...messages];
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Lỗi khi sửa tin nhắn: $e';
      print(_error);
      notifyListeners();
      return false;
    }
  }

  // Delete message
  Future<bool> deleteMessage({
    required String groupId,
    required String messageId,
  }) async {
    try {
      final success = await _service.deleteMessage(
        groupId: groupId,
        messageId: messageId,
      );

      if (success) {
        final messages = _messagesByGroup[groupId] ?? [];
        messages.removeWhere((m) => m.id == messageId);
        _messagesByGroup[groupId] = [...messages];
        notifyListeners();
      }
      return success;
    } catch (e) {
      _error = 'Lỗi khi xóa tin nhắn: $e';
      print(_error);
      notifyListeners();
      return false;
    }
  }

  // Search messages
  Future<List<GroupMessage>> searchMessages({
    required String groupId,
    required String keyword,
  }) async {
    try {
      return await _service.searchMessages(
        groupId: groupId,
        keyword: keyword,
      );
    } catch (e) {
      _error = 'Lỗi khi tìm kiếm tin nhắn: $e';
      print(_error);
      return [];
    }
  }

  // Get shared files
  Future<List<GroupMessage>> getSharedFiles(String groupId) async {
    try {
      return await _service.getSharedFiles(groupId: groupId);
    } catch (e) {
      _error = 'Lỗi khi tải file: $e';
      print(_error);
      return [];
    }
  }

  // Set reply to message
  void setReplyTo(GroupMessage? message) {
    _replyToMessage = message;
    notifyListeners();
  }

  // Clear reply
  void clearReply() {
    _replyToMessage = null;
    notifyListeners();
  }

  // Add new message (for real-time updates)
  void addNewMessage(String groupId, GroupMessage message) {
    final messages = _messagesByGroup[groupId] ?? [];
    
    // Check if message already exists
    if (!messages.any((m) => m.id == message.id)) {
      _messagesByGroup[groupId] = [...messages, message];
      notifyListeners();
    }
  }

  // Update message (for real-time updates)
  void updateMessage(String groupId, GroupMessage message) {
    final messages = _messagesByGroup[groupId] ?? [];
    final index = messages.indexWhere((m) => m.id == message.id);
    
    if (index != -1) {
      messages[index] = message;
      _messagesByGroup[groupId] = [...messages];
      notifyListeners();
    }
  }

  // Remove message (for real-time updates)
  void removeMessage(String groupId, String messageId) {
    final messages = _messagesByGroup[groupId] ?? [];
    messages.removeWhere((m) => m.id == messageId);
    _messagesByGroup[groupId] = [...messages];
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearGroup(String groupId) {
    _messagesByGroup.remove(groupId);
    _loadingByGroup.remove(groupId);
    _pageByGroup.remove(groupId);
    _hasMoreByGroup.remove(groupId);
    notifyListeners();
  }

  void clearAll() {
    _messagesByGroup.clear();
    _loadingByGroup.clear();
    _pageByGroup.clear();
    _hasMoreByGroup.clear();
    _currentGroupId = null;
    _error = null;
    _replyToMessage = null;
    notifyListeners();
  }

  // Clear all state
  void clear() {
    _messagesByGroup.clear();
    _loadingByGroup.clear();
    _pageByGroup.clear();
    _hasMoreByGroup.clear();
    _currentGroupId = null;
    _error = null;
    _replyToMessage = null;
    notifyListeners();
  }
}
