import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/lesson_provider.dart';
import '../../models/lesson.dart';
import 'lesson_detail_screen.dart';

class LessonListScreen extends StatefulWidget {
  const LessonListScreen({Key? key}) : super(key: key);

  @override
  State<LessonListScreen> createState() => _LessonListScreenState();
}

class _LessonListScreenState extends State<LessonListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedLevel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LessonProvider>(context, listen: false)
          .loadLessons(refresh: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bài học'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
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
                fillColor: Colors.grey[100],
              ),
              onSubmitted: (value) {
                Provider.of<LessonProvider>(context, listen: false)
                    .searchLessons(value);
              },
            ),
          ),

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
                            size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          provider.error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => provider.loadLessons(refresh: true),
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
                        Icon(Icons.book_outlined,
                            size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Không có bài học nào',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
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
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LessonDetailScreen(lessonId: lesson.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Level badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.getJlptLevelColor(lesson.level),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  lesson.level,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Lesson info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (lesson.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        lesson.description!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (lesson.vocabularies.isNotEmpty) ...[ 
                          Icon(Icons.spellcheck, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '${lesson.vocabularies.length} từ',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        if (lesson.kanjis.isNotEmpty) ...[ 
                          Icon(Icons.draw_outlined, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '${lesson.kanjis.length} kanji',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        if (lesson.grammars.isNotEmpty) ...[ 
                          Icon(Icons.segment, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '${lesson.grammars.length} ngữ pháp',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow icon
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPagination(LessonProvider provider) {
    if (provider.totalPages <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: provider.currentPage > 1
                ? () => provider.previousPage()
                : null,
            icon: const Icon(Icons.chevron_left),
          ),
          const SizedBox(width: 8),
          Text(
            'Trang ${provider.currentPage} / ${provider.totalPages}',
            style: const TextStyle(fontSize: 14),
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
