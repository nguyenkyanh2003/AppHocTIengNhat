import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/grammar_provider.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/content_pane.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/app_tokens.dart';
import '../widgets/grammar_detail_section.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../core/state/view_state.dart';
import '../models/grammar.dart';
import '../../../shared/widgets/level_badge.dart';
import '../../../app/theme/app_theme.dart';

class GrammarDetailScreen extends StatefulWidget {
  final String grammarId;

  const GrammarDetailScreen({Key? key, required this.grammarId})
      : super(key: key);

  @override
  State<GrammarDetailScreen> createState() => _GrammarDetailScreenState();
}

class _GrammarDetailScreenState extends State<GrammarDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<GrammarProvider>(context, listen: false)
          .loadGrammarDetail(widget.grammarId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Ngữ Pháp',
      body: ContentWidthLimit(
        child: Consumer<GrammarProvider>(
          builder: (context, provider, _) {
            final grammar = provider.selectedGrammar;
            if (provider.isLoading ||
                provider.error != null ||
                grammar == null) {
              return AsyncView<Grammar>(
                state: ViewState.detail(
                  isLoading: provider.isLoading,
                  error: provider.error,
                  value: grammar,
                ),
                onRetry: () => provider.loadGrammarDetail(widget.grammarId),
                builder: (context, _) => const SizedBox.shrink(),
              );
            }

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    color: AppTheme.getJlptLevelColor(grammar.level)
                        .withValues(alpha: 0.12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LevelBadge(grammar.level),
                        const SizedBox(height: 16),
                        Text(
                          grammar.title,
                          style: TextStyle(
                            color: context.colors.textPrimary,
                            fontSize: AppTypography.headline,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Pattern: ${grammar.pattern}',
                          style: TextStyle(
                            color: context.colors.textSecondary,
                            fontSize: AppTypography.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Meaning section
                        GrammarDetailSection(
                            title: 'Ý Nghĩa',
                            content: grammar.meaning,
                            icon: Icons.description),
                        const SizedBox(height: 24),

                        // Explanation section
                        if (grammar.explanation != null &&
                            grammar.explanation!.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GrammarDetailSection(
                                  title: 'Giải Thích',
                                  content: grammar.explanation!,
                                  icon: Icons.info),
                              const SizedBox(height: 24),
                            ],
                          ),

                        // Examples section
                        if (grammar.examples.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const GrammarSectionTitle(
                                  title: 'Ví Dụ', icon: Icons.lightbulb),
                              const SizedBox(height: 12),
                              ...grammar.examples.asMap().entries.map((entry) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: context.colors.surfaceVariant,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border(
                                        left: BorderSide(
                                          color: AppTheme.getJlptLevelColor(
                                              grammar.level),
                                          width: 4,
                                        ),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Ví dụ ${entry.key + 1}:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: AppTypography.caption,
                                            color: context.colors.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          entry.value,
                                          style: const TextStyle(
                                            fontSize: AppTypography.bodySmall,
                                            height: 1.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ],
                          ),

                        const SizedBox(height: 24),

                        // Stats
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatCard(
                              'Lượt Xem',
                              '${grammar.viewCount}',
                              Icons.visibility,
                            ),
                            _buildStatCard(
                              'Cấp Độ',
                              grammar.level,
                              Icons.trending_up,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Expanded(
      child: Card(
        elevation: 0,
        color: context.colors.surfaceVariant,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
          child: Column(
            children: [
              Icon(icon, color: context.colors.primary, size: 24),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: AppTypography.body,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: AppTypography.caption,
                  color: context.colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
