import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/kanji_provider.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/content_pane.dart';
import '../../../app/theme/app_tokens.dart';
import '../widgets/kanji_list_card.dart';
import '../widgets/kanji_pagination.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../core/state/view_state.dart';
import '../models/kanji.dart';

class KanjiListScreen extends StatefulWidget {
  const KanjiListScreen({Key? key}) : super(key: key);

  @override
  State<KanjiListScreen> createState() => _KanjiListScreenState();
}

class _KanjiListScreenState extends State<KanjiListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _levels = ['Tất cả', 'N5', 'N4', 'N3', 'N2', 'N1'];
  String _selectedLevel = 'Tất cả';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<KanjiProvider>().loadKanjis(refresh: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Kanji',
      body: ContentWidthLimit(
        child: Column(
          children: [
            _buildSearchBar(),
            _buildLevelFilter(),
            Expanded(child: _buildKanjiList()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Tìm kiếm Kanji...',
            hintStyle: TextStyle(color: context.colors.textDisabled),
            prefixIcon: Icon(Icons.search, color: context.colors.textSecondary),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon:
                        Icon(Icons.clear, color: context.colors.textSecondary),
                    onPressed: () {
                      _searchController.clear();
                      context.read<KanjiProvider>().loadKanjis(refresh: true);
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.all(16),
          ),
          onChanged: (value) {
            setState(() {});
            if (value.isEmpty) {
              context.read<KanjiProvider>().loadKanjis(refresh: true);
            }
          },
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              context.read<KanjiProvider>().searchKanjis(value);
            }
          },
        ),
      ),
    );
  }

  Widget _buildLevelFilter() {
    return Container(
      height: 60,
      margin: const EdgeInsets.only(top: 15),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _levels.length,
        itemBuilder: (context, index) {
          final level = _levels[index];
          final isSelected = level == _selectedLevel;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: FilterChip(
              label: Text(level),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedLevel = level;
                });
                context.read<KanjiProvider>().filterByLevel(
                      level == 'Tất cả' ? null : level,
                    );
              },
              backgroundColor: context.colors.surface,
              selectedColor: AppColors.kanjiCoral.withValues(alpha: 0.2),
              labelStyle: TextStyle(
                color: isSelected
                    ? AppColors.kanjiCoral
                    : context.colors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              side: BorderSide(
                color:
                    isSelected ? AppColors.kanjiCoral : context.colors.border,
                width: isSelected ? 2 : 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildKanjiList() {
    return Consumer<KanjiProvider>(
      builder: (context, provider, child) => AsyncView<List<Kanji>>(
        state: ViewState.fromLegacy(
          isLoading: provider.isLoading,
          error: provider.errorMessage.isEmpty ? null : provider.errorMessage,
          value: provider.kanjis,
          isEmpty: provider.kanjis.isEmpty,
        ),
        onRetry: () => provider.loadKanjis(refresh: true),
        isEmpty: (kanjis) => kanjis.isEmpty,
        emptyTitle: 'Không tìm thấy Kanji nào',
        emptyIcon: Icons.search_off,
        builder: (context, kanjis) => Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: kanjis.length,
                itemBuilder: (context, index) =>
                    KanjiListCard(kanji: kanjis[index]),
              ),
            ),
            KanjiPagination(provider: provider),
          ],
        ),
      ),
    );
  }
}
