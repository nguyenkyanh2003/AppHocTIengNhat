import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../providers/exercise_provider.dart';
import '../../models/exercise.dart';

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
    );

    setState(() {
      _isSubmitting = false;
    });

    if (success && mounted) {
      Navigator.pushReplacementNamed(
        context,
        '/exercise-result',
        arguments: provider.currentResult,
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Có lỗi xảy ra khi nộp bài'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<ExerciseProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final exercise = provider.currentExercise;
          if (exercise == null) {
            return const Center(child: Text('Không tìm thấy bài tập'));
          }

          if (!_isStarted) {
            return _buildStartScreen(exercise);
          }

          return _buildExerciseScreen(exercise);
        },
      ),
    );
  }

  Widget _buildStartScreen(Exercise exercise) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.blue.shade400,
            Colors.blue.shade700,
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
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
                            gradient: LinearGradient(
                              colors: [
                                Colors.orange.shade400,
                                Colors.orange.shade600,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            exercise.level,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            exercise.type,
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      exercise.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    if (exercise.description != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          exercise.description!,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    _buildInfoRow(
                      Icons.quiz,
                      'Số câu hỏi',
                      '${exercise.questions.length} câu',
                      Colors.blue,
                    ),
                    const SizedBox(height: 12),
                    if (exercise.timeLimit > 0)
                      _buildInfoRow(
                        Icons.timer,
                        'Thời gian',
                        '${exercise.timeLimit} phút',
                        Colors.orange,
                      ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      Icons.check_circle,
                      'Điểm đạt',
                      '${exercise.passScore}%',
                      Colors.green,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _startExercise,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Bắt đầu làm bài',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseScreen(Exercise exercise) {
    final minutes = _secondsElapsed ~/ 60;
    final seconds = _secondsElapsed % 60;
    final timeString = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.blue.shade50,
            Colors.white,
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildProgressBar(exercise),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // Disable swipe, use buttons only
                itemCount: exercise.questions.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentQuestionIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  return _buildQuestionCard(exercise.questions[index], index);
                },
              ),
            ),
            _buildBottomBar(exercise, timeString),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(Exercise exercise) {
    final answered = _userAnswers.length;
    final total = exercise.questions.length;
    final progress = total > 0 ? answered / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$answered/$total câu',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(Question question, int index) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue.shade400,
                            Colors.blue.shade600,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Câu hỏi',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  question.content,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...question.answers.asMap().entries.map((entry) {
            final answerIndex = entry.key;
            final answer = entry.value;
            final isSelected = _userAnswers[question.id] == answer.id;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _userAnswers[question.id] = answer.id;
                });
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue.shade50 : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? Colors.blue.shade600 : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? Colors.blue.shade600 : Colors.white,
                        border: Border.all(
                          color: isSelected ? Colors.blue.shade600 : Colors.grey.shade400,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          String.fromCharCode(65 + answerIndex),
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        answer.content,
                        style: TextStyle(
                          fontSize: 16,
                          color: isSelected ? Colors.blue.shade900 : Colors.black87,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color: Colors.blue.shade600,
                        size: 24,
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildBottomBar(Exercise exercise, String timeString) {
    final isFirstQuestion = _currentQuestionIndex == 0;
    final isLastQuestion = _currentQuestionIndex == exercise.questions.length - 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Timer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.timer, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 8),
                Text(
                  timeString,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Navigation buttons
          Row(
            children: [
              // Previous button
              if (!isFirstQuestion)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Câu trước'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue.shade700,
                      side: BorderSide(color: Colors.blue.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              if (!isFirstQuestion) const SizedBox(width: 12),
              // Next or Submit button
              Expanded(
                flex: isFirstQuestion ? 1 : 1,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting
                      ? null
                      : () {
                          if (isLastQuestion) {
                            _submitExercise();
                          } else {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                  icon: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(isLastQuestion ? Icons.check : Icons.arrow_forward),
                  label: Text(isLastQuestion ? 'Nộp bài' : 'Câu tiếp'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isLastQuestion ? Colors.green.shade600 : Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
