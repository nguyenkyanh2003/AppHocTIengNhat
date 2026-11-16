import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/streak_provider.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/content_pane.dart';
import '../../../app/theme/app_typography.dart';
import '../widgets/leaderboard_item.dart';
import '../widgets/leaderboard_user_rank_card.dart';
import '../../../shared/widgets/async_view.dart';
import '../models/leaderboard.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadLeaderboard();
    });
  }

  Future<void> _loadLeaderboard() async {
    final provider = Provider.of<StreakProvider>(context, listen: false);
    await provider.loadLeaderboard(period: _selectedPeriod);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Bảng xếp hạng',
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
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 140),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      _periods[_selectedPeriod]!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: AppTypography.bodySmall),
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ),
      ],
      body: ContentWidthLimit(
        child: Consumer<StreakProvider>(
          builder: (context, provider, child) {
            return AsyncView<Leaderboard>(
              state: provider.leaderboard,
              onRetry: _loadLeaderboard,
              isEmpty: (board) => board.entries.isEmpty,
              emptyTitle: 'Chưa có dữ liệu bảng xếp hạng',
              emptyIcon: Icons.leaderboard_outlined,
              builder: (context, board) => RefreshIndicator(
                onRefresh: _loadLeaderboard,
                child: Column(
                  children: [
                    if (board.userRank case final rank?) LeaderboardUserRankCard(rank: rank),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: board.entries.length,
                        itemBuilder: (context, index) => LeaderboardItem(entry: board.entries[index]),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
