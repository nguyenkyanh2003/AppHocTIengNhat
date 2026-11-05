import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/exercise_provider.dart';
import '../../../shared/widgets/content_pane.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../widgets/exercise_filters.dart';
import '../widgets/exercise_list_card.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../core/state/view_state.dart';

class ExerciseListScreen extends StatefulWidget {
  final String? lessonId;
  final String? lessonTitle;

  const ExerciseListScreen({
    super.key,
    this.lessonId,
    this.lessonTitle,
  });

  @override
  State<ExerciseListScreen> createState() => _ExerciseListScreenState();
}

class _ExerciseListScreenState extends State<ExerciseListScreen> {
  String _selectedLevel = '';
  String _selectedType = '';
  List<dynamic> _allExercises = [];
  List<dynamic> _filteredExercises = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExercises();
    });
  }

  Future<void> _loadExercises() async {
    final provider = context.read<ExerciseProvider>();
    if (widget.lessonId == null) {
      await provider.loadAllExercises();
    } else {
      await provider.loadExercisesByLesson(widget.lessonId!);
    }

    if (!mounted) return;
    setState(() {
      _allExercises = provider.exercises;
      _applyFilters();
    });
  }

  void _applyFilters() {
    List<dynamic> filtered = List.from(_allExercises);

    // Lọc theo level
    if (_selectedLevel.isNotEmpty && _selectedLevel != 'Tất cả') {
      filtered = filtered.where((ex) => ex.level == _selectedLevel).toList();
    }

    // Lọc theo type
    if (_selectedType.isNotEmpty && _selectedType != 'Tất cả') {
      filtered = filtered.where((ex) => ex.type == _selectedType).toList();
    }

    setState(() {
      _filteredExercises = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: widget.lessonTitle == null
          ? 'Luyện tập'
          : 'Bài tập: ${widget.lessonTitle}',
      onRefresh: _loadExercises,
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
                selectedLevel: _selectedLevel,
                selectedType: _selectedType,
                selectLevel: _selectLevel,
                selectType: _selectType),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadExercises,
                child: _buildExerciseList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseList() {
    return Consumer<ExerciseProvider>(
      builder: (context, provider, child) => AsyncView<List<dynamic>>(
        state: ViewState.fromLegacy(
          isLoading: provider.isLoading,
          error: provider.error,
          value: _filteredExercises,
          isEmpty: _filteredExercises.isEmpty,
        ),
        onRetry: _loadExercises,
        isEmpty: (exercises) => exercises.isEmpty,
        emptyTitle: _allExercises.isEmpty
            ? 'Chưa có bài tập nào'
            : 'Không tìm thấy bài tập phù hợp',
        emptyIcon: Icons.quiz_outlined,
        builder: (context, exercises) => ListView.builder(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: exercises.length,
          itemBuilder: (context, index) =>
              ExerciseListCard(exercise: exercises[index]),
        ),
      ),
    );
  }

  void _selectLevel(String level) {
    setState(() {
      _selectedLevel = level == 'Tất cả' ? '' : level;
      _selectedType = '';
      _applyFilters();
    });
  }

  void _selectType(String type) {
    setState(() {
      _selectedType = type == 'Tất cả' ? '' : type;
      _selectedLevel = '';
      _applyFilters();
    });
  }
}
