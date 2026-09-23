import '../../vocabulary/models/vocabulary.dart';

/// Một câu kiểm tra nhanh: nhìn từ, chọn nghĩa đúng trong bốn đáp án.
class QuizQuestion {
  const QuizQuestion({
    required this.word,
    required this.choices,
    required this.correctIndex,
  });

  final Vocabulary word;
  final List<String> choices;
  final int correctIndex;

  bool isCorrect(int choice) => choice == correctIndex;
}

/// Bài kiểm tra nhanh cuối bài từ chính những từ vừa học.
///
/// Đáp án nhiễu là nghĩa của từ khác **trong cùng bài** và được chọn theo vị
/// trí, không ngẫu nhiên: học lại bài thì vẫn là bộ câu đó, và kết quả kiểm
/// thử không phụ thuộc vận may. Vị trí đáp án đúng xoay vòng theo câu để
/// không đoán được bằng vị trí.
List<QuizQuestion> buildQuickQuiz(List<Vocabulary> words, {int size = 5}) {
  final pool = words.where((word) => word.meaning.trim().isNotEmpty).toList();
  if (pool.length < 4) return const [];

  final count = size < pool.length ? size : pool.length;
  // Rải câu hỏi đều trên cả bài thay vì chỉ lấy mấy từ đầu.
  final stride = pool.length / count;
  final questions = <QuizQuestion>[];

  for (var q = 0; q < count; q++) {
    final index = (q * stride).floor();
    final correct = pool[index].meaning;
    final distractors = <String>[];
    for (var step = 1; step < pool.length && distractors.length < 3; step++) {
      final candidate = pool[(index + step) % pool.length].meaning;
      if (candidate != correct && !distractors.contains(candidate)) distractors.add(candidate);
    }
    if (distractors.length < 3) continue;

    final correctIndex = q % 4;
    final choices = [...distractors]..insert(correctIndex, correct);
    questions.add(QuizQuestion(word: pool[index], choices: choices, correctIndex: correctIndex));
  }
  return questions;
}
