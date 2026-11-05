import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/state/view_state.dart';
import '../models/jlpt_practice_question.dart';
import '../services/jlpt_service.dart';

/// Một bộ câu luyện nhanh. Chấm ngay trên máy và không lưu lên server: đây là ôn
/// nhanh, không phải một lượt thi.
class JLPTPracticeProvider with ChangeNotifier {
  JLPTPracticeProvider({JLPTService? service})
      : _service = service ?? JLPTService();

  final JLPTService _service;

  bool _loading = false;
  String? _error;
  List<JlptPracticeQuestion> _items = const [];
  final Map<int, int> _answers = {};

  bool get isLoading => _loading;
  String? get error => _error;
  List<JlptPracticeQuestion> get items => _items;

  int? answerOf(int index) => _answers[index];
  int get answeredCount => _answers.length;
  int get correctCount => _answers.entries
      .where((entry) => _items[entry.key].correctAnswer == entry.value)
      .length;

  Future<void> loadPractice({
    required String type,
    String? level,
    int limit = 10,
  }) async {
    _loading = true;
    _error = null;
    _items = const [];
    _answers.clear();
    notifyListeners();
    try {
      final data =
          await _service.fetchPractice(type: type, level: level, limit: limit);
      _items = data
          .map((item) => JlptPracticeQuestion.fromJson(
              Map<String, dynamic>.from(item as Map)))
          .toList();
    } on NotFoundException {
      // Server trả 404 khi không có câu nào phù hợp: đó là danh sách rỗng, không phải lỗi.
      _items = const [];
    } catch (e) {
      _error = userMessageOf(e);
      debugPrint('Error load practice: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Ghi câu trả lời. Đã trả lời thì không đổi được, vì đáp án đã hiện ra.
  void answer(int index, int choice) {
    if (_answers.containsKey(index)) return;
    _answers[index] = choice;
    notifyListeners();
  }
}
