import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/group_chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/group_message.dart';

class GroupChatScreen extends StatefulWidget {
  final String groupId;

  const GroupChatScreen({Key? key, required this.groupId}) : super(key: key);

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _refreshTimer;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<GroupChatProvider>(context, listen: false);
      provider.setCurrentGroup(widget.groupId);
      provider.loadMessages(groupId: widget.groupId, refresh: true);
    });
    
    _scrollController.addListener(_onScroll);
    
    // Auto-refresh messages every 3 seconds để nhận tin nhắn mới
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        final provider = Provider.of<GroupChatProvider>(context, listen: false);
        provider.loadMessages(groupId: widget.groupId, refresh: true, silent: true);
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels <= 100) {
      final provider = Provider.of<GroupChatProvider>(context, listen: false);
      if (!provider.isLoading(widget.groupId) && 
          provider.hasMore(widget.groupId)) {
        provider.loadMessages(groupId: widget.groupId);
      }
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat nhóm'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
          IconButton(
            icon: const Icon(Icons.attach_file),
            onPressed: _showSharedFiles,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<GroupChatProvider>(
              builder: (context, provider, child) {
                final messages = provider.getMessages(widget.groupId);
                
                if (provider.isLoading(widget.groupId) && messages.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (messages.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Chưa có tin nhắn nào',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Hãy bắt đầu cuộc trò chuyện!',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(8),
                  itemCount: messages.length + 
                      (provider.hasMore(widget.groupId) ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == messages.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    
                    final message = messages[messages.length - 1 - index];
                    return _buildMessageBubble(message);
                  },
                );
              },
            ),
          ),
          _buildReplyPreview(),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildReplyPreview() {
    return Consumer<GroupChatProvider>(
      builder: (context, provider, child) {
        final replyTo = provider.replyToMessage;
        
        if (replyTo == null) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            border: Border(top: BorderSide(color: Colors.grey[300]!)),
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 40,
                color: Colors.blue,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trả lời ${replyTo.displayName}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    Text(
                      replyTo.content,
                      style: const TextStyle(fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: provider.clearReply,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Nhập tin nhắn...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Colors.blue,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(GroupMessage message) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final isMe = message.userId == auth.user?.id;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundImage: message.userAvatar != null
                  ? NetworkImage(message.userAvatar!)
                  : null,
              backgroundColor: Colors.grey[300],
              child: message.userAvatar == null
                  ? Text(
                      message.displayName[0].toUpperCase(),
                      style: const TextStyle(fontSize: 12),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: () => _showMessageOptions(message, isMe),
              child: Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Padding(
                      padding: const EdgeInsets.only(left: 12, bottom: 4),
                      child: Text(
                        message.displayName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  if (message.replyMessage != null)
                    _buildReplyQuote(message.replyMessage!),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.blue : Colors.grey[300],
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (message.isImage || message.isFile)
                          _buildAttachment(message),
                        Text(
                          message.content,
                          style: TextStyle(
                            fontSize: 14,
                            color: isMe ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              message.getTimeAgo(),
                              style: TextStyle(
                                fontSize: 10,
                                color: isMe
                                    ? Colors.white70
                                    : Colors.grey[600],
                              ),
                            ),
                            if (message.isEdited) ...[
                              const SizedBox(width: 4),
                              Text(
                                '(đã sửa)',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontStyle: FontStyle.italic,
                                  color: isMe
                                      ? Colors.white70
                                      : Colors.grey[600],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyQuote(GroupMessage replyMessage) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 30,
            color: Colors.blue,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  replyMessage.displayName,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                Text(
                  replyMessage.content,
                  style: const TextStyle(fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachment(GroupMessage message) {
    if (message.isImage) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            message.attachmentUrl!,
            width: 200,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 200,
                height: 150,
                color: Colors.grey[300],
                child: const Icon(Icons.broken_image, size: 48),
              );
            },
          ),
        ),
      );
    } else if (message.isFile) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.insert_drive_file, size: 24),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.attachmentName ?? 'File',
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  message.formattedSize,
                  style: const TextStyle(fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  void _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    final provider = Provider.of<GroupChatProvider>(context, listen: false);
    final success = await provider.sendMessage(
      groupId: widget.groupId,
      content: content,
    );

    if (success) {
      _messageController.clear();
      _scrollToBottom();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Lỗi khi gửi tin nhắn')),
      );
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _showMessageOptions(GroupMessage message, bool isMe) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('Trả lời'),
              onTap: () {
                Navigator.pop(context);
                final provider =
                    Provider.of<GroupChatProvider>(context, listen: false);
                provider.setReplyTo(message);
              },
            ),
            if (isMe) ...[
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Chỉnh sửa'),
                onTap: () {
                  Navigator.pop(context);
                  _editMessage(message);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Xóa', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _deleteMessage(message);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _editMessage(GroupMessage message) {
    _messageController.text = message.content;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chỉnh sửa tin nhắn'),
        content: TextField(
          controller: _messageController,
          maxLines: 3,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _messageController.clear();
              Navigator.pop(context);
            },
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              final provider =
                  Provider.of<GroupChatProvider>(context, listen: false);
              final success = await provider.editMessage(
                groupId: widget.groupId,
                messageId: message.id,
                content: _messageController.text,
              );
              _messageController.clear();
              if (mounted) Navigator.pop(context);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã cập nhật tin nhắn')),
                );
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _deleteMessage(GroupMessage message) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc muốn xóa tin nhắn này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final provider = Provider.of<GroupChatProvider>(context, listen: false);
      final success = await provider.deleteMessage(
        groupId: widget.groupId,
        messageId: message.id,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa tin nhắn')),
        );
      }
    }
  }

  void _showSearchDialog() {
    final searchController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tìm kiếm tin nhắn'),
        content: TextField(
          controller: searchController,
          decoration: const InputDecoration(
            hintText: 'Nhập từ khóa...',
            prefixIcon: Icon(Icons.search),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              final provider =
                  Provider.of<GroupChatProvider>(context, listen: false);
              final results = await provider.searchMessages(
                groupId: widget.groupId,
                keyword: searchController.text,
              );
              if (mounted) {
                Navigator.pop(context);
                _showSearchResults(results);
              }
            },
            child: const Text('Tìm'),
          ),
        ],
      ),
    );
  }

  void _showSearchResults(List<GroupMessage> results) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Kết quả (${results.length})'),
        content: SizedBox(
          width: double.maxFinite,
          child: results.isEmpty
              ? const Center(child: Text('Không tìm thấy tin nhắn'))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final message = results[index];
                    return ListTile(
                      title: Text(message.displayName),
                      subtitle: Text(message.content),
                      onTap: () => Navigator.pop(context),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showSharedFiles() async {
    final provider = Provider.of<GroupChatProvider>(context, listen: false);
    final files = await provider.getSharedFiles(widget.groupId);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('File đã chia sẻ (${files.length})'),
        content: SizedBox(
          width: double.maxFinite,
          child: files.isEmpty
              ? const Center(child: Text('Chưa có file nào'))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: files.length,
                  itemBuilder: (context, index) {
                    final file = files[index];
                    return ListTile(
                      leading: Icon(
                        file.isImage ? Icons.image : Icons.insert_drive_file,
                      ),
                      title: Text(file.attachmentName ?? 'File'),
                      subtitle: Text(file.formattedSize),
                      trailing: Text(
                        DateFormat('dd/MM').format(file.createdAt),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}
