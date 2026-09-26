import { loadVideoKeyPhrases } from './lesson-video-phrases.js';
import { SITUATIONAL_LESSONS } from './situational-lessons.js';

/**
 * Bài tập mẫu dựng **tự động** từ bảng từ vựng của bộ bài chủ đề.
 *
 * Không có câu tiếng Nhật nào được soạn mới ở đây: đề và đáp án đều lấy nguyên
 * từ `situational-lessons.js`, nên bài tập đúng đến đâu là do bảng từ đó đúng
 * đến đó (bảng từ còn chờ người biết tiếng Nhật rà, xem đầu file đó).
 *
 * Mỗi bài học sinh ba bài tập trắc nghiệm 4 đáp án, theo ba dạng quen thuộc của
 * các app học tiếng Nhật: nghĩa của từ, cách đọc chữ Hán, và hiểu câu trong hội
 * thoại của bài. Bài có video lấy câu hội thoại từ các mẫu câu trong kịch bản
 * video (`data/lesson-videos/`); bài chưa có video dùng hội thoại soạn sẵn. Khớp model `Exercise` hiện tại (2–4 đáp án, một đáp án đúng).
 * Đáp án nhiễu lấy **trong cùng bài**, chọn theo vị trí chứ không `Math.random`,
 * để chạy lại seed luôn ra đúng cùng nội dung và upsert không báo khác nhau giả.
 *
 * Dữ liệu thuần, không chạm DB — `seed-exercises.js` lo phần ghi.
 */

const CHOICES = 4;

/**
 * Đáp án đúng cộng ba đáp án nhiễu khác chữ, đáp án đúng xoay vòng vị trí theo
 * câu để người học không đoán được bằng vị trí.
 */
export const buildChoices = (pool, index, pick) => {
  const correct = pick(pool[index]);
  const distractors = [];
  for (let step = 1; step < pool.length && distractors.length < CHOICES - 1; step += 1) {
    const candidate = pick(pool[(index + step) % pool.length]);
    if (candidate !== correct && !distractors.includes(candidate)) distractors.push(candidate);
  }
  if (distractors.length < CHOICES - 1) return null;

  const answers = distractors.map((content) => ({ content, is_correct: false }));
  answers.splice(index % CHOICES, 0, { content: correct, is_correct: true });
  return answers;
};

const meaningQuestions = (words) =>
  words
    .map((word, index) => {
      const answers = buildChoices(words, index, (w) => w.meaning);
      return (
        answers && {
          content: `「${word.word}」（${word.hiragana}）nghĩa là gì?`,
          answers,
          explanation: `${word.word}（${word.hiragana}）: ${word.meaning}`,
        }
      );
    })
    .filter(Boolean);

/** Từ viết toàn bằng kana thì "cách đọc" chính là mặt chữ — bỏ, không thành câu hỏi. */
const readingQuestions = (words) => {
  const withKanji = words.filter((word) => word.word !== word.hiragana);
  return withKanji
    .map((word, index) => {
      const answers = buildChoices(withKanji, index, (w) => w.hiragana);
      return (
        answers && {
          content: `Cách đọc của「${word.word}」là gì?`,
          answers,
          explanation: `${word.word} đọc là ${word.hiragana} — ${word.meaning}`,
        }
      );
    })
    .filter(Boolean);
};

/**
 * Mỗi câu thoại thành một câu hỏi; đáp án nhiễu là bản dịch của câu khác cùng
 * bài. Nhận cả lượt thoại soạn sẵn lẫn mẫu câu của video — cùng các trường
 * `speaker`, `text_ja`, `reading` (có thể thiếu), `text_vi`.
 */
const dialogueQuestions = (turns) =>
  turns
    .map((turn, index) => {
      const answers = buildChoices(turns, index, (t) => t.text_vi);
      const speaker = turn.speaker ? `${turn.speaker}:` : '';
      const reading = turn.reading ? `（${turn.reading}）` : '';
      return (
        answers && {
          content: `${speaker}「${turn.text_ja}」có nghĩa là gì?`,
          answers,
          explanation: `${turn.text_ja}${reading}— ${turn.text_vi}`,
        }
      );
    })
    .filter(Boolean);

const topicOf = (lesson) => lesson.title.replace(/^Tình huống:\s*/, '');

/**
 * Bài tập của một bài học, chưa có `lesson_id` — runner gắn sau khi tra bài
 * theo `title`. Bài không đủ từ để dựng câu 4 đáp án thì không sinh bài tập.
 *
 * `videoPhrases` là mẫu câu trong kịch bản video của bài; dùng khi bài không
 * có hội thoại soạn sẵn. Tiêu đề bài tập giữ nguyên dù đổi nguồn câu hỏi, để
 * bài tập đã có giữ `_id` và kết quả làm bài cũ vẫn trỏ đúng.
 */
export const exercisesForLesson = (lesson, videoPhrases = []) => {
  const fromVideo = !(lesson.dialogue?.length > 0);
  return [
    {
      title: `Nghĩa của từ — ${topicOf(lesson)}`,
      description: `Chọn nghĩa đúng của các từ trong bài "${topicOf(lesson)}".`,
      questions: meaningQuestions(lesson.vocabularies),
    },
    {
      title: `Cách đọc — ${topicOf(lesson)}`,
      description: `Chọn cách đọc đúng của các từ có chữ Hán trong bài "${topicOf(lesson)}".`,
      questions: readingQuestions(lesson.vocabularies),
    },
    {
      title: `Hội thoại — ${topicOf(lesson)}`,
      type: 'Tổng hợp',
      description: fromVideo
        ? `Hiểu các mẫu câu trong video của bài "${topicOf(lesson)}".`
        : `Hiểu từng câu trong đoạn hội thoại của bài "${topicOf(lesson)}".`,
      questions: dialogueQuestions(fromVideo ? videoPhrases : lesson.dialogue),
    },
  ]
    .filter((exercise) => exercise.questions.length > 0)
    .map((exercise) => ({
      type: 'Từ vựng',
      ...exercise,
      level: lesson.level,
      time_limit: 0,
      pass_score: 60,
      is_active: true,
    }));
};

const VIDEO_PHRASES = loadVideoKeyPhrases();

/** Toàn bộ bài tập mẫu, kèm tiêu đề bài học để runner tra `lesson_id`. */
export const SAMPLE_EXERCISES = SITUATIONAL_LESSONS.flatMap((lesson) =>
  exercisesForLesson(lesson, VIDEO_PHRASES.get(lesson.title)).map((exercise) => ({
    lessonTitle: lesson.title,
    exercise,
  })),
);
