import 'package:flutter/material.dart';

import '../../../core/utils/attempt_id.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../providers/exercise_provider.dart';
import '../models/exercise.dart';
import '../../../shared/widgets/content_pane.dart';
import '../../../app/theme/app_tokens.dart';
import '../widgets/exercise_start_view.dart';
import '../widgets/exercise_progress_bar.dart';
import '../widgets/exercise_question_card.dart';
import '../widgets/exercise_bottom_bar.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../core/state/view_state.dart';

class ExerciseDetailScreen extends StatefulWidget {
  final String exerciseId;

  const ExerciseDetailScreen({
    super.key,
    required this.exerciseId,
  });

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  final Map<String, String> _userAnswers = {};
  final PageController _pageController = PageController();
  Timer? _timer;
  int _secondsElapsed = 0;
  int _currentQuestionIndex = 0;
  bool _isStarted = false;
  bool _isSubmitting = false;

  /// Định danh lượt làm hiện tại, sinh khi bấm bắt đầu.
  ///
  /// Giữ nguyên suốt lượt: nộp bài lỗi mạng rồi bấm nộp lại vẫn là **một**
  /// lượt, nên server trả lại kết quả cũ thay vì chấm và cộng XP lần nữa.
  String _attemptId = newAttemptId();

  @override
  void initState() {
    super.initState();
    // Load exercise after build phase completes
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _loadExercise();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _loadExercise() {
    context.read<ExerciseProvider>().loadExerciseDetail(widget.exerciseId);
  }

  void _startExercise() {
    setState(() {
      _isStarted = true;
      // Lượt mới thì định danh mới — đây mới là "làm lại", khác với nộp lại.
      _attemptId = newAttemptId();
    });
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsElapsed++;
      });

      // Check time limit
      final exercise = context.read<ExerciseProvider>().currentExercise;
      if (exercise != null &&
          exercise.timeLimit > 0 &&
          _secondsElapsed >= exercise.timeLimit * 60) {
        _submitExercise();
      }
    });
  }

  Future<void> _submitExercise() async {
    if (_isSubmitting) return;

    final exercise = context.read<ExerciseProvider>().currentExercise;
    if (exercise == null) return;

    // Check if all questions are answered
    if (_userAnswers.length < exercise.questions.length) {
      final shouldContinue = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Chưa hoàn thành'),
          content: Text(
            'Bạn mới trả lời ${_userAnswers.length}/${exercise.questions.length} câu.\nBạn có muốn nộp bài không?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Tiếp tục'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Nộp bài'),
            ),
          ],
        ),
      );

      if (shouldContinue != true) return;
    }

    if (!mounted) return;

    setState(() {
      _isSubmitting = true;
    });

    _timer?.cancel();

    // Convert user answers to UserAnswer list
    final answers = _userAnswers.entries.map((entry) {
      return UserAnswer(
        questionId: entry.key,
        answerId: entry.value,
        isCorrect: false, // Will be calculated by backend
      );
    }).toList();

    final provider = context.read<ExerciseProvider>();
    final success = await provider.submitExercise(
      widget.exerciseId,
      answers,
      _secondsElapsed,
      attemptId: _attemptId,
    );

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    if (success && mounted) {
      final resultId = provider.currentResult?.id;
      if (resultId != null) {
        context.pushReplacement('/exercise/result/$resultId');
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Có lỗi xảy ra khi nộp bài'),
          backgroundColor: AppColors.errorStrong,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ContentWidthLimit(
        child: Consumer<ExerciseProvider>(
          builder: (context, provider, child) {
            final exercise = provider.currentExercise;
            // Đang làm dở mà nộp lỗi thì giữ nguyên bài: lỗi nộp được báo riêng,
            // không được xoá câu trả lời của người học.
            final failed = !_isStarted && provider.error != null;
            if (provider.isLoading || failed || exercise == null) {
              return AsyncView<Exercise>(
                state: ViewState.detail(
                  isLoading: provider.isLoading,
                  error: provider.error,
                  value: exercise,
                ),
                onRetry: () => provider.loadExerciseDetail(widget.exerciseId),
                builder: (context, _) => const SizedBox.shrink(),
              );
            }

            if (!_isStarted) {
              return ExerciseStartView(
                  exercise: exercise, startExercise: _startExercise);
            }

            return _buildExerciseScreen(exercise);
          },
        ),
      ),
    );
  }

  Widget _buildExerciseScreen(Exercise exercise) {
    final minutes = _secondsElapsed ~/ 60;
    final seconds = _secondsElapsed % 60;
    final timeString =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            context.colors.primarySoft,
            context.colors.surface,
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            ExerciseProgressBar(exercise: exercise, userAnswers: _userAnswers),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics:
                    const NeverScrollableScrollPhysics(), // Disable swipe, use buttons only
                itemCount: exercise.questions.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentQuestionIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  return ExerciseQuestionCard(
                      question: exercise.questions[index],
                      index: index,
                      userAnswers: _userAnswers,
                      selectAnswer: _selectAnswer);
                },
              ),
            ),
            ExerciseBottomBar(
                exercise: exercise,
                timeString: timeString,
                pageController: _pageController,
                currentQuestionIndex: _currentQuestionIndex,
                isSubmitting: _isSubmitting,
                submitExercise: _submitExercise),
          ],
        ),
      ),
    );
  }

  void _selectAnswer(String questionId, String answerId) {
    setState(() => _userAnswers[questionId] = answerId);
  }
}
