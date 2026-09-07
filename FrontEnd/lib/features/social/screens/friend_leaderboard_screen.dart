import 'package:flutter/material.dart';

class FriendLeaderboardScreen extends StatefulWidget {
  const FriendLeaderboardScreen({Key? key}) : super(key: key);

  @override
  State<FriendLeaderboardScreen> createState() =>
      _FriendLeaderboardScreenState();
}

class _FriendLeaderboardScreenState extends State<FriendLeaderboardScreen> {
  String _selectedPeriod = 'week';

  final List<LeaderboardUser> _friendsRanking = [
    LeaderboardUser(
      rank: 1,
      name: 'Nguyễn Văn A',
      xp: 4560,
      level: 25,
      avatar: '👤',
      isFriend: true,
      isYou: false,
    ),
    LeaderboardUser(
      rank: 2,
      name: 'Trần Thị B',
      xp: 4320,
      level: 24,
      avatar: '👤',
      isFriend: true,
      isYou: false,
    ),
    LeaderboardUser(
      rank: 3,
      name: 'Bạn (Bạn)',
      xp: 3890,
      level: 22,
      avatar: '😊',
      isFriend: false,
      isYou: true,
    ),
    LeaderboardUser(
      rank: 4,
      name: 'Lê Minh C',
      xp: 3450,
      level: 20,
      avatar: '👤',
      isFriend: true,
      isYou: false,
    ),
    LeaderboardUser(
      rank: 5,
      name: 'Phạm Hữu D',
      xp: 3100,
      level: 19,
      avatar: '👤',
      isFriend: true,
      isYou: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bảng Xếp Hạng Bạn Bè'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Period selector
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildPeriodButton('week', '🗓️ Tuần'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildPeriodButton('month', '📅 Tháng'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildPeriodButton('all', '👑 Mọi Thời'),
                  ),
                ],
              ),
            ),

            // Top 3
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.amber.withValues(alpha: 0.2),
                      Colors.amber.withValues(alpha: 0.05)
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Top 3 Xuất Sắc Nhất',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMedalCard(
                          _friendsRanking[1],
                          '🥈',
                          2,
                        ),
                        _buildMedalCard(
                          _friendsRanking[0],
                          '🥇',
                          1,
                        ),
                        _buildMedalCard(
                          _friendsRanking[2],
                          '🥉',
                          3,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Your rank
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Text(
                      '📍',
                      style: TextStyle(fontSize: 32),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Vị Trí Của Bạn',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Hạng #3',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '3,890 XP',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Ranking list
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bảng Xếp Hạng',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._friendsRanking.map((user) {
                    return _buildLeaderboardTile(user);
                  }).toList(),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Add friend button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showAddFriendDialog();
                  },
                  icon: const Icon(Icons.person_add),
                  label: const Text('Thêm Bạn Bè'),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodButton(String period, String label) {
    final isSelected = _selectedPeriod == period;
    return ElevatedButton(
      onPressed: () {
        setState(() => _selectedPeriod = period);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue : Colors.grey[300],
        foregroundColor: isSelected ? Colors.white : Colors.black,
      ),
      child: Text(label),
    );
  }

  Widget _buildMedalCard(LeaderboardUser user, String medal, int rank) {
    return Column(
      children: [
        Text(medal, style: const TextStyle(fontSize: 48)),
        const SizedBox(height: 8),
        Text(
          user.name,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          '${user.xp} XP',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.orange,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardTile(LeaderboardUser user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: user.isYou ? Colors.blue.withValues(alpha: 0.1) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: user.isYou ? Colors.blue : Colors.grey.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 40,
            child: Text(
              '#${user.rank}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _getRankColor(user.rank),
              ),
            ),
          ),

          // Avatar & Name
          Text(
            user.avatar,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: user.isYou ? Colors.blue : Colors.black,
                  ),
                ),
                Text(
                  'Cấp ${user.level}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          // XP
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${user.xp}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.orange,
                ),
              ),
              const Text(
                'XP',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                ),
              ),
            ],
          ),

          // Action button
          const SizedBox(width: 12),
          SizedBox(
            width: 32,
            height: 32,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Xem profil ${user.name}')),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
              ),
              child: const Text(
                '→',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey;
      case 3:
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  void _showAddFriendDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm Bạn'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Nhập tên hoặc ID người dùng',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Đã gửi lời mời cho ${controller.text}',
                  ),
                ),
              );
            },
            child: const Text('Gửi Lời Mời'),
          ),
        ],
      ),
    );
  }
}

class LeaderboardUser {
  final int rank;
  final String name;
  final int xp;
  final int level;
  final String avatar;
  final bool isFriend;
  final bool isYou;

  LeaderboardUser({
    required this.rank,
    required this.name,
    required this.xp,
    required this.level,
    required this.avatar,
    required this.isFriend,
    required this.isYou,
  });
}
