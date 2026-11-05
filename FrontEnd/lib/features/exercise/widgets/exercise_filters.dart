import 'package:flutter/material.dart';
import '../../../app/theme/app_tokens.dart';

/// Hai hàng lọc theo cấp độ và loại bài tập.
class ExerciseFilters extends StatelessWidget {
  const ExerciseFilters({
    super.key,
    required this.selectedLevel,
    required this.selectedType,
    required this.selectLevel,
    required this.selectType,
  });

  static final List<String> _levels = ['Tất cả', 'N5', 'N4', 'N3', 'N2', 'N1'];
  static final List<String> _types = [
    'Tất cả',
    'Từ vựng',
    'Ngữ pháp',
    'Kanji',
    'Tổng hợp'
  ];

  final String selectedLevel;
  final String selectedType;
  final void Function(String level) selectLevel;
  final void Function(String type) selectType;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildLevelFilter(context),
        const SizedBox(height: 8),
        _buildTypeFilter(context),
      ],
    );
  }

  Widget _buildLevelFilter(BuildContext context) {
    return SizedBox(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _levels.length,
        itemBuilder: (context, index) {
          final level = _levels[index];
          final isSelected = selectedLevel == level ||
              (selectedLevel.isEmpty && level == 'Tất cả');

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(level),
              selected: isSelected,
              onSelected: (selected) {
                selectLevel(level);
              },
              backgroundColor: context.colors.surface,
              selectedColor: context.colors.primarySoft,
              labelStyle: TextStyle(
                color: isSelected
                    ? context.colors.primaryStrong
                    : context.colors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              side: BorderSide(
                color:
                    isSelected ? context.colors.primary : context.colors.border,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTypeFilter(BuildContext context) {
    return SizedBox(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _types.length,
        itemBuilder: (context, index) {
          final type = _types[index];
          final isSelected = selectedType == type ||
              (selectedType.isEmpty && type == 'Tất cả');

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(type),
              selected: isSelected,
              onSelected: (selected) {
                selectType(type);
              },
              backgroundColor: context.colors.surface,
              selectedColor: AppColors.success.withValues(alpha: 0.15),
              checkmarkColor: AppColors.success,
              labelStyle: TextStyle(
                color: isSelected
                    ? AppColors.success
                    : context.colors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected ? AppColors.success : context.colors.border,
              ),
            ),
          );
        },
      ),
    );
  }
}
