import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../core/utils/attempt_id.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/content_pane.dart';
import '../models/exercise.dart';
import '../providers/exercise_provider.dart';
import '../widgets/exercise_bottom_bar.dart';
import '../widgets/exercise_progress_bar.dart';
import '../widgets/exercise_question_card.dart';
import '../widgets/exercise_start_view.dart';
import '../widgets/exercise_submit_dialog.dart';

class ExerciseDetailScreen extends StatefulWidget {
  const ExerciseDetailScreen({super.key, required this.exerciseId});

  final String exerciseId;

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

  /// Định danh lượt làm hiện tại, sinh khi bấm bắt đầu.
  ///
  /// Giữ nguyên suốt lượt: nộp bài lỗi mạng rồi bấm nộp lại vẫn là **một**
  /// lượt, nên server trả lại kết quả cũ thay vì chấm và cộng XP lần nữa.
  String _attemptId = newAttemptId();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadExercise();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadExercise() => context.read<ExerciseProvider>().loadDetail(widget.exerciseId);

  Exercise? get _exercise => context.read<ExerciseProvider>().detailOf(widget.exerciseId).valueOrNull;

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
      setState(() => _secondsElapsed++);
      final limit = _exercise?.timeLimit ?? 0;
      if (limit > 0 && _secondsElapsed >= limit * 60) _submitExercise(timeUp: true);
    });
  }

  /// Nộp bài. Người học tự bấm nộp khi còn câu bỏ trống thì hỏi lại; hết giờ
  /// thì nộp luôn — không còn gì để hỏi, và đồng hồ vẫn chạy sẽ mở thêm một hộp
  /// thoại mỗi giây nếu cứ hỏi.
  Future<void> _submitExercise({bool timeUp = false}) async {
    final provider = context.read<ExerciseProvider>();
    final exercise = _exercise;
    if (provider.isSubmitting || exercise == null) return;

    if (timeUp) {
      _timer?.cancel();
    } else if (_userAnswers.length < exercise.questions.length) {
      final submit = await confirmPartialSubmit(
        context,
        answered: _userAnswers.length,
        total: exercise.questions.length,
      );
      if (!submit || provider.isSubmitting) return;
    }
    if (!mounted) return;
    _timer?.cancel();

    // Đúng sai do server chấm; lỗi thì giữ nguyên bài làm để nộp lại cùng lượt.
    final submitted = await provider.submit(
      widget.exerciseId,
      answers: Map.of(_userAnswers),
      timeSpent: _secondsElapsed,
      attemptId: _attemptId,
    );
    if (!mounted) return;

    if (submitted.valueOrNull case final result?) {
      context.pushReplacement('/exercise/result/${result.id}');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(submitted.errorOrNull ?? 'Có lỗi xảy ra khi nộp bài'),
        backgroundColor: AppColors.errorStrong,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ContentWidthLimit(
        child: AsyncView<Exercise>(
          state: context.watch<ExerciseProvider>().detailOf(widget.exerciseId),
          onRetry: _loadExercise,
          builder: (context, exercise) => _isStarted
              ? _buildExerciseScreen(exercise)
              : ExerciseStartView(exercise: exercise, startExercise: _startExercise),
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
                isSubmitting: context.watch<ExerciseProvider>().isSubmitting,
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
