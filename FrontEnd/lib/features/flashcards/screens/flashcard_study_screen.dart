import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../../vocabulary/providers/vocabulary_provider.dart';
import '../../vocabulary/models/vocabulary.dart';
import '../models/flashcard_deck.dart';
import '../widgets/flashcard_widget.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/content_pane.dart';

class FlashcardStudyScreen extends StatefulWidget {
  final String? level;
  final List<Vocabulary>? vocabularies;
  final FlashcardDeck? flashcardDeck; // Hỗ trợ bộ thẻ tùy chỉnh

  const FlashcardStudyScreen({
    Key? key,
    this.level,
    this.vocabularies,
    this.flashcardDeck,
  }) : super(key: key);

  @override
  State<FlashcardStudyScreen> createState() => _FlashcardStudyScreenState();
}

class _FlashcardStudyScreenState extends State<FlashcardStudyScreen> {
  int _currentIndex = 0;
  List<dynamic> _studyList = []; // Có thể là Vocabulary hoặc FlashcardCard
  bool _isLoading = true;
  late PageController _pageController;
  bool _isCustomDeck =
      false; // Flag để biết đang học bộ thẻ tùy chỉnh hay vocabulary

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

  bool get _canGoBack => _currentIndex > 0;
  bool get _canGoForward => _currentIndex < _studyList.length;

  void _goToPrevious() {
    if (!_canGoBack) return;
    _pageController.previousPage(
      duration: AppDurations.normal,
      curve: Curves.easeOut,
    );
  }

  void _goToNext() {
    if (!_canGoForward) return;
    _pageController.nextPage(
      duration: AppDurations.normal,
      curve: Curves.easeOut,
    );
  }

  /// Mũi tên trái/phải chuyển thẻ.
  ///
  /// Trên desktop, vuốt không phải cử chỉ có thật; bàn phím và hai nút ở dưới
  /// là đường điều hướng chính, kéo chuột chỉ là lối phụ.
  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _goToPrevious();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _goToNext();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> _loadVocabularies() async {
    setState(() => _isLoading = true);

    List<dynamic> loadedItems;

    // Nếu có flashcardDeck, sử dụng bộ thẻ tùy chỉnh
    if (widget.flashcardDeck != null) {
      loadedItems = List.from(widget.flashcardDeck!.cards);
      _isCustomDeck = true;
    }
    // Nếu có vocabularies, sử dụng danh sách từ vựng có sẵn
    else if (widget.vocabularies != null) {
      loadedItems = List.from(widget.vocabularies!);
      _isCustomDeck = false;
    }
    // Nếu không, load từ provider
    else {
      final provider = context.read<VocabularyProvider>();
      if (widget.level != null) {
        await provider.filterByLevel(widget.level);
      } else {
        await provider.loadVocabularies();
      }
      loadedItems = provider.vocabularies;
      _isCustomDeck = false;
    }

    loadedItems.shuffle(math.Random());

    if (mounted) {
      setState(() {
        _studyList = loadedItems;
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
      return const AppScaffold(
        title: 'Học Flashcard',
        body: ContentWidthLimit(
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_studyList.isEmpty) {
      return AppScaffold(
        title: 'Học Flashcard',
        body: ContentWidthLimit(
          child: Center(
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
      body: ContentWidthLimit(
        child: SafeArea(
          child: Focus(
            autofocus: true,
            onKeyEvent: _handleKey,
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

                      final item = _studyList[index];

                      // Nếu là bộ thẻ tùy chỉnh
                      if (_isCustomDeck && item is FlashcardCard) {
                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: FlashcardWidget(
                            frontText: item.front,
                            frontSubtext: item.frontSubtext,
                            backText: item.back,
                            backSubtext: item.backSubtext,
                          ),
                        );
                      }
                      // Nếu là vocabulary
                      else if (item is Vocabulary) {
                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: FlashcardWidget(
                            frontText: item.word,
                            frontSubtext: item.hiragana,
                            backText: item.meaning,
                            backSubtext: item.examples.isNotEmpty
                                ? item.examples.first.sentence
                                : null,
                          ),
                        );
                      }

                      return const SizedBox.shrink();
                    },
                  ),
                ),
                _buildNavigationControls(),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    final progress =
        _studyList.isEmpty ? 0.0 : (_currentIndex) / _studyList.length;

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

  /// Điều khiển chuyển thẻ: bấm được bằng chuột, tới được bằng Tab.
  Widget _buildNavigationControls() {
    final total = _studyList.length;
    final position = _currentIndex >= total ? total : _currentIndex + 1;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          OutlinedButton.icon(
            onPressed: _canGoBack ? _goToPrevious : null,
            icon: const Icon(Icons.chevron_left),
            label: const Text('Thẻ trước'),
          ),
          Flexible(
            child: Text(
              _currentIndex >= total ? 'Đã hết thẻ' : '$position / $total',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          FilledButton.icon(
            onPressed: _canGoForward ? _goToNext : null,
            icon: const Icon(Icons.chevron_right),
            label: const Text('Thẻ sau'),
          ),
        ],
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
              const Icon(Icons.check_circle_outline_rounded,
                  color: Colors.green, size: 80),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
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
