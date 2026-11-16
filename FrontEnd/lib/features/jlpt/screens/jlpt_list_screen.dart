import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/content_pane.dart';
import '../../../shared/widgets/level_badge.dart';
import '../../../shared/widgets/paged_list_view.dart';
import '../models/jlpt_models.dart';
import '../providers/jlpt_provider.dart';

class JLPTListScreen extends StatefulWidget {
  const JLPTListScreen({super.key});

  @override
  State<JLPTListScreen> createState() => _JLPTListScreenState();
}

class _JLPTListScreenState extends State<JLPTListScreen> {
  static const _levels = ['N5', 'N4', 'N3', 'N2', 'N1'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<JLPTProvider>().loadExams();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<JLPTProvider>();
    return AppScaffold(
      title: 'Luyện thi JLPT',
      actions: [
        IconButton(
          tooltip: 'Luyện nhanh',
          icon: const Icon(Icons.play_circle_outline),
          onPressed: () => context.push('/jlpt-practice'),
        ),
      ],
      body: ContentWidthLimit(
        child: Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Wrap(
                spacing: AppSpacing.sm,
                children: [
                  for (final level in [null, ..._levels])
                    FilterChip(
                      label: Text(level ?? 'Tất cả'),
                      selected: provider.level == level,
                      onSelected: (_) => provider.loadExams(level: level),
                    ),
                ],
              ),
            ),
            Expanded(
              child: AsyncView<List<JLPTExamBrief>>(
                state: provider.exams,
                onRetry: provider.reload,
                isEmpty: (exams) => exams.isEmpty,
                emptyTitle: 'Chưa có đề thi nào',
                emptyMessage: 'Thử chọn cấp độ khác.',
                emptyIcon: Icons.assignment_outlined,
                builder: (context, exams) => RefreshIndicator(
                  onRefresh: provider.reload,
                  child: PagedListView<JLPTExamBrief>(
                    items: exams,
                    hasMore: provider.hasMore,
                    isLoadingMore: provider.isLoadingMore,
                    loadMoreError: provider.loadMoreError,
                    onLoadMore: provider.loadMore,
                    itemBuilder: (context, exam) => _ExamCard(exam: exam),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExamCard extends StatelessWidget {
  const _ExamCard({required this.exam});

  final JLPTExamBrief exam;

  @override
  Widget build(BuildContext context) {
    final description = exam.description;
    final last = exam.lastResult;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: ListTile(
        title: Text(exam.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (description != null) Text(description),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                LevelBadge(exam.level, compact: true),
                Text('Thời gian: ${exam.timeLimit} phút'),
              ],
            ),
            Text('Số câu: ${exam.totalQuestions} | Điểm: ${exam.totalScore}'),
            if (last != null) Text('Điểm gần nhất: ${last.score} (${last.isPassed ? 'Đỗ' : 'Trượt'})'),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => context.push(Uri(path: '/jlpt/${exam.id}/exam', queryParameters: {'title': exam.title}).toString()),
      ),
    );
  }
}
