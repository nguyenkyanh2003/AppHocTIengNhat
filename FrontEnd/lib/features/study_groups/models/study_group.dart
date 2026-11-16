import '../../../core/network/api_client.dart';
import '../../../core/network/api_envelope.dart';

/// Một thành viên trong nhóm; thông tin người dùng do server populate.
class StudyGroupMember {
  const StudyGroupMember({
    required this.userId,
    required this.role,
    required this.joinedAt,
    this.fullName,
    this.username,
    this.avatar,
    this.email,
  });

  final String userId;
  final String role;
  final DateTime joinedAt;
  final String? fullName;
  final String? username;
  final String? avatar;
  final String? email;

  bool get isAdmin => role == 'admin';

  factory StudyGroupMember.fromJson(JsonObject json) {
    final user = json['user_id'];
    final profile = user is Map ? user : const {};
    return StudyGroupMember(
      userId: user is Map ? '${user['_id']}' : '$user',
      role: json['role'] as String? ?? 'member',
      joinedAt: _dateOf(json['joined_at']),
      fullName: profile['HoTen'] as String?,
      username: profile['TenDangNhap'] as String?,
      avatar: ApiClient.resolveAssetUrl(profile['AnhDaiDien'] as String?),
      email: profile['Email'] as String?,
    );
  }
}

class StudyGroup {
  const StudyGroup({
    required this.id,
    required this.name,
    required this.creatorId,
    this.description,
    this.avatar,
    this.level = 'ALL',
    this.members = const [],
    this.memberCount = 0,
    this.isPrivate = false,
    this.maxMembers = 50,
    this.createdAt,
    this.creatorName,
    this.creatorAvatar,
    this.creatorUsername,
  });

  final String id;
  final String name;
  final String? description;
  final String? avatar;
  final String level;
  final String creatorId;

  /// Rỗng ở danh sách; chỉ chi tiết mới kèm thành viên.
  final List<StudyGroupMember> members;
  final int memberCount;
  final bool isPrivate;
  final int maxMembers;
  final DateTime? createdAt;
  final String? creatorName;
  final String? creatorAvatar;
  final String? creatorUsername;

  factory StudyGroup.fromJson(JsonObject json) {
    final creator = json['creator_id'];
    final profile = creator is Map ? creator : const {};
    final avatar = ApiClient.resolveAssetUrl(json['avatar'] as String?);
    return StudyGroup(
      id: json['_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      // Model backend gán sẵn ảnh mẫu này cho nhóm chưa có ảnh.
      avatar: avatar?.contains('via.placeholder.com') == true ? null : avatar,
      level: json['level'] as String? ?? 'ALL',
      creatorId: creator is Map ? '${creator['_id']}' : '${creator ?? ''}',
      members: [
        for (final member in json['members'] as List? ?? const [])
          if (member is Map) StudyGroupMember.fromJson(Map<String, dynamic>.from(member)),
      ],
      memberCount: (json['member_count'] as num?)?.toInt() ?? 0,
      isPrivate: json['is_private'] as bool? ?? false,
      maxMembers: (json['max_members'] as num?)?.toInt() ?? 50,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      creatorName: profile['HoTen'] as String?,
      creatorAvatar: ApiClient.resolveAssetUrl(profile['AnhDaiDien'] as String?),
      creatorUsername: profile['TenDangNhap'] as String?,
    );
  }

  bool isFull() => memberCount >= maxMembers;

  bool isMember(String userId) => members.any((member) => member.userId == userId);

  bool isAdmin(String userId) => members.any((member) => member.userId == userId && member.isAdmin);

  bool isCreator(String userId) => creatorId == userId;

  String get levelDisplay => switch (level) {
        'ALL' => 'Tất cả cấp độ',
        'N1' || 'N2' || 'N3' || 'N4' || 'N5' => 'JLPT $level',
        _ => level,
      };

  String get memberCountDisplay => '$memberCount/$maxMembers thành viên';
}

/// Nội dung người dùng nhập khi tạo hoặc sửa nhóm; hai việc gửi cùng hình dạng.
class StudyGroupDraft {
  const StudyGroupDraft({
    required this.name,
    this.description = '',
    this.level = 'ALL',
    this.isPrivate = false,
    this.maxMembers = 50,
  });

  final String name;
  final String description;
  final String level;
  final bool isPrivate;
  final int maxMembers;

  JsonObject toJson() => {
        'name': name,
        'description': description,
        'level': level,
        'is_private': isPrivate,
        'max_members': maxMembers,
      };
}

/// Số liệu của một nhóm; "hoạt động" là đăng nhập trong 24 giờ qua.
class GroupStats {
  const GroupStats({required this.groupId, this.memberCount = 0, this.adminCount = 0, this.activeMembers = 0});

  final String groupId;
  final int memberCount;
  final int adminCount;
  final int activeMembers;

  factory GroupStats.fromJson(String groupId, JsonObject json) => GroupStats(
        groupId: groupId,
        memberCount: (json['member_count'] as num?)?.toInt() ?? 0,
        adminCount: (json['admin_count'] as num?)?.toInt() ?? 0,
        activeMembers: (json['active_members'] as num?)?.toInt() ?? 0,
      );
}

DateTime _dateOf(Object? value) => DateTime.tryParse(value as String? ?? '') ?? DateTime.now();
