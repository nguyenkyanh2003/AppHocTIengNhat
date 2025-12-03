import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_html/flutter_html.dart';
import '../../providers/lesson_provider.dart';
import '../../providers/lesson_progress_provider.dart';
import '../../models/lesson.dart';
import 'lesson_study_screen.dart';

class LessonDetailScreen extends StatefulWidget {
  final String lessonId;

  const LessonDetailScreen({
    Key? key,
    required this.lessonId,
  }) : super(key: key);

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LessonProvider>(context, listen: false)
          .loadLessonDetail(widget.lessonId);
      Provider.of<LessonProgressProvider>(context, listen: false)
          .loadProgress(widget.lessonId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<LessonProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    provider.error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        provider.loadLessonDetail(widget.lessonId),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          if (provider.currentLessonDetail == null) {
            return const Center(child: Text('Không tìm thấy bài học'));
          }

          final lessonDetail = provider.currentLessonDetail!;
          final lesson = lessonDetail.lesson;

          return CustomScrollView(
            slivers: [
              _buildAppBar(lesson),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    _buildHeader(lesson),
                    _buildTabBar(),
                  ],
                ),
              ),
              SliverFillRemaining(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(lesson, lessonDetail),
                    _buildVocabularyTab(lessonDetail.vocabularies),
                    _buildKanjiTab(lessonDetail.kanjis),
                    _buildGrammarTab(lessonDetail.grammars),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildAppBar(Lesson lesson) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          lesson.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                offset: Offset(0, 1),
                blurRadius: 3,
                color: Colors.black45,
              ),
            ],
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _getLevelColor(lesson.level),
                _getLevelColor(lesson.level).withOpacity(0.7),
              ],
            ),
          ),
          child: Center(
            child: Icon(
              Icons.menu_book,
              size: 80,
              color: Colors.white.withOpacity(0.3),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Lesson lesson) {
    return Consumer<LessonProgressProvider>(
      builder: (context, progressProvider, child) {
        final progress = progressProvider.currentProgress;
        
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getLevelColor(lesson.level),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      lesson.getLevelName(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (progress != null && progress.isCompleted)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle, size: 16, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'Đã hoàn thành',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              
              // Progress bar
              if (progress != null) ...[
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tiến độ học tập',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${(progress.overallProgress * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _getLevelColor(lesson.level),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress.overallProgress,
                        minHeight: 8,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getLevelColor(lesson.level),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (lesson.description != null) ...[
                const SizedBox(height: 12),
                Text(
                  lesson.description!,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    Icons.spellcheck,
                    progress != null
                        ? '${progress.completedVocabularies}/${progress.totalVocabularies}'
                        : lesson.vocabularies.length.toString(),
                    'Từ vựng',
                    Colors.blue,
                    progress?.vocabularyProgress,
                  ),
                  _buildStatItem(
                    Icons.draw_outlined,
                    progress != null
                        ? '${progress.completedKanjis}/${progress.totalKanjis}'
                        : lesson.kanjis.length.toString(),
                    'Kanji',
                    Colors.orange,
                    progress?.kanjiProgress,
                  ),
                  _buildStatItem(
                    Icons.segment,
                    progress != null
                        ? '${progress.completedGrammars}/${progress.totalGrammars}'
                        : lesson.grammars.length.toString(),
                    'Ngữ pháp',
                    Colors.green,
                    progress?.grammarProgress,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, Color color, [double? progress]) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            if (progress != null)
              SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 3,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            Icon(icon, color: color, size: progress != null ? 24 : 32),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: progress != null ? 16 : 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.blue,
        unselectedLabelColor: Colors.grey,
        indicatorColor: Colors.blue,
        tabs: const [
          Tab(text: 'Tổng quan'),
          Tab(icon: Icon(Icons.spellcheck), text: 'Từ vựng'), 
          Tab(text: 'Kanji'),
          Tab(text: 'Ngữ pháp'),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(Lesson lesson, LessonDetail detail) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (lesson.contentHtml != null && lesson.contentHtml!.isNotEmpty) ...[
            const Text(
              'Nội dung bài học',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Html(
                  data: lesson.contentHtml,
                ),
              ),
            ),
          ] else ...[
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.description_outlined,
                      size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có nội dung bài học',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVocabularyTab(List<dynamic> vocabularies) {
    if (vocabularies.isEmpty) {
      return _buildEmptyState('Chưa có từ vựng', Icons.spellcheck_outlined);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final vocab = vocabularies[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue,
              child: Text('${index + 1}'),
            ),
            title: Text(vocab['word'] ?? vocab.toString()),
            subtitle: Text(vocab['meaning'] ?? ''),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Navigate to vocabulary detail
            },
          ),
        );
      },
    );
  }

  Widget _buildKanjiTab(List<dynamic> kanjis) {
    if (kanjis.isEmpty) {
      return _buildEmptyState('Chưa có Kanji', Icons.draw_outlined);
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: kanjis.length,
      itemBuilder: (context, index) {
        final kanji = kanjis[index];
        return Card(
          child: InkWell(
            onTap: () {
              // Navigate to kanji detail
            },
            child: Center(
              child: Text(
                kanji['character'] ?? kanji.toString(),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGrammarTab(List<dynamic> grammars) {
    if (grammars.isEmpty) {
      return _buildEmptyState('Chưa có ngữ pháp', Icons.segment_outlined);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: grammars.length,
      itemBuilder: (context, index) {
        final grammar = grammars[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green,
              child: Text('${index + 1}'),
            ),
            title: Text(
              grammar['pattern'] ?? grammar.toString(), 
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(grammar['meaning'] ?? ''),
            children: [
              if (grammar['example'] != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(grammar['example']),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Consumer<LessonProgressProvider>(
      builder: (context, progressProvider, child) {
        final progress = progressProvider.currentProgress;
        final isCompleted = progress?.isCompleted ?? false;
        
        return Container(
          padding: const EdgeInsets.all(16),
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
          child: SafeArea(
            child: Row(
              children: [
                if (progress != null && !isCompleted)
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      onPressed: () => _showResetDialog(progressProvider),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Icon(Icons.refresh),
                    ),
                  ),
                if (progress != null && !isCompleted) const SizedBox(width: 12),
                Expanded(
                  flex: 4,
                  child: ElevatedButton.icon(
                    onPressed: () => _startLesson(progressProvider),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: isCompleted ? Colors.green : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: Icon(
                      isCompleted
                          ? Icons.check_circle
                          : (progress != null
                              ? Icons.play_arrow
                              : Icons.play_circle_outline),
                    ),
                    label: Text(
                      isCompleted
                          ? 'Học lại'
                          : (progress != null ? 'Tiếp tục học' : 'Bắt đầu học'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _startLesson(LessonProgressProvider progressProvider) async {
    final progress = progressProvider.currentProgress;
    
    // Nếu chưa có progress, tạo mới
    if (progress == null) {
      final success = await progressProvider.startLesson(widget.lessonId);
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể bắt đầu bài học'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    // Navigate to study screen
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LessonStudyScreen(lessonId: widget.lessonId),
        ),
      );
    }
  }

  Future<void> _showResetDialog(LessonProgressProvider progressProvider) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đặt lại tiến độ'),
        content: const Text(
          'Bạn có chắc muốn đặt lại tiến độ học của bài này? '
          'Tất cả tiến độ sẽ bị xóa.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Đặt lại'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      final success = await progressProvider.resetProgress(widget.lessonId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Đã đặt lại tiến độ' : 'Không thể đặt lại tiến độ',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  Color _getLevelColor(String level) {
    switch (level) {
      case 'N1':
        return Colors.red;
      case 'N2':
        return Colors.orange;
      case 'N3':
        return Colors.amber;
      case 'N4':
        return Colors.green;
      case 'N5':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
