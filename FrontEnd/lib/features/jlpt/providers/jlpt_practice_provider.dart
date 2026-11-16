import 'package:flutter/foundation.dart';

import '../../../core/state/view_state.dart';
import '../models/jlpt_practice_question.dart';
import '../services/jlpt_service.dart';

/// Một bộ câu luyện nhanh. Chấm ngay trên máy và không lưu lên server: đây là ôn
/// nhanh, không phải một lượt thi.
class JLPTPracticeProvider extends ChangeNotifier {
  JLPTPracticeProvider({JLPTService? service}) : _service = service ?? JLPTService();

  final JLPTService _service;
  ViewState<List<JlptPracticeQuestion>> _questions = const ViewState.idle();
  final Map<int, int> _answers = {};
  int _generation = 0;
  bool _disposed = false;

  ViewState<List<JlptPracticeQuestion>> get questions => _questions;

  int? answerOf(int index) => _answers[index];
  int get answeredCount => _answers.length;
  int get correctCount {
    final items = _questions.valueOrNull ?? const [];
    return _answers.entries.where((entry) => items[entry.key].correctAnswer == entry.value).length;
  }

  /// Bộ câu mới thì câu trả lời cũ bị bỏ.
  Future<void> loadPractice({required String type, String? level, int limit = 10}) async {
    final generation = ++_generation;
    _answers.clear();
    _questions = const ViewState.loading();
    _notify();

    final result = await ViewState.guard(() => _service.practice(type: type, level: level, limit: limit));
    if (generation != _generation) return;
    _questions = result;
    _notify();
  }

  /// Ghi câu trả lời. Đã trả lời thì không đổi được, vì đáp án đã hiện ra.
  void answer(int index, int choice) {
    if (_answers.containsKey(index)) return;
    _answers[index] = choice;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
