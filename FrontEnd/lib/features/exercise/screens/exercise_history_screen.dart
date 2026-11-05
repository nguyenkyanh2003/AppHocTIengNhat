import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/exercise_provider.dart';
import '../../../shared/widgets/content_pane.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../widgets/exercise_history_card.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../core/state/view_state.dart';
import '../models/exercise.dart';

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
      _loadHistory();
    });
  }

  Future<void> _loadHistory() async {
    await context.read<ExerciseProvider>().loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Lịch sử làm bài',
      onRefresh: _loadHistory,
      body: ContentWidthLimit(
        child: RefreshIndicator(
          onRefresh: _loadHistory,
          child: _buildHistoryList(),
        ),
      ),
    );
  }

  Widget _buildHistoryList() {
    return Consumer<ExerciseProvider>(
      builder: (context, provider, child) => AsyncView<List<ExerciseResult>>(
        state: ViewState.fromLegacy(
          isLoading: provider.isLoading,
          error: provider.error,
          value: provider.history,
          isEmpty: provider.history.isEmpty,
        ),
        onRetry: _loadHistory,
        isEmpty: (history) => history.isEmpty,
        emptyTitle: 'Chưa có lịch sử làm bài',
        emptyMessage: 'Hãy thử làm một bài tập nhé!',
        emptyIcon: Icons.history,
        builder: (context, history) => ListView.builder(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: history.length,
          itemBuilder: (context, index) =>
              ExerciseHistoryCard(result: history[index]),
        ),
      ),
    );
  }
}
