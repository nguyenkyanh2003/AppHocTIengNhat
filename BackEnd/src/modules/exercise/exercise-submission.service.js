import { ApiError } from '../../shared/http/api-error.js';
import { attemptSubmitter } from '../streaks/attempt-submission.js';
import { scoreExerciseAnswers } from './exercise-scoring.service.js';
import { exerciseSubmissionRepository } from './exercise-submission.repository.js';

/**
 * Nộp bài tập: chấm, lưu kết quả, ghi hoạt động học — tất cả trong một lượt
 * làm có định danh.
 *
 * XP do chính sách quyết từ **kết quả server chấm**, không từ cờ nào client
 * gửi lên. Bản cũ cộng XP ngay trong controller, trong một `try/catch` nuốt
 * lỗi, nên lỗi streak biến mất im lặng và bài nộp lại thì cộng XP lần nữa.
 */
export const createExerciseSubmissionService = ({
  repository = exerciseSubmissionRepository,
  submitter = attemptSubmitter,
  score = scoreExerciseAnswers,
  now = () => new Date(),
} = {}) => ({
  async submit({ userId, exerciseId, attemptId, answers, timeSpent }) {
    return submitter.submit({
      userId,
      type: 'exercise.submit',
      sourceId: exerciseId,
      attemptId,
      // Dấu vân tay chỉ gồm bài làm: thời gian làm bài có thể lệch giữa hai
      // lần gửi của **cùng** một lượt mà không làm nó thành bài khác.
      payload: { exerciseId: String(exerciseId), answers },
      persist: async ({ session }) => {
        const exercise = await repository.findExercise(exerciseId, { session });
        if (!exercise) throw ApiError.notFound('Không tìm thấy bài tập.');

        const questions = exercise.questions ?? [];
        if (questions.length === 0) throw ApiError.notFound('Bài tập này không có câu hỏi.');

        const scored = score({
          questions,
          answers,
          passScore: exercise.pass_score ?? 60,
        });

        const saved = await repository.createResult(
          {
            user_id: userId,
            exercise_id: exerciseId,
            score: scored.score,
            correct_count: scored.correctCount,
            total_questions: questions.length,
            time_spent: Number(timeSpent || 0),
            user_answers: scored.userAnswers,
            is_passed: scored.isPassed,
            completed_at: now(),
          },
          { session },
        );
        await repository.incrementAttempts(exerciseId, { session });

        return {
          result: {
            _id: saved._id,
            user_id: saved.user_id,
            exercise_id: saved.exercise_id,
            score: saved.score,
            correct_answers: scored.correctCount,
            total_questions: questions.length,
            time_spent: saved.time_spent,
            passed: scored.isPassed,
            answers: scored.userAnswers,
            createdAt: saved.createdAt ?? saved.completed_at,
          },
          outcome: { passed: scored.isPassed },
        };
      },
    });
  },
});

export const exerciseSubmissionService = createExerciseSubmissionService();

export default exerciseSubmissionService;
