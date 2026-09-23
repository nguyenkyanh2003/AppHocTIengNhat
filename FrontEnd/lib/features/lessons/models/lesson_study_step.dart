import 'lesson.dart';

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
      StudyStep(
        StudyStepKind.video,
        videos.length == 1 ? 'Xem tình huống' : 'Cảnh ${index + 1}: ${videos[index].title}',
        videoIndex: index,
      ),
    if (lesson.isSituational) const StudyStep(StudyStepKind.dialogue, 'Hội thoại'),
    if (detail.words.isNotEmpty) const StudyStep(StudyStepKind.vocabulary, 'Từ vựng'),
    if (detail.kanjis.isNotEmpty) const StudyStep(StudyStepKind.kanji, 'Chữ Hán'),
    if (detail.grammars.isNotEmpty) const StudyStep(StudyStepKind.grammar, 'Ngữ pháp'),
    if (detail.words.length >= quickQuizMinWords) const StudyStep(StudyStepKind.quiz, 'Kiểm tra nhanh'),
    const StudyStep(StudyStepKind.finish, 'Hoàn thành'),
  ];
}

/// Ước lượng số phút của một bài, để người học biết trước mình cần bao lâu.
int estimateStudyMinutes(LessonDetail detail) {
  final lesson = detail.lesson;
  final seconds = lesson.videos.length * 90 +
      lesson.dialogue.length * 20 +
      detail.words.length * 25 +
      (detail.kanjis.length + detail.grammars.length) * 60 +
      (detail.words.length >= quickQuizMinWords ? 90 : 0);
  return (seconds / 60).ceil().clamp(1, 120);
}
