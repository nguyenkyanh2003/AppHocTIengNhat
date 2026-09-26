import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/state/view_state.dart';
import '../../vocabulary/models/vocabulary.dart';
import '../models/lesson.dart';
import '../models/lesson_progress.dart';
import '../models/lesson_study_step.dart';
import '../models/quick_quiz.dart';
import '../services/lesson_progress_service.dart';

/// Trạng thái một phiên học bài: đang ở bước nào, từ nào đã nhớ, câu kiểm tra
/// nào đã trả lời, và kết quả lưu bài.
///
/// Sống cùng màn học (tạo khi mở, huỷ khi đóng) chứ không đăng ký toàn cục:
/// mỗi lần vào học là một phiên mới. Tiến độ **từng từ** được lưu ngay khi
/// người học bấm "Đã nhớ", nên rời giữa chừng không mất gì đã học.
class LessonStudySession extends ChangeNotifier {
  LessonStudySession({
    required this.detail,
    LessonProgressService? service,
    int initialStep = 0,
  })  : _service = service ?? LessonProgressService(),
        steps = buildStudySteps(detail),
        quiz = buildQuickQuiz(detail.words) {
    _index = initialStep.clamp(0, steps.length - 2);
  }

  final LessonDetail detail;
  final List<StudyStep> steps;
  final List<QuizQuestion> quiz;
  final LessonProgressService _service;

  late int _index;
  final Set<String> _learned = {};
  final Set<String> _saving = {};
  final Map<int, int> _answers = {};
  ViewState<LessonProgress> _completion = const ViewState.idle();
  String? _message;
  bool _disposed = false;

  String get lessonId => detail.lesson.id;
  int get index => _index;
  StudyStep get step => steps[_index];
  bool get isFinished => step.kind == StudyStepKind.finish;

  /// Bước kiểm tra chỉ cho đi tiếp khi đã trả lời hết.
  bool get canContinue => step.kind != StudyStepKind.quiz || _answers.length == quiz.length;

  bool isLearned(Vocabulary word) => _learned.contains(word.id);
  bool isSaving(Vocabulary word) => _saving.contains(word.id);
  int get learnedCount => detail.words.where(isLearned).length;

  int? answerOf(int question) => _answers[question];
  int get correctAnswers => _answers.entries.where((e) => quiz[e.key].isCorrect(e.value)).length;

  ViewState<LessonProgress> get completion => _completion;

  /// Thông báo một lần (lưu từ thất bại...). Đọc xong thì xoá.
  String? consumeMessage() {
    final message = _message;
    _message = null;
    return message;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  /// Mở bài (0 XP, tạo bản ghi tiến độ nếu chưa có) và nạp những từ đã học.
  Future<void> start() async {
    final progress = await _service.startLesson(lessonId);
    if (progress != null) _learned.addAll(progress.learnedVocabularyIds);
    _notify();
  }

  /// Sang bước kế. Tới bước cuối thì lưu hoàn thành bài và chờ kết quả, để
  /// màn học biết khi nào được đọc lại số XP mới.
  Future<void> next() async {
    if (isFinished || !canContinue) return;
    _index += 1;
    _notify();
    if (isFinished) await complete();
  }

  void back() {
    if (_index == 0 || isFinished) return;
    _index -= 1;
    _notify();
  }

  /// Lưu một từ là đã nhớ. Gọi lại với từ đã lưu hoặc đang lưu thì bỏ qua,
  /// để bấm đôi không gửi hai lần.
  Future<void> markLearned(Vocabulary word) => _setLearned(word, true);

  /// Gỡ dấu "Đã nhớ" của một từ bấm nhầm. Backend không trừ XP và cũng không
  /// cộng lại khi đánh dấu lần nữa, nên bấm qua bấm lại không lợi dụng được.
  Future<void> unmarkLearned(Vocabulary word) => _setLearned(word, false);

  Future<void> _setLearned(Vocabulary word, bool learned) async {
    if (isLearned(word) == learned || isSaving(word)) return;
    _saving.add(word.id);
    _notify();

    final progress = await _service.updateProgress(
      lessonId: lessonId,
      itemType: 'vocabulary',
      itemId: word.id,
      completed: learned,
    );
    _saving.remove(word.id);
    if (progress == null) {
      _message = learned
          ? 'Chưa lưu được "${word.word}". Kiểm tra kết nối rồi bấm lại.'
          : 'Chưa bỏ đánh dấu được "${word.word}". Kiểm tra kết nối rồi bấm lại.';
    } else if (learned) {
      _learned.add(word.id);
    } else {
      _learned.remove(word.id);
    }
    _notify();
  }

  /// Trả lời một câu kiểm tra; mỗi câu chỉ trả lời một lần.
  void answer(int question, int choice) {
    if (_answers.containsKey(question)) return;
    _answers[question] = choice;
    _notify();
  }

  /// Lưu hoàn thành bài. Gọi lại được sau khi lỗi.
  Future<void> complete() async {
    if (_completion.isLoading) return;
    _completion = const ViewState.loading();
    _notify();
    _completion = await ViewState.guard(() async {
      final progress = await _service.completeLesson(lessonId);
      if (progress == null) {
        throw ApiException('Chưa lưu được kết quả bài học. Kiểm tra kết nối rồi thử lại.');
      }
      return progress;
    });
    _notify();
  }
}
