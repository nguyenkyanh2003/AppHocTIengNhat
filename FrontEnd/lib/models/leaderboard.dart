class LeaderboardEntry {
  final int rank;
  final String userId;
  final String username;
  final String? fullName;
  final String? avatar;
  final int totalXP;
  final int level;
  final int currentStreak;
  final int longestStreak;

  LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.username,
    this.fullName,
    this.avatar,
    required this.totalXP,
    required this.level,
    required this.currentStreak,
    required this.longestStreak,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? {};
    
    return LeaderboardEntry(
      rank: json['rank'] ?? 0,
      userId: user['_id'] ?? '',
      username: user['username'] ?? '',
      fullName: user['full_name'],
      avatar: user['avatar'],
      totalXP: json['total_xp'] ?? 0,
      level: json['level'] ?? 1,
      currentStreak: json['current_streak'] ?? 0,
      longestStreak: json['longest_streak'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rank': rank,
      'user': {
        '_id': userId,
        'username': username,
        'full_name': fullName,
        'avatar': avatar,
      },
      'total_xp': totalXP,
      'level': level,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
    };
  }

  String get displayName => fullName ?? username;
  
  String get avatarInitial => 
      (fullName ?? username).isNotEmpty 
          ? (fullName ?? username)[0].toUpperCase() 
          : 'U';
}
