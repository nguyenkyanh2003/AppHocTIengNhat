import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/state/detail_state.dart';
import '../../../core/state/view_state.dart';
import '../../../core/utils/attempt_id.dart';
import '../models/jlpt_models.dart';
import '../services/jlpt_service.dart';

/// Một lượt thi: đề, đồng hồ đếm ngược, bài làm, nộp bài và đáp án sau khi nộp.
class JLPTExamProvider extends ChangeNotifier {
  JLPTExamProvider({JLPTService? service}) : _service = service ?? JLPTService();

  final JLPTService _service;
  late final _exam = DetailState<JLPTExamDetail>(idOf: (exam) => exam.id, onChanged: _notify);

  /// Khoá câu (`moji-0`, `dokkai-1-2`...) → lựa chọn 0–3.
  final Map<String, int> _answers = {};
  Timer? _timer;
  int _secondsLeft = 0;
  bool _submitting = false;
  JLPTSubmitResult? _result;
  ViewState<List<JLPTQuestion>> _solutions = const ViewState.idle();
  bool _disposed = false;

  /// Định danh lượt thi, sinh khi mở đề. Nộp lại sau lỗi mạng dùng lại đúng ID
  /// này nên không bị chấm hai lần; mở đề lần nữa là một lượt thi mới.
  String _attemptId = newAttemptId();

  ViewState<JLPTExamDetail> examOf(String id) => _exam.of(id);
  Map<String, int> get answers => Map.unmodifiable(_answers);
  int get secondsLeft => _secondsLeft;
  bool get isSubmitting => _submitting;
  bool get hasSubmitted => _result != null;
  JLPTSubmitResult? get result => _result;

  /// Đáp án theo thứ tự câu trong đề; rỗng khi chưa nộp hoặc chưa tải được.
  List<JLPTQuestion> get solutions => _solutions.valueOrNull ?? const [];

  /// Mở đề [id] như một lượt thi mới: bài làm, kết quả và đồng hồ về đầu.
  Future<void> loadExam(String id) async {
    _timer?.cancel();
    _attemptId = newAttemptId();
    _answers.clear();
    _result = null;
    _solutions = const ViewState.idle();

    await _exam.load(id, () => _service.detail(id));
    final exam = _exam.of(id).valueOrNull;
    if (exam == null || _disposed) return;
    _secondsLeft = exam.timeLimit * 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (_secondsLeft <= 0) {
      _timer?.cancel();
      return;
    }
    _secondsLeft -= 1;
    _notify();
  }

  /// Nộp rồi thì bài làm khoá lại.
  void setAnswer(String key, int choice) {
    if (_result != null) return;
    _answers[key] = choice;
    _notify();
  }

  /// Nộp bài đang làm; trả `null` khi xong (kèm tải đáp án), hoặc câu báo lỗi
  /// để màn hiện — bài làm giữ nguyên để nộp lại với cùng lượt thi.
  Future<String?> submit() async {
    final exam = _exam.state.valueOrNull;
    if (exam == null || _result != null || _submitting) return null;
    _submitting = true;
    _notify();

    final submitted = await ViewState.guard(() => _service.submit(
          exam.id,
          attemptId: _attemptId,
          answers: Map.of(_answers),
          timeSpent: exam.timeLimit * 60 - _secondsLeft,
        ));
    _submitting = false;
    if (submitted case ViewData(:final value)) {
      _result = value;
      _timer?.cancel();
      _solutions = const ViewState.loading();
      _notify();
      _solutions = await ViewState.guard(() => _service.solutions(exam.id));
    }
    _notify();
    return submitted.errorOrNull;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
