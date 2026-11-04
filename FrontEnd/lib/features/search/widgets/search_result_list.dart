import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../shared/widgets/level_badge.dart';
import '../models/search_result.dart';

/// Kết quả tìm kiếm chia theo nhóm. Server đã trả đúng thứ tự nhóm và xếp
/// độ liên quan trong từng nhóm, nên danh sách giữ nguyên thứ tự đó.
class SearchResultList extends StatelessWidget {
  const SearchResultList({super.key, required this.results, required this.onOpen});

  final List<SearchResult> results;
  final ValueChanged<SearchResult> onOpen;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    SearchResultType? section;
    for (final result in results) {
      if (result.type != section) {
        section = result.type;
        rows.add(_SectionHeader(type: section));
      }
      rows.add(SearchResultTile(result: result, onTap: () => onOpen(result)));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
      children: rows,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.type});

  final SearchResultType type;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.xs),
      child: Row(
        children: [
          Icon(type.icon, size: 18, color: type.color),
          const SizedBox(width: AppSpacing.sm),
          Text(type.label, style: Theme.of(context).textTheme.titleSmall),
        ],
      ),
    );
  }
}

/// Một dòng kết quả: tiêu đề, cách đọc/cấu trúc kèm nghĩa, cấp JLPT nếu có.
class SearchResultTile extends StatelessWidget {
  const SearchResultTile({super.key, required this.result, required this.onTap});

  final SearchResult result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final details = [result.subtitle, result.description]
        .whereType<String>()
        .where((text) => text.isNotEmpty)
        .join(' · ');
    final level = result.level;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: ListTile(
        key: ValueKey('search-result-${result.type.key}-${result.id}'),
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: result.type.color.withValues(alpha: 0.15),
          child: Icon(result.type.icon, color: result.type.color, size: 20),
        ),
        title: Text(result.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: details.isEmpty ? null : Text(details, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: level == null ? null : LevelBadge(level, compact: true),
      ),
    );
  }
}

extension on SearchResultType {
  IconData get icon => switch (this) {
        SearchResultType.vocabulary => Icons.spellcheck,
        SearchResultType.kanji => Icons.draw_outlined,
        SearchResultType.lesson => Icons.menu_book,
        SearchResultType.grammar => Icons.school,
        SearchResultType.news => Icons.newspaper,
      };

  Color get color => switch (this) {
        SearchResultType.vocabulary => AppColors.vocabulary,
        SearchResultType.kanji => AppColors.kanji,
        SearchResultType.lesson => AppColors.lesson,
        SearchResultType.grammar => AppColors.grammar,
        SearchResultType.news => AppColors.news,
      };
}
