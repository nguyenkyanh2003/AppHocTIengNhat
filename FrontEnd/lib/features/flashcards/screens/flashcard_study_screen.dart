import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/content_pane.dart';
import '../../vocabulary/models/vocabulary.dart';
import '../../vocabulary/providers/vocabulary_provider.dart';
import '../models/flashcard_deck.dart';
import '../widgets/flashcard_completion_card.dart';
import '../widgets/flashcard_study_controls.dart';
import '../widgets/flashcard_study_parts.dart';
import '../widgets/flashcard_widget.dart';

class FlashcardStudyScreen extends StatefulWidget {
  final String? level;
  final List<Vocabulary>? vocabularies;
  final FlashcardDeck? flashcardDeck; // Hỗ trợ bộ thẻ tùy chỉnh

  const FlashcardStudyScreen({super.key, this.level, this.vocabularies, this.flashcardDeck});

  @override
  State<FlashcardStudyScreen> createState() => _FlashcardStudyScreenState();
}

class _FlashcardStudyScreenState extends State<FlashcardStudyScreen> {
  int _currentIndex = 0;
  List<FlashcardFace> _studyList = [];
  bool _isLoading = true;
  final _pageController = PageController();

  @override
  void initState() {
    super.initState();
    // Sau khung hình đầu: tải theo cấp độ đi qua VocabularyProvider, mà provider
    // không được báo thay đổi khi cây đang dựng.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadCards();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool get _canGoBack => _currentIndex > 0;
  bool get _canGoForward => _currentIndex < _studyList.length;

  void _goToPrevious() {
    if (_canGoBack) _pageController.previousPage(duration: AppDurations.normal, curve: Curves.easeOut);
  }

  void _goToNext() {
    if (_canGoForward) _pageController.nextPage(duration: AppDurations.normal, curve: Curves.easeOut);
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

  /// Bộ thẻ tự tạo, danh sách từ được truyền vào, hoặc từ vựng tải theo cấp độ.
  Future<void> _loadCards() async {
    final List<FlashcardFace> cards;
    final deck = widget.flashcardDeck;
    final words = widget.vocabularies;
    if (deck != null) {
      cards = deck.cards.map(faceOfCard).toList();
    } else if (words != null) {
      cards = words.map(faceOfVocabulary).toList();
    } else {
      final provider = context.read<VocabularyProvider>();
      if (widget.level != null) {
        await provider.filterByLevel(widget.level);
      } else {
        await provider.loadVocabularies();
      }
      cards = provider.vocabularies.map(faceOfVocabulary).toList();
    }

    cards.shuffle(math.Random());
    if (mounted) {
      setState(() {
        _studyList = cards;
        _isLoading = false;
      });
    }
  }

  void _restartStudy() {
    setState(() => _studyList.shuffle(math.Random()));
    _pageController.jumpToPage(0);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _studyList.isEmpty) {
      return AppScaffold(
        title: 'Học Flashcard',
        body: ContentWidthLimit(
          child: _isLoading ? const Center(child: CircularProgressIndicator()) : const FlashcardStudyEmpty(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.colors.surfaceVariant,
      appBar: AppBar(
        title: const Text('Học Flashcard'),
        elevation: 0,
        backgroundColor: context.colors.surfaceVariant,
        foregroundColor: context.colors.textPrimary,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: AppSpacing.lg),
              child: Text(
                '${_currentIndex + 1}/${_studyList.length}',
                style: Theme.of(context).textTheme.titleMedium,
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
                FlashcardStudyProgress(current: _currentIndex, total: _studyList.length),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _studyList.length + 1,
                    onPageChanged: (index) => setState(() => _currentIndex = index),
                    itemBuilder: (context, index) {
                      if (index == _studyList.length) {
                        return FlashcardCompletionCard(restartStudy: _restartStudy);
                      }
                      final card = _studyList[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                        child: FlashcardWidget(
                          frontText: card.front,
                          frontSubtext: card.frontSubtext,
                          backText: card.back,
                          backSubtext: card.backSubtext,
                        ),
                      );
                    },
                  ),
                ),
                FlashcardNavigationControls(
                  currentIndex: _currentIndex,
                  studyList: _studyList,
                  canGoBack: _canGoBack,
                  canGoForward: _canGoForward,
                  goToPrevious: _goToPrevious,
                  goToNext: _goToNext,
                ),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
