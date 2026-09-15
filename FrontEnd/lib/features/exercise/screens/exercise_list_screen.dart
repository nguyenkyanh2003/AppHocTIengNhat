import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/exercise_provider.dart';
import '../../../shared/widgets/content_pane.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/app_tokens.dart';

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

  final List<String> _levels = ['Tất cả', 'N5', 'N4', 'N3', 'N2', 'N1'];
  final List<String> _types = [
    'Tất cả',
    'Từ vựng',
    'Ngữ pháp',
    'Kanji',
    'Tổng hợp'
  ];

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
            _buildFilters(),
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

  Widget _buildFilters() {
    return Column(
      children: [
        _buildLevelFilter(),
        const SizedBox(height: 8),
        _buildTypeFilter(),
      ],
    );
  }

  Widget _buildLevelFilter() {
    return SizedBox(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _levels.length,
        itemBuilder: (context, index) {
          final level = _levels[index];
          final isSelected = _selectedLevel == level ||
              (_selectedLevel.isEmpty && level == 'Tất cả');

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(level),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedLevel = level == 'Tất cả' ? '' : level;
                  _selectedType = '';
                  _applyFilters();
                });
              },
              backgroundColor: Colors.white,
              selectedColor: AppColors.primaryLight,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.border,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTypeFilter() {
    return SizedBox(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _types.length,
        itemBuilder: (context, index) {
          final type = _types[index];
          final isSelected = _selectedType == type ||
              (_selectedType.isEmpty && type == 'Tất cả');

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(type),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedType = type == 'Tất cả' ? '' : type;
                  _selectedLevel = '';
                  _applyFilters();
                });
              },
              backgroundColor: Colors.white,
              selectedColor: AppColors.success,
              labelStyle: TextStyle(
                color:
                    isSelected ? AppColors.success : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              side: BorderSide(
                color:
                    isSelected ? AppColors.success : AppColors.border,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildExerciseList() {
    return Consumer<ExerciseProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                const SizedBox(height: 16),
                const Text(
                  'Đã xảy ra lỗi',
                  style: TextStyle(
                    fontSize: AppTypography.subtitle,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _loadExercises,
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }

        if (_filteredExercises.isEmpty && !provider.isLoading) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.quiz_outlined,
                    size: 64, color: AppColors.textDisabled),
                const SizedBox(height: 16),
                Text(
                  _allExercises.isEmpty
                      ? 'Chưa có bài tập nào'
                      : 'Không tìm thấy bài tập phù hợp',
                  style: const TextStyle(
                    fontSize: AppTypography.subtitle,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (_allExercises.isEmpty) ...[
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loadExercises,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tải lại'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: _filteredExercises.length,
          itemBuilder: (context, index) {
            final exercise = _filteredExercises[index];
            return _buildExerciseCard(exercise);
          },
        );
      },
    );
  }

  Widget _buildExerciseCard(exercise) {
    final Color typeColor = _getTypeColor(exercise.type);
    final IconData typeIcon = _getTypeIcon(exercise.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            typeColor.withValues(alpha: 0.1),
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.textSecondary.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            context.push('/exercise/${exercise.id}');
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Hero(
                  tag: 'exercise_${exercise.id}',
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [typeColor.withValues(alpha: 0.7), typeColor],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: typeColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(typeIcon, color: Colors.white, size: 30),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              exercise.title,
                              style: const TextStyle(
                                fontSize: AppTypography.subtitle,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.warning,
                                  AppColors.warning,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              exercise.level,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: AppTypography.caption,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (exercise.description != null &&
                          exercise.description!.isNotEmpty)
                        Text(
                          exercise.description!,
                          style: const TextStyle(
                            fontSize: AppTypography.bodySmall,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildInfoChip(
                            Icons.quiz,
                            '${exercise.questionCount} câu',
                            AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          if (exercise.timeLimit > 0)
                            _buildInfoChip(
                              Icons.timer,
                              '${exercise.timeLimit} phút',
                              Colors.purple,
                            ),
                          const SizedBox(width: 8),
                          _buildInfoChip(
                            Icons.people,
                            '${exercise.totalAttempts} lượt',
                            AppColors.success,
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
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: AppTypography.caption,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'Từ vựng':
        return AppColors.primary;
      case 'Ngữ pháp':
        return AppColors.success;
      case 'Kanji':
        return AppColors.warning;
      case 'Tổng hợp':
        return Colors.purple;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'Từ vựng':
        return Icons.spellcheck;
      case 'Ngữ pháp':
        return Icons.book;
      case 'Kanji':
        return Icons.text_fields;
      case 'Tổng hợp':
        return Icons.dashboard;
      default:
        return Icons.quiz;
    }
  }
}
