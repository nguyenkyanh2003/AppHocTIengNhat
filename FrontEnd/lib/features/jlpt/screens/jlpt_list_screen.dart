import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/jlpt_provider.dart';
import '../models/jlpt_models.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/content_pane.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../core/state/view_state.dart';
import '../../../shared/widgets/level_badge.dart';
import '../../../app/theme/app_tokens.dart';

class JLPTListScreen extends StatefulWidget {
  const JLPTListScreen({super.key});

  @override
  State<JLPTListScreen> createState() => _JLPTListScreenState();
}

class _JLPTListScreenState extends State<JLPTListScreen> {
  String? _level;
  int page = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JLPTProvider>().loadExams(refresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Luyện thi JLPT',
      actions: [
        IconButton(
          icon: const Icon(Icons.play_circle_outline),
          onPressed: () {
            context.push('/jlpt-practice');
          },
        )
      ],
      body: ContentWidthLimit(
        child: Consumer<JLPTProvider>(
          builder: (context, provider, _) {
            return Column(
              children: [
                _buildLevelChips(),
                Expanded(
                  child: AsyncView<List<JLPTExamBrief>>(
                    state: ViewState.fromLegacy(
                      isLoading: provider.isLoading,
                      error: provider.error,
                      value: provider.exams,
                      isEmpty: provider.exams.isEmpty,
                    ),
                    onRetry: () =>
                        provider.loadExams(refresh: true, level: _level),
                    isEmpty: (exams) => exams.isEmpty,
                    emptyTitle: 'Chưa có đề thi nào',
                    emptyMessage: 'Thử chọn cấp độ khác.',
                    emptyIcon: Icons.assignment_outlined,
                    builder: (context, exams) => RefreshIndicator(
                      onRefresh: () =>
                          provider.loadExams(refresh: true, level: _level),
                      child: ListView.builder(
                        itemCount: exams.length,
                        itemBuilder: (context, index) =>
                            _ExamCard(exam: exams[index]),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLevelChips() {
    const levels = ['N5', 'N4', 'N3', 'N2', 'N1'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          FilterChip(
            label: const Text('Tất cả'),
            selected: _level == null,
            onSelected: (_) => _onLevel(null),
          ),
          ...levels.map((lv) => Padding(
                padding: const EdgeInsets.only(left: 8),
                child: FilterChip(
                  label: Text(lv),
                  selected: _level == lv,
                  onSelected: (_) => _onLevel(lv),
                ),
              )),
        ],
      ),
    );
  }

  void _onLevel(String? lv) {
    setState(() => _level = lv);
    context.read<JLPTProvider>().loadExams(refresh: true, level: lv);
  }
}

class _ExamCard extends StatelessWidget {
  final JLPTExamBrief exam;
  const _ExamCard({required this.exam});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: ListTile(
        title: Text(exam.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (exam.description != null) Text(exam.description!),
            const SizedBox(height: 4),
            Wrap(
              spacing: AppSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                LevelBadge(exam.level, compact: true),
                Text('Thời gian: ${exam.timeLimit} phút'),
              ],
            ),
            Text('Số câu: ${exam.totalQuestions} | Điểm: ${exam.totalScore}'),
            if (exam.lastResult != null)
              Text(
                  'Điểm gần nhất: ${exam.lastResult!.score} (${exam.lastResult!.isPassed ? 'Đỗ' : 'Trượt'})'),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          context.push(
            Uri(
              path: '/jlpt/${exam.id}/exam',
              queryParameters: {'title': exam.title},
            ).toString(),
          );
        },
      ),
    );
  }
}
