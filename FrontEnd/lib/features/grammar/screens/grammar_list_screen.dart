import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/grammar_provider.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/content_pane.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../core/state/view_state.dart';
import '../models/grammar.dart';
import '../../../shared/widgets/level_badge.dart';

class GrammarListScreen extends StatefulWidget {
  final String? level;

  const GrammarListScreen({Key? key, this.level}) : super(key: key);

  @override
  State<GrammarListScreen> createState() => _GrammarListScreenState();
}

class _GrammarListScreenState extends State<GrammarListScreen> {
  late TextEditingController _searchController;
  String? _selectedLevel;
  String? _selectedSort = 'popular';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _selectedLevel = widget.level ?? 'N5';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadGrammars();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadGrammars() async {
    final provider = Provider.of<GrammarProvider>(context, listen: false);
    if (_searchController.text.isNotEmpty) {
      await provider.searchGrammars(_searchController.text);
    } else {
      await provider.loadGrammars(
        level: _selectedLevel,
        sortBy: _selectedSort,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Ngữ Pháp',
      body: ContentWidthLimit(
        child: Consumer<GrammarProvider>(
          builder: (context, provider, _) {
            return Column(
              children: [
                // Search & Filter
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Search bar
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm ngữ pháp...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    _loadGrammars();
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {});
                          if (value.isEmpty) {
                            _loadGrammars();
                          } else {
                            provider.searchGrammars(value);
                          }
                        },
                      ),
                      const SizedBox(height: 12),

                      // Level & Sort filters
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButton<String>(
                              value: _selectedLevel,
                              isExpanded: true,
                              items: ['N5', 'N4', 'N3', 'N2', 'N1']
                                  .map((level) => DropdownMenuItem(
                                        value: level,
                                        child: Text(level),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() => _selectedLevel = value);
                                _loadGrammars();
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButton<String>(
                              value: _selectedSort,
                              isExpanded: true,
                              items: const [
                                DropdownMenuItem(
                                  value: 'popular',
                                  child: Text('Phổ biến'),
                                ),
                                DropdownMenuItem(
                                  value: 'newest',
                                  child: Text('Mới nhất'),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() => _selectedSort = value);
                                _loadGrammars();
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: AsyncView<List<Grammar>>(
                    state: ViewState.fromLegacy(
                      isLoading: provider.isLoading,
                      error: provider.error,
                      value: provider.grammars,
                      isEmpty: provider.grammars.isEmpty,
                    ),
                    onRetry: _loadGrammars,
                    isEmpty: (grammars) => grammars.isEmpty,
                    emptyTitle: 'Không tìm thấy ngữ pháp',
                    builder: (context, grammars) => ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: grammars.length,
                      itemBuilder: (context, index) {
                        final grammar = grammars[index];
                        return GrammarCard(
                          grammar: grammar,
                          onTap: () => context.push('/grammar/${grammar.id}'),
                        );
                      },
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
}

class GrammarCard extends StatelessWidget {
  final dynamic grammar;
  final VoidCallback onTap;

  const GrammarCard({
    Key? key,
    required this.grammar,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        onTap: onTap,
        leading: LevelBadge(grammar.level),
        title: Text(
          grammar.title ?? grammar.pattern ?? '',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          grammar.meaning ?? '',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.visibility_outlined,
                size: 18, color: context.colors.textSecondary),
            AppGap.xs,
            Text(
              '${grammar.viewCount ?? 0}',
              style: TextStyle(
                  fontSize: AppTypography.caption,
                  color: context.colors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
