import { ApiError } from '../../shared/http/api-error.js';
import { toSkip } from '../../shared/http/pagination.js';
import { exerciseRepository } from './exercise.repository.js';

/**
 * Danh sách chỉ đếm câu hỏi: mảng `questions` chứa `answers[].is_correct` và
 * `explanation`, tức là đáp án của bài.
 */
const toListItem = ({ questions, ...exercise }) => ({ ...exercise, question_count: questions?.length ?? 0 });

/** Đề để làm bài: bỏ đáp án đúng và lời giải, người học chưa nộp. */
const withoutAnswers = ({ _id, content, answers = [] }) => ({
  _id,
  content,
  answers: answers.map((answer) => ({ _id: answer._id, content: answer.content })),
});

/**
 * Kết quả đã lưu đổi sang đúng hình dạng mà lần nộp bài trả về
 * (`exercise-submission.service.js`), để client chỉ phải đọc một kiểu.
 * Bài tập populate sẵn nằm ở `exercise`; bài đã bị xoá thì cả hai là `null`.
 */
const toResultDto = (doc) => ({
  _id: doc._id,
  exercise_id: doc.exercise_id?._id ?? null,
  exercise: doc.exercise_id ?? null,
  score: doc.score,
  correct_answers: doc.correct_count,
  total_questions: doc.total_questions,
  time_spent: doc.time_spent,
  passed: doc.is_passed,
  answers: doc.user_answers,
  createdAt: doc.createdAt ?? doc.completed_at,
});

export const createExerciseService = ({ repository = exerciseRepository } = {}) => ({
  async listByLevel(level) {
    return (await repository.findActive({ level })).map(toListItem);
  },

  async listByLesson(lessonId) {
    return (await repository.findActive({ lesson_id: lessonId })).map(toListItem);
  },

  async detail(id) {
    const exercise = await repository.findActiveById(id);
    if (!exercise) throw ApiError.notFound('Không tìm thấy bài tập.');
    return { ...exercise, questions: (exercise.questions ?? []).map(withoutAnswers) };
  },

  async history({ userId, page, limit }) {
    const [items, total] = await Promise.all([
      repository.findHistoryPage({ userId, skip: toSkip({ page, limit }), limit }),
      repository.countHistory(userId),
    ]);
    return { items: items.map(toResultDto), total, page, limit };
  },

  /** Đã nộp nên đề kèm đáp án đúng và lời giải để xem lại. */
  async result({ userId, id }) {
    const result = await repository.findResult({ id, userId });
    if (!result) throw ApiError.notFound('Không tìm thấy kết quả.');
    return toResultDto(result);
  },
});

export const exerciseService = createExerciseService();
