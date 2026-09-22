import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/content_pane.dart';
import '../models/vocabulary_set.dart';
import '../providers/vocabulary_set_provider.dart';
import 'vocabulary_set_card.dart';

/// Tab "Bộ từ vựng": chọn cấp, rồi chọn một bộ khoảng 20 từ để học.
///
/// Thay cho một danh sách dài hàng nghìn từ: người học thấy ngay nên bắt đầu
/// từ đâu và mình đã đi được bao xa trong từng chủ đề.
class VocabularySetsTab extends StatelessWidget {
  const VocabularySetsTab({super.key});

  Future<void> _open(BuildContext context, VocabularySet set) async {
    await context.push('/vocabulary/sets/${set.id}');
    // Quay về sau khi học thì số từ đã học của bộ có thể đã đổi.
    if (context.mounted) {
      await context.read<VocabularySetProvider>().loadSets(silent: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VocabularySetProvider>();

    return Column(
      children: [
        ContentPane(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final level in VocabularySetProvider.levels)
                ChoiceChip(
                  label: Text(level),
                  selected: provider.level == level,
                  onSelected: (_) => provider.selectLevel(level),
                ),
            ],
          ),
        ),
        Expanded(
          child: AsyncView<List<VocabularySet>>(
            state: provider.setsState,
            onRetry: provider.loadSets,
            isEmpty: (sets) => sets.isEmpty,
            emptyTitle: 'Chưa có bộ từ vựng nào ở cấp này',
            emptyIcon: Icons.collections_bookmark_outlined,
            builder: (context, sets) => _SetList(
              sets: sets,
              onOpen: (set) => _open(context, set),
            ),
          ),
        ),
      ],
    );
  }
}

class _SetList extends StatelessWidget {
  const _SetList({required this.sets, required this.onOpen});

  final List<VocabularySet> sets;
  final ValueChanged<VocabularySet> onOpen;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final learned = sets.fold<int>(0, (sum, set) => sum + set.learnedCount);
    final total = sets.fold<int>(0, (sum, set) => sum + set.wordCount);

    // Mỗi phần tử là tiêu đề mức độ khó (N3–N1) hoặc một thẻ bộ.
    final rows = <Object>[];
    String? section;
    for (final set in sets) {
      if (set.section != null && set.section != section) {
        section = set.section;
        rows.add(section!);
      }
      rows.add(set);
    }

    return ContentPaneList(
      builder: (context, padding) => ListView.builder(
        padding: padding,
        itemCount: rows.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Text(
                '${sets.length} bộ · đã học $learned/$total từ',
                style: textTheme.bodyMedium,
              ),
            );
          }

          final row = rows[index - 1];
          if (row is String) {
            return Padding(
              padding: const EdgeInsets.only(
                top: AppSpacing.md,
                bottom: AppSpacing.sm,
              ),
              child: Text(row, style: textTheme.titleLarge),
            );
          }

          final set = row as VocabularySet;
          return VocabularySetCard(set: set, onTap: () => onOpen(set));
        },
      ),
    );
  }
}
