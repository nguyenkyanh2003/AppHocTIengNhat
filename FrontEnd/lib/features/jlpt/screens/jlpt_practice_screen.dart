import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/state/view_state.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/content_pane.dart';
import '../models/jlpt_practice_question.dart';
import '../providers/jlpt_practice_provider.dart';
import '../widgets/jlpt_practice_question_card.dart';

class JLPTPracticeScreen extends StatefulWidget {
  const JLPTPracticeScreen({super.key});

  @override
  State<JLPTPracticeScreen> createState() => _JLPTPracticeScreenState();
}

class _JLPTPracticeScreenState extends State<JLPTPracticeScreen> {
  String _type = 'moji_goi';
  String? _level;

  static const _skills = {
    'moji_goi': 'Từ vựng',
    'bunpou': 'Ngữ pháp',
    'dokkai': 'Đọc',
    'choukai': 'Nghe',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() => context
      .read<JLPTPracticeProvider>()
      .loadPractice(type: _type, level: _level);

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Luyện nhanh',
      actions: [
        IconButton(
          tooltip: 'Đổi bộ câu khác',
          icon: const Icon(Icons.shuffle),
          onPressed: _load,
        ),
      ],
      body: ContentWidthLimit(
        child: Column(
          children: [
            _buildFilters(),
            Expanded(
              child: Consumer<JLPTPracticeProvider>(
                builder: (context, provider, _) {
                  return AsyncView<List<JlptPracticeQuestion>>(
                    state: ViewState.fromLegacy(
                      isLoading: provider.isLoading,
                      error: provider.error,
                      value: provider.items,
                      isEmpty: provider.items.isEmpty,
                    ),
                    onRetry: _load,
                    isEmpty: (items) => items.isEmpty,
                    emptyTitle: 'Chưa có câu hỏi',
                    emptyMessage: 'Thử chọn kỹ năng hoặc cấp độ khác.',
                    emptyIcon: Icons.quiz_outlined,
                    builder: (context, items) => Column(
                      children: [
                        _ScoreBar(provider: provider),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            itemCount: items.length,
                            itemBuilder: (context, index) =>
                                JlptPracticeQuestionCard(
                              number: index + 1,
                              question: items[index],
                              selected: provider.answerOf(index),
                              onSelect: (choice) =>
                                  provider.answer(index, choice),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        0,
      ),
      child: Row(
        children: [
          Expanded(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _type,
              items: [
                for (final MapEntry(:key, :value) in _skills.entries)
                  DropdownMenuItem(value: key, child: Text(value)),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _type = value);
                _load();
              },
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: DropdownButton<String?>(
              isExpanded: true,
              value: _level,
              items: [
                for (final level in const [null, 'N5', 'N4', 'N3', 'N2', 'N1'])
                  DropdownMenuItem(
                      value: level, child: Text(level ?? 'Tất cả cấp độ')),
              ],
              onChanged: (value) {
                setState(() => _level = value);
                _load();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreBar extends StatelessWidget {
  const _ScoreBar({required this.provider});

  final JLPTPracticeProvider provider;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        0,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Đã làm ${provider.answeredCount}/${provider.items.length} câu',
              style: TextStyle(
                fontSize: AppTypography.bodySmall,
                color: context.colors.textSecondary,
              ),
            ),
          ),
          Text(
            'Đúng ${provider.correctCount}',
            style: TextStyle(
              fontSize: AppTypography.bodySmall,
              fontWeight: FontWeight.bold,
              color: context.colors.readable(AppColors.success),
            ),
          ),
        ],
      ),
    );
  }
}
