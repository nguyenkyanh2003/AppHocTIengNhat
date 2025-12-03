import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_html/flutter_html.dart';
import '../../config/theme.dart';
import '../../providers/lesson_provider.dart';
import '../../providers/lesson_progress_provider.dart';
import '../../models/lesson.dart';
import '../../services/lesson_progress_service.dart';

class LessonStudyScreen extends StatefulWidget {
  final String lessonId;

  const LessonStudyScreen({
    Key? key,
    required this.lessonId,
  }) : super(key: key);

  @override
  State<LessonStudyScreen> createState() => _LessonStudyScreenState();
}

class _LessonStudyScreenState extends State<LessonStudyScreen> {
  int _currentStep = 0;
  final PageController _pageController = PageController();
  final LessonProgressService _progressService = LessonProgressService();
  bool _isCompletingLesson = false;

  @override
  void initState() {
    super.initState();
    // Bắt đầu học bài - tạo hoặc cập nhật progress record
    _startLesson();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _startLesson() async {
    try {
      await _progressService.startLesson(widget.lessonId);
    } catch (e) {
      print('Error starting lesson: $e');
    }
  }

  Future<void> _completeLesson() async {
    if (_isCompletingLesson) return;

    setState(() {
      _isCompletingLesson = true;
    });

    try {
      // Gọi API để đánh dấu bài học hoàn thành
      await _progressService.completeLesson(widget.lessonId);

      // Reload progress trong provider
      if (mounted) {
        await Provider.of<LessonProgressProvider>(context, listen: false)
            .loadProgress(widget.lessonId);

        // Hiển thị thông báo thành công
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chúc mừng! Bạn đã hoàn thành bài học'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Quay về màn hình trước
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi lưu tiến độ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCompletingLesson = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Học bài'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _showExitConfirmation(),
          ),
        ],
      ),
      body: Consumer<LessonProvider>(
        builder: (context, provider, child) {
          if (provider.currentLessonDetail == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final lessonDetail = provider.currentLessonDetail!;
          final lesson = lessonDetail.lesson;

          return Column(
            children: [
              // Progress indicator
              _buildProgressBar(lessonDetail),

              // Content
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentStep = index;
                    });
                  },
                  children: [
                    _buildIntroductionStep(lesson),
                    if (lessonDetail.vocabularies.isNotEmpty)
                      _buildVocabularyStep(lessonDetail.vocabularies),
                    if (lessonDetail.kanjis.isNotEmpty)
                      _buildKanjiStep(lessonDetail.kanjis),
                    if (lessonDetail.grammars.isNotEmpty)
                      _buildGrammarStep(lessonDetail.grammars),
                    _buildSummaryStep(lesson, lessonDetail),
                  ],
                ),
              ),

              // Navigation buttons
              _buildNavigationButtons(lessonDetail),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProgressBar(LessonDetail detail) {
    int totalSteps = 2; // Intro + Summary
    if (detail.vocabularies.isNotEmpty) totalSteps++;
    if (detail.kanjis.isNotEmpty) totalSteps++;
    if (detail.grammars.isNotEmpty) totalSteps++;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bước ${_currentStep + 1}/$totalSteps',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                '${((_currentStep + 1) / totalSteps * 100).toInt()}%',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (_currentStep + 1) / totalSteps,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        ],
      ),
    );
  }

  Widget _buildIntroductionStep(Lesson lesson) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Icon(
              Icons.school,
              size: 80,
              color: AppTheme.getJlptLevelColor(lesson.level),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              lesson.title,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          if (lesson.description != null)
            Center(
              child: Text(
                lesson.description!,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 32),
          if (lesson.contentHtml != null && lesson.contentHtml!.isNotEmpty) ...[
            const Text(
              'Giới thiệu',
              style: TextStyle(
                fontSize: 20,
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
          ],
          const SizedBox(height: 24),
          _buildLearningObjectives(lesson),
        ],
      ),
    );
  }

  Widget _buildLearningObjectives(Lesson lesson) {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.flag, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Mục tiêu bài học',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (lesson.vocabularies.isNotEmpty)
              _buildObjectiveItem(
                  'Học ${lesson.vocabularies.length} từ vựng mới'),
            if (lesson.kanjis.isNotEmpty)
              _buildObjectiveItem('Nhận biết ${lesson.kanjis.length} chữ Kanji'),
            if (lesson.grammars.isNotEmpty)
              _buildObjectiveItem(
                  'Nắm vững ${lesson.grammars.length} cấu trúc ngữ pháp'),
            _buildObjectiveItem('Hoàn thành bài tập và đánh giá'),
          ],
        ),
      ),
    );
  }

  Widget _buildObjectiveItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _buildVocabularyStep(List<dynamic> vocabularies) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: vocabularies.length,
      itemBuilder: (context, index) {
        final vocab = vocabularies[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vocab['word'] ?? vocab.toString(),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (vocab['reading'] != null)
                            Text(
                              vocab['reading'],
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.volume_up),
                      onPressed: () {
                        // Play audio
                      },
                    ),
                  ],
                ),
                const Divider(height: 24),
                Text(
                  vocab['meaning'] ?? 'Không có nghĩa',
                  style: const TextStyle(fontSize: 16),
                ),
                if (vocab['example'] != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ví dụ:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(vocab['example']),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildKanjiStep(List<dynamic> kanjis) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: kanjis.length,
      itemBuilder: (context, index) {
        final kanji = kanjis[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  kanji['character'] ?? kanji.toString(),
                  style: const TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                if (kanji['meaning'] != null)
                  Text(
                    kanji['meaning'],
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                if (kanji['kunyomi'] != null || kanji['onyomi'] != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${kanji['kunyomi'] ?? ''} / ${kanji['onyomi'] ?? ''}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGrammarStep(List<dynamic> grammars) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: grammars.length,
      itemBuilder: (context, index) {
        final grammar = grammars[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.green,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        grammar['pattern'] ?? grammar.toString(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Text(
                  grammar['meaning'] ?? 'Không có nghĩa',
                  style: const TextStyle(fontSize: 16),
                ),
                if (grammar['usage'] != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(grammar['usage']),
                  ),
                ],
                if (grammar['example'] != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ví dụ:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(grammar['example']),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryStep(Lesson lesson, LessonDetail detail) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(
            Icons.celebration,
            size: 80,
            color: Colors.amber,
          ),
          const SizedBox(height: 24),
          const Text(
            'Chúc mừng!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bạn đã hoàn thành bài học',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    'Tổng kết',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSummaryItem(
                    Icons.book,
                    'Từ vựng',
                    '${detail.vocabularies.length}',
                    Colors.blue,
                  ),
                  _buildSummaryItem(
                    Icons.style,
                    'Kanji',
                    '${detail.kanjis.length}',
                    Colors.orange,
                  ),
                  _buildSummaryItem(
                    Icons.text_fields,
                    'Ngữ pháp',
                    '${detail.grammars.length}',
                    Colors.green,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // Navigate to exercise
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tính năng bài tập đang phát triển'),
                  ),
                );
              },
              icon: const Icon(Icons.quiz),
              label: const Text('Làm bài tập'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Quay lại'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
      IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(LessonDetail detail) {
    int totalSteps = 2;
    if (detail.vocabularies.isNotEmpty) totalSteps++;
    if (detail.kanjis.isNotEmpty) totalSteps++;
    if (detail.grammars.isNotEmpty) totalSteps++;

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
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Quay lại'),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 12),
            Expanded(
              flex: _currentStep == 0 ? 1 : 1,
              child: ElevatedButton(
                onPressed: _isCompletingLesson ? null : () {
                  if (_currentStep < totalSteps - 1) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  } else {
                    // Hoàn thành bài học và cập nhật progress
                    _completeLesson();
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isCompletingLesson
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        _currentStep < totalSteps - 1 ? 'Tiếp theo' : 'Hoàn thành',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thoát học bài?'),
        content: const Text('Bạn có chắc muốn thoát? Tiến độ học của bạn sẽ không được lưu.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close study screen
            },
            child: const Text('Thoát'),
          ),
        ],
      ),
    );
  }
}
