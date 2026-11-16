import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/content_pane.dart';
import '../models/exercise.dart';
import '../providers/exercise_provider.dart';
import '../widgets/exercise_filters.dart';
import '../widgets/exercise_list_card.dart';

/// Danh sách bài tập: mọi bài, hoặc bài của một bài học khi có [lessonId].
class ExerciseListScreen extends StatefulWidget {
  const ExerciseListScreen({super.key, this.lessonId, this.lessonTitle});

  final String? lessonId;
  final String? lessonTitle;

  @override
  State<ExerciseListScreen> createState() => _ExerciseListScreenState();
}

class _ExerciseListScreenState extends State<ExerciseListScreen> {
  static const _all = 'Tất cả';

  /// Lọc ngay trên danh sách đã tải; chọn cấp độ thì bỏ lọc loại và ngược lại.
  String _level = _all;
  String _type = _all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() => context.read<ExerciseProvider>().loadExercises(lessonId: widget.lessonId);

  bool _matches(Exercise exercise) =>
      (_level == _all || exercise.level == _level) && (_type == _all || exercise.type == _type);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExerciseProvider>();
    final filtered = _level != _all || _type != _all;
    return AppScaffold(
      title: widget.lessonTitle == null ? 'Luyện tập' : 'Bài tập: ${widget.lessonTitle}',
      onRefresh: _load,
      actions: [
        IconButton(
          icon: const Icon(Icons.history),
          tooltip: 'Lịch sử làm bài',
          onPressed: () => context.push('/exercise-history'),
        ),
      ],
      body: ContentWidthLimit(
        child: Column(
          children: [
            ExerciseFilters(
              selectedLevel: _level,
              selectedType: _type,
              selectLevel: (level) => setState(() {
                _level = level;
                _type = _all;
              }),
              selectType: (type) => setState(() {
                _type = type;
                _level = _all;
              }),
            ),
            Expanded(
              child: AsyncView<List<Exercise>>(
                state: provider.exercises.map((exercises) => exercises.where(_matches).toList()),
                onRetry: _load,
                isEmpty: (exercises) => exercises.isEmpty,
                emptyTitle: filtered ? 'Không tìm thấy bài tập phù hợp' : 'Chưa có bài tập nào',
                emptyIcon: Icons.quiz_outlined,
                builder: (context, exercises) => RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: AppSpacing.page,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: exercises.length,
                    itemBuilder: (context, index) => ExerciseListCard(exercise: exercises[index]),
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
