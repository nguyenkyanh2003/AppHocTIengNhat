import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_view.dart';

/// Backend chưa có khái niệm bạn bè nên màn này không có dữ liệu thật để hiện.
///
/// Giữ đường dẫn để liên kết cũ không chết, nhưng nói thẳng là chưa có tính năng
/// và dẫn sang bảng xếp hạng chung, thay vì hiện một bảng tên giả.
class FriendLeaderboardScreen extends StatelessWidget {
  const FriendLeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Bảng xếp hạng bạn bè',
      body: EmptyStateView(
        title: 'Chưa có tính năng kết bạn',
        message: 'Hiện ứng dụng có bảng xếp hạng chung cho mọi người học.',
        icon: Icons.group_outlined,
        action: FilledButton(
          onPressed: () => context.go('/leaderboard'),
          child: const Text('Xem bảng xếp hạng chung'),
        ),
      ),
    );
  }
}
