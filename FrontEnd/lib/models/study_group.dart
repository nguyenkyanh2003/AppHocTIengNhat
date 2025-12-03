class StudyGroupMember {
  final String userId;
  final String role;
  final DateTime joinedAt;
  final String? fullName;
  final String? username;
  final String? avatar;
  final String? email;

  StudyGroupMember({
    required this.userId,
    required this.role,
    required this.joinedAt,
    this.fullName,
    this.username,
    this.avatar,
    this.email,
  });

  factory StudyGroupMember.fromJson(Map<String, dynamic> json) {
    final userData = json['user_id'];
    return StudyGroupMember(
      userId: userData is Map ? userData['_id'] : userData.toString(),
      role: json['role'] ?? 'member',
      joinedAt: DateTime.parse(json['joined_at'] ?? DateTime.now().toIso8601String()),
      fullName: userData is Map ? userData['full_name'] : null,
      username: userData is Map ? userData['username'] : null,
      avatar: userData is Map ? userData['avatar'] : null,
      email: userData is Map ? userData['email'] : null,
    );
  }

  bool get isAdmin => role == 'admin';
}

class StudyGroup {
  final String id;
  final String name;
  final String? description;
  final String? avatar;
  final String level;
  final String creatorId;
  final List<StudyGroupMember> members;
  final int memberCount;
  final bool isActive;
  final bool isPrivate;
  final int maxMembers;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Creator info (nếu được populate)
  final String? creatorName;
  final String? creatorAvatar;
  final String? creatorUsername;

  StudyGroup({
    required this.id,
    required this.name,
    this.description,
    this.avatar,
    required this.level,
    required this.creatorId,
    required this.members,
    required this.memberCount,
    required this.isActive,
    required this.isPrivate,
    required this.maxMembers,
    required this.createdAt,
    required this.updatedAt,
    this.creatorName,
    this.creatorAvatar,
    this.creatorUsername,
  });

  factory StudyGroup.fromJson(Map<String, dynamic> json) {
    final creatorData = json['creator_id'];
    
    // Convert relative avatar path to full URL
    String? avatarUrl = json['avatar'];
    if (avatarUrl != null && avatarUrl.startsWith('/uploads/')) {
      avatarUrl = 'http://localhost:3000$avatarUrl';
    }
    
    return StudyGroup(
      id: json['_id'] ?? json['id'],
      name: json['name'] ?? '',
      description: json['description'],
      avatar: avatarUrl ?? 'https://via.placeholder.com/150',
      level: json['level'] ?? 'ALL',
      creatorId: creatorData is Map ? creatorData['_id'] : creatorData.toString(),
      members: (json['members'] as List?)
          ?.map((m) => StudyGroupMember.fromJson(m))
          .toList() ?? [],
      memberCount: json['member_count'] ?? 0,
      isActive: json['is_active'] ?? true,
      isPrivate: json['is_private'] ?? false,
      maxMembers: json['max_members'] ?? 50,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      creatorName: creatorData is Map ? creatorData['full_name'] : null,
      creatorAvatar: creatorData is Map ? creatorData['avatar'] : null,
      creatorUsername: creatorData is Map ? creatorData['username'] : null,
    );
  }

  bool isFull() => memberCount >= maxMembers;
  
  bool isMember(String userId) {
    return members.any((m) => m.userId == userId);
  }

  bool isAdmin(String userId) {
    return members.any((m) => m.userId == userId && m.isAdmin);
  }

  bool isCreator(String userId) {
    return creatorId == userId;
  }

  String get levelDisplay {
    switch (level) {
      case 'ALL':
        return 'Tất cả cấp độ';
      case 'N1':
      case 'N2':
      case 'N3':
      case 'N4':
      case 'N5':
        return 'JLPT $level';
      default:
        return level;
    }
  }

  String get memberCountDisplay => '$memberCount/$maxMembers thành viên';
}

class GroupStats {
  final int totalMessages;
  final int todayMessages;
  final int activeMembers;
  final Map<String, int> messagesByUser;

  GroupStats({
    required this.totalMessages,
    required this.todayMessages,
    required this.activeMembers,
    required this.messagesByUser,
  });

  factory GroupStats.fromJson(Map<String, dynamic> json) {
    return GroupStats(
      totalMessages: json['total_messages'] ?? 0,
      todayMessages: json['today_messages'] ?? 0,
      activeMembers: json['active_members'] ?? 0,
      messagesByUser: Map<String, int>.from(json['messages_by_user'] ?? {}),
    );
  }
}
