import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/content_pane.dart';
import '../../../shared/widgets/paged_list_view.dart';
import '../models/exercise.dart';
import '../providers/exercise_provider.dart';
import '../widgets/exercise_history_card.dart';

class ExerciseHistoryScreen extends StatefulWidget {
  const ExerciseHistoryScreen({super.key});

  @override
  State<ExerciseHistoryScreen> createState() => _ExerciseHistoryScreenState();
}

class _ExerciseHistoryScreenState extends State<ExerciseHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ExerciseProvider>().loadHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExerciseProvider>();
    return AppScaffold(
      title: 'Lịch sử làm bài',
      onRefresh: provider.loadHistory,
      body: ContentWidthLimit(
        child: AsyncView<List<ExerciseResult>>(
          state: provider.history,
          onRetry: provider.loadHistory,
          isEmpty: (history) => history.isEmpty,
          emptyTitle: 'Chưa có lịch sử làm bài',
          emptyMessage: 'Hãy thử làm một bài tập nhé!',
          emptyIcon: Icons.history,
          builder: (context, history) => RefreshIndicator(
            onRefresh: provider.loadHistory,
            child: PagedListView<ExerciseResult>(
              items: history,
              padding: AppSpacing.page,
              hasMore: provider.hasMoreHistory,
              isLoadingMore: provider.isLoadingMoreHistory,
              loadMoreError: provider.loadMoreHistoryError,
              onLoadMore: provider.loadMore,
              itemBuilder: (context, result) => ExerciseHistoryCard(result: result),
            ),
          ),
        ),
      ),
    );
  }
}
