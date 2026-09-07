import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/jlpt_models.dart';
import '../services/jlpt_service.dart';

class JLPTExamProvider with ChangeNotifier {
  final JLPTService _service = JLPTService();

  JLPTExamDetail? _exam;
  bool _loading = false;
  bool _submitting = false;
  final Map<String, int> _answers =
      {}; // key: section-index, value: choice index
  Timer? _timer;
  int _secondsLeft = 0;
  JLPTSubmitResult? _result;
  List<JLPTQuestion> _solutions = [];
  bool _loadingSolutions = false;

  JLPTExamDetail? get exam => _exam;
  bool get isLoading => _loading;
  bool get isSubmitting => _submitting;
  bool get hasSubmitted => _result != null;
  int get secondsLeft => _secondsLeft;
  JLPTSubmitResult? get result => _result;
  Map<String, int> get answers => _answers;
  List<JLPTQuestion> get solutions => _solutions;
  bool get isLoadingSolutions => _loadingSolutions;

  Future<void> loadExam(String id) async {
    _loading = true;
    _exam = null;
    _answers.clear();
    _result = null;
    _solutions = [];
    _loadingSolutions = false;
    _timer?.cancel();
    notifyListeners();
    try {
      final data = await _service.fetchExamDetail(id);
      _exam = data;
      _secondsLeft = data.timeLimit * 60;
      _startTimer();
    } catch (e) {
      debugPrint('Error load exam: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 0) {
        t.cancel();
        notifyListeners();
        return;
      }
      _secondsLeft -= 1;
      notifyListeners();
    });
  }

  void setAnswer(String key, int choiceIndex) {
    if (_result != null) return; // prevent changes after submission
    _answers[key] = choiceIndex;
    notifyListeners();
  }

  Future<void> submit(String examId) async {
    if (_exam == null || _result != null) return; // block re-submit
    _submitting = true;
    notifyListeners();
    try {
      final payload = {
        'ThoiGianLamBai': (_exam!.timeLimit * 60) - _secondsLeft,
        'answers': _answers.entries
            .map((e) => {
                  'question_key': e.key,
                  'selected': e.value,
                })
            .toList()
      };
      final resp = await _service.submitExam(examId, payload);
      _result = resp;
      _timer?.cancel();
      await loadSolutions(examId);
    } catch (e) {
      debugPrint('Error submit exam: $e');
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> loadSolutions(String examId) async {
    _loadingSolutions = true;
    _solutions = [];
    notifyListeners();
    try {
      _solutions = await _service.fetchSolutions(examId);
    } catch (e) {
      debugPrint('Error load solutions: $e');
    } finally {
      _loadingSolutions = false;
      notifyListeners();
    }
  }
}
