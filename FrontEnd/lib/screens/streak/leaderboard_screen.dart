import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/streak_provider.dart';
import '../../models/leaderboard.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({Key? key}) : super(key: key);

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  String _selectedPeriod = 'all';
  
  final Map<String, String> _periods = {
    'all': 'Tất cả thời gian',
    'month': 'Tháng này',
    'week': 'Tuần này',
  };

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    final provider = Provider.of<StreakProvider>(context, listen: false);
    await provider.loadLeaderboard(period: _selectedPeriod);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bảng xếp hạng'),
        actions: [
          PopupMenuButton<String>(
            initialValue: _selectedPeriod,
            onSelected: (value) {
              setState(() {
                _selectedPeriod = value;
              });
              _loadLeaderboard();
            },
            itemBuilder: (context) {
              return _periods.entries.map((entry) {
                return PopupMenuItem<String>(
                  value: entry.key,
                  child: Text(entry.value),
                );
              }).toList();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    _periods[_selectedPeriod]!,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Consumer<StreakProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.leaderboard.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.leaderboard.isEmpty) {
            return const Center(
              child: Text('Chưa có dữ liệu bảng xếp hạng'),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadLeaderboard,
            child: Column(
              children: [
                if (provider.userRank != null) _buildUserRankCard(provider),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.leaderboard.length,
                    itemBuilder: (context, index) {
                      return _buildLeaderboardItem(
                        provider.leaderboard[index],
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildUserRankCard(StreakProvider provider) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Hạng của bạn',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '#${provider.userRank}',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardItem(LeaderboardEntry entry) {
    final isTopThree = entry.rank <= 3;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isTopThree ? 4 : 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: isTopThree
              ? LinearGradient(
                  colors: _getRankGradient(entry.rank),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Rank badge
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isTopThree
                      ? Colors.white.withOpacity(0.3)
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    _getRankIcon(entry.rank),
                    style: TextStyle(
                      fontSize: isTopThree ? 28 : 20,
                      fontWeight: FontWeight.bold,
                      color: isTopThree ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Avatar
              CircleAvatar(
                radius: 25,
                backgroundColor: isTopThree
                    ? Colors.white.withOpacity(0.3)
                    : Colors.grey[300],
                child: entry.avatar != null
                    ? ClipOval(
                        child: Image.network(
                          entry.avatar!,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Text(
                              entry.avatarInitial,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isTopThree ? Colors.white : Colors.black54,
                              ),
                            );
                          },
                        ),
                      )
                    : Text(
                        entry.avatarInitial,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isTopThree ? Colors.white : Colors.black54,
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              
              // User info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.displayName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isTopThree ? Colors.white : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildInfoChip(
                          '🔥 ${entry.currentStreak}',
                          isTopThree,
                        ),
                        const SizedBox(width: 8),
                        _buildInfoChip(
                          'Lv.${entry.level}',
                          isTopThree,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // XP
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${entry.totalXP}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isTopThree ? Colors.white : Theme.of(context).primaryColor,
                    ),
                  ),
                  Text(
                    'XP',
                    style: TextStyle(
                      fontSize: 12,
                      color: isTopThree ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String text, bool isTopThree) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isTopThree
            ? Colors.white.withOpacity(0.2)
            : Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: isTopThree ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _getRankIcon(int rank) {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '#$rank';
    }
  }

  List<Color> _getRankGradient(int rank) {
    switch (rank) {
      case 1:
        return [const Color(0xFFFFD700), const Color(0xFFFFAA00)];
      case 2:
        return [const Color(0xFFC0C0C0), const Color(0xFF999999)];
      case 3:
        return [const Color(0xFFCD7F32), const Color(0xFF8B4513)];
      default:
        return [Colors.grey, Colors.grey];
    }
  }
}
