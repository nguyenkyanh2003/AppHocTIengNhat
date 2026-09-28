import 'lesson.dart';
import 'lesson_video.dart';

/// Loại của một bước trong phiên học bài.
enum StudyStepKind { intro, video, dialogue, vocabulary, kanji, grammar, quiz, finish }

/// Một bước của phiên học: mỗi bước chỉ làm một việc, để bài học được chia
/// thành những phần nhỏ vừa sức thay vì một trang dài.
class StudyStep {
  const StudyStep(this.kind, this.title, {this.videoIndex});

  final StudyStepKind kind;
  final String title;

  /// Chỉ có ở bước video: vị trí video trong `lesson.videos`.
  final int? videoIndex;
}

/// Số câu tối thiểu để có một bài kiểm tra nhanh 4 đáp án có nghĩa.
const quickQuizMinWords = 4;

/// Lộ trình học của một bài, chỉ gồm những phần bài thật sự có nội dung.
///
/// Thứ tự đi từ tiếp nhận tới tự kiểm tra: xem tình huống diễn ra thế nào,
/// đọc lại lời thoại, học từng từ, rồi tự kiểm tra — giống cách các app học
/// ngôn ngữ dẫn một bài.
List<StudyStep> buildStudySteps(LessonDetail detail) {
  final lesson = detail.lesson;
  final videos = lesson.videos;
  return [
    const StudyStep(StudyStepKind.intro, 'Mở đầu'),
    for (var index = 0; index < videos.length; index++)
      StudyStep(StudyStepKind.video, _videoStepTitle(videos, index), videoIndex: index),
    if (lesson.hasDialogue) const StudyStep(StudyStepKind.dialogue, 'Hội thoại'),
    if (detail.words.isNotEmpty) const StudyStep(StudyStepKind.vocabulary, 'Từ vựng'),
    if (detail.kanjis.isNotEmpty) const StudyStep(StudyStepKind.kanji, 'Chữ Hán'),
    if (detail.grammars.isNotEmpty) const StudyStep(StudyStepKind.grammar, 'Ngữ pháp'),
    if (detail.words.length >= quickQuizMinWords) const StudyStep(StudyStepKind.quiz, 'Kiểm tra nhanh'),
    const StudyStep(StudyStepKind.finish, 'Hoàn thành'),
  ];
}

/// Cảnh tình huống đánh số "Cảnh N"; video ôn tập mang đúng tên của nó.
String _videoStepTitle(List<LessonVideo> videos, int index) {
  if (videos.length == 1) return 'Xem tình huống';
  final number = sceneNumber(videos, index);
  final title = videos[index].title;
  return number == null ? title : 'Cảnh $number: $title';
}

/// Ước lượng số phút của một bài, để người học biết trước mình cần bao lâu.
int estimateStudyMinutes(LessonDetail detail) => _estimateMinutes(
      lesson: detail.lesson,
      words: detail.words.length,
      kanjisAndGrammars: detail.kanjis.length + detail.grammars.length,
    );

/// Cùng ước lượng, tính từ bản tóm tắt của danh sách bài (Trang chủ chưa tải
/// chi tiết bài): đếm theo mã từ / kanji / ngữ pháp gắn với bài.
int estimateLessonMinutes(Lesson lesson) => _estimateMinutes(
      lesson: lesson,
      words: lesson.vocabularies.length,
      kanjisAndGrammars: lesson.kanjis.length + lesson.grammars.length,
    );

int _estimateMinutes({required Lesson lesson, required int words, required int kanjisAndGrammars}) {
  // Video có thời lượng thật thì dùng, video cũ chưa có thì ước 90 giây.
  final videoSeconds = lesson.videos.fold<int>(0, (sum, video) => sum + (video.duration?.inSeconds ?? 90));
  final seconds = videoSeconds +
      lesson.dialogue.length * 20 +
      words * 25 +
      kanjisAndGrammars * 60 +
      (words >= quickQuizMinWords ? 90 : 0);
  return (seconds / 60).ceil().clamp(1, 120);
}
