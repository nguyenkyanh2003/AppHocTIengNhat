import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';

/// Ô tìm kiếm và bộ lọc cấp độ của màn từ vựng.
class VocabularyFilterBar extends StatefulWidget {
  const VocabularyFilterBar({
    super.key,
    required this.selectedLevel,
    required this.onSearch,
    required this.onLevelChanged,
    required this.onClear,
  });

  final String? selectedLevel;
  final ValueChanged<String> onSearch;
  final ValueChanged<String?> onLevelChanged;
  final VoidCallback onClear;

  static const levels = ['N5', 'N4', 'N3', 'N2', 'N1'];

  @override
  State<VocabularyFilterBar> createState() => _VocabularyFilterBarState();
}

class _VocabularyFilterBarState extends State<VocabularyFilterBar> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    widget.onClear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: TextField(
            controller: _controller,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Tìm từ vựng, hiragana hoặc nghĩa...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _controller.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _clear,
                    ),
            ),
            onChanged: (_) => setState(() {}),
            onSubmitted: widget.onSearch,
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: VocabularyFilterBar.levels.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              final level = VocabularyFilterBar.levels[index];
              final selected = widget.selectedLevel == level;

              return FilterChip(
                label: Text(level),
                selected: selected,
                onSelected: (value) =>
                    widget.onLevelChanged(value ? level : null),
              );
            },
          ),
        ),
      ],
    );
  }
}
