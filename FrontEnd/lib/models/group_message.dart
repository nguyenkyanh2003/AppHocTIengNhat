class GroupMessage {
  final String id;
  final String groupId;
  final String userId;
  final String content;
  final String type;
  final String? attachmentUrl;
  final String? attachmentName;
  final int? attachmentSize;
  final String? replyTo;
  final bool isDeleted;
  final bool isEdited;
  final DateTime? editedAt;
  final DateTime createdAt;
  
  // User info (nếu được populate)
  final String? userName;
  final String? userAvatar;
  final String? userUsername;

  // Reply message info (nếu được populate)
  final GroupMessage? replyMessage;

  GroupMessage({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.content,
    required this.type,
    this.attachmentUrl,
    this.attachmentName,
    this.attachmentSize,
    this.replyTo,
    required this.isDeleted,
    required this.isEdited,
    this.editedAt,
    required this.createdAt,
    this.userName,
    this.userAvatar,
    this.userUsername,
    this.replyMessage,
  });

  factory GroupMessage.fromJson(Map<String, dynamic> json) {
    final userData = json['user_id'];
    final replyData = json['reply_to'];
    
    return GroupMessage(
      id: json['_id'] ?? json['id'],
      groupId: json['group_id'] is Map 
          ? json['group_id']['_id'] 
          : json['group_id'].toString(),
      userId: userData is Map ? userData['_id'] : userData.toString(),
      content: json['content'] ?? '',
      type: json['type'] ?? 'TEXT',
      attachmentUrl: json['attachment_url'],
      attachmentName: json['attachment_name'],
      attachmentSize: json['attachment_size'],
      replyTo: replyData is Map ? replyData['_id'] : replyData?.toString(),
      isDeleted: json['is_deleted'] ?? false,
      isEdited: json['is_edited'] ?? false,
      editedAt: json['edited_at'] != null 
          ? DateTime.parse(json['edited_at']) 
          : null,
      createdAt: DateTime.parse(
        json['created_at'] ?? json['createdAt'] ?? DateTime.now().toIso8601String()
      ),
      userName: userData is Map ? userData['full_name'] : null,
      userAvatar: userData is Map ? userData['avatar'] : null,
      userUsername: userData is Map ? userData['username'] : null,
      replyMessage: replyData is Map ? GroupMessage.fromJson(Map<String, dynamic>.from(replyData)) : null,
    );
  }

  bool get isText => type == 'TEXT';
  bool get isImage => type == 'IMAGE';
  bool get isFile => type == 'FILE';
  bool get isSystem => type == 'SYSTEM';

  String get displayName => userName ?? userUsername ?? 'User';

  String get formattedSize {
    if (attachmentSize == null) return '';
    final kb = attachmentSize! / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(1)} MB';
  }

  String getTimeAgo() {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inSeconds < 60) {
      return 'Vừa xong';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return '${(difference.inDays / 7).floor()} tuần trước';
    }
  }
}
