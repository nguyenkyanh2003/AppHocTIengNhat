import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../../providers/vocabulary_provider.dart';
import '../../models/vocabulary.dart';
import '../../widgets/flashcard_widget.dart';
import '../../config/theme.dart';

class FlashcardStudyScreen extends StatefulWidget {
  final String? level;
  final List<Vocabulary>? vocabularies;

  const FlashcardStudyScreen({
    Key? key,
    this.level,
    this.vocabularies,
  }) : super(key: key);

  @override
  State<FlashcardStudyScreen> createState() => _FlashcardStudyScreenState();
}

class _FlashcardStudyScreenState extends State<FlashcardStudyScreen> {
  int _currentIndex = 0;
  List<Vocabulary> _studyList = [];
  bool _isLoading = true;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadVocabularies();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadVocabularies() async {
    setState(() => _isLoading = true);

    List<Vocabulary> loadedVocabs;
    if (widget.vocabularies != null) {
      loadedVocabs = List.from(widget.vocabularies!);
    } else {
      final provider = context.read<VocabularyProvider>();
      if (widget.level != null) {
        await provider.filterByLevel(widget.level);
      } else {
        await provider.loadVocabularies();
      }
      loadedVocabs = provider.vocabularies;
    }
    
    loadedVocabs.shuffle(math.Random());

    if (mounted) {
      setState(() {
        _studyList = loadedVocabs;
        _isLoading = false;
      });
    }
  }

  void _restartStudy() {
    setState(() {
      _studyList.shuffle(math.Random());
      _isLoading = false;
      _pageController.jumpToPage(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Học Flashcard')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_studyList.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Học Flashcard')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox_rounded, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Không có từ vựng để học',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Quay lại'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Học Flashcard'),
        elevation: 0,
        backgroundColor: Colors.grey[100],
        foregroundColor: Colors.black,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                '${_currentIndex + 1}/${_studyList.length}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildProgressBar(),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _studyList.length + 1,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  if (index == _studyList.length) {
                    return _buildCompletionCard();
                  }
                  final vocab = _studyList[index];
                  return Container(
                     padding: const EdgeInsets.symmetric(vertical: 16),
                     child: FlashcardWidget(
                      frontText: vocab.word,
                      frontSubtext: vocab.hiragana,
                      backText: vocab.meaning,
                      backSubtext: vocab.examples.isNotEmpty
                          ? vocab.examples.first.sentence
                          : null,
                    ),
                  );
                },
              ),
            ),
            _buildNavigationHint(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    final progress = _studyList.isEmpty ? 0.0 : (_currentIndex) / _studyList.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: LinearProgressIndicator(
          value: progress,
          minHeight: 10,
          backgroundColor: Colors.grey[300],
          valueColor: const AlwaysStoppedAnimation<Color>(
            AppTheme.primaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationHint() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blueGrey[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.touch_app_outlined, color: AppTheme.primaryColor, size: 20),
            SizedBox(width: 12),
            Text(
              'Chạm để lật, vuốt để chuyển thẻ',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w500,
                fontSize: 16
              ),
            ),
          ],
        ),
      ),
    );
  }

   Widget _buildCompletionCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 4,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 80),
              const SizedBox(height: 24),
              const Text(
                'Hoàn thành!',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Bạn đã học hết bộ từ này.',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Học lại từ đầu'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _restartStudy,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Thoát'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
