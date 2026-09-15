import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/app_tokens.dart';
import '../providers/lesson_provider.dart';
import '../models/lesson.dart';
import '../models/situation_labels.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/content_pane.dart';

class LessonListScreen extends StatefulWidget {
  const LessonListScreen({Key? key}) : super(key: key);

  @override
  State<LessonListScreen> createState() => _LessonListScreenState();
}

class _LessonListScreenState extends State<LessonListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedLevel;
  String? _selectedSituation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<LessonProvider>(context, listen: false);
      provider.loadLessons(refresh: true);
      provider.loadSituations();
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
      title: 'Bài học',
      actions: [
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: _showFilterDialog,
        ),
      ],
      body: ContentWidthLimit(
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm bài học...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            Provider.of<LessonProvider>(context, listen: false)
                                .searchLessons('');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                ),
                onSubmitted: (value) {
                  Provider.of<LessonProvider>(context, listen: false)
                      .searchLessons(value);
                },
              ),
            ),

            // Lọc nhanh theo tình huống thực tế (đi siêu thị, đi tàu...)
            _buildSituationBar(),

            // Level filter chips
            if (_selectedLevel != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Chip(
                      label: Text(_selectedLevel!),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () {
                        setState(() {
                          _selectedLevel = null;
                        });
                        Provider.of<LessonProvider>(context, listen: false)
                            .filterByLevel(null);
                      },
                    ),
                  ],
                ),
              ),

            // Lesson list
            Expanded(
              child: Consumer<LessonProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (provider.error != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 64, color: AppColors.error),
                          const SizedBox(height: 16),
                          Text(
                            provider.error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.error),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () =>
                                provider.loadLessons(refresh: true),
                            child: const Text('Thử lại'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (provider.lessons.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.book_outlined,
                              size: 56, color: AppColors.textDisabled),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            _selectedSituation != null
                                ? 'Chưa có bài học cho tình huống này'
                                : 'Chưa có bài học nào',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () => provider.loadLessons(refresh: true),
                    child: Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: provider.lessons.length,
                            itemBuilder: (context, index) {
                              final lesson = provider.lessons[index];
                              return _buildLessonCard(lesson);
                            },
                          ),
                        ),
                        _buildPagination(provider),
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

  /// Hàng chip chọn tình huống. Ẩn hẳn khi chưa có bài tình huống nào để không
  /// chiếm chỗ bằng một thanh trống.
  Widget _buildSituationBar() {
    return Consumer<LessonProvider>(
      builder: (context, provider, child) {
        if (provider.situations.isEmpty) return const SizedBox.shrink();

        return SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildSituationChip(null, 'Tất cả', Icons.apps),
              ...provider.situations.map(
                (code) => _buildSituationChip(
                  code,
                  situationLabel(code),
                  situationIcon(code),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSituationChip(String? code, String label, IconData icon) {
    final selected = _selectedSituation == code;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        avatar: Icon(icon, size: 18),
        label: Text(label),
        selected: selected,
        onSelected: (_) {
          setState(() => _selectedSituation = code);
          Provider.of<LessonProvider>(context, listen: false)
              .filterBySituation(code);
        },
      ),
    );
  }

  Widget _buildLessonCard(Lesson lesson) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          context.push('/lessons/${lesson.id}');
        },
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.getJlptLevelColor(lesson.level),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  lesson.level,
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(color: Colors.white),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (lesson.situation != null) ...[
                      Row(
                        children: [
                          Icon(situationIcon(lesson.situation!),
                              size: 14, color: AppColors.primary),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            situationLabel(lesson.situation!),
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(color: AppColors.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                    ],
                    Text(
                      lesson.title,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    if (lesson.description != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        lesson.description!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.xs,
                      children: [
                        if (lesson.isSituational)
                          _buildMeta(Icons.forum_outlined,
                              '${lesson.dialogue.length} lượt thoại'),
                        if (lesson.vocabularies.isNotEmpty)
                          _buildMeta(Icons.spellcheck,
                              '${lesson.vocabularies.length} từ'),
                        if (lesson.kanjis.isNotEmpty)
                          _buildMeta(Icons.draw_outlined,
                              '${lesson.kanjis.length} kanji'),
                        if (lesson.grammars.isNotEmpty)
                          _buildMeta(Icons.segment,
                              '${lesson.grammars.length} ngữ pháp'),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textDisabled),
            ],
          ),
        ),
      ),
    );
  }

  /// Một mẩu thông tin phụ của bài học. Dùng `Wrap` ở chỗ gọi nên khi thẻ hẹp
  /// các mẩu này xuống dòng thay vì tràn ngang.
  Widget _buildMeta(IconData icon, String label) {
    return Builder(
      builder: (context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.xs),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildPagination(LessonProvider provider) {
    if (provider.totalPages <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed:
                provider.currentPage > 1 ? () => provider.previousPage() : null,
            icon: const Icon(Icons.chevron_left),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'Trang ${provider.currentPage} / ${provider.totalPages}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: provider.currentPage < provider.totalPages
                ? () => provider.nextPage()
                : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lọc theo cấp độ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLevelOption('N5'),
            _buildLevelOption('N4'),
            _buildLevelOption('N3'),
            _buildLevelOption('N2'),
            _buildLevelOption('N1'),
            const Divider(),
            ListTile(
              title: const Text('Tất cả'),
              leading: Radio<String?>(
                value: null,
                groupValue: _selectedLevel,
                onChanged: (value) {
                  setState(() {
                    _selectedLevel = value;
                  });
                  Provider.of<LessonProvider>(context, listen: false)
                      .filterByLevel(null);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelOption(String level) {
    return ListTile(
      title: Text(level),
      leading: Radio<String>(
        value: level,
        groupValue: _selectedLevel,
        onChanged: (value) {
          setState(() {
            _selectedLevel = value;
          });
          Provider.of<LessonProvider>(context, listen: false)
              .filterByLevel(value);
          Navigator.pop(context);
        },
      ),
    );
  }
}
