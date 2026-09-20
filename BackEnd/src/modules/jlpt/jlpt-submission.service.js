import mongoose from 'mongoose';

import { ApiError } from '../../shared/http/api-error.js';
import { attemptSubmitter } from '../streaks/attempt-submission.js';
import { scoreExamAnswers } from './jlpt-scoring.service.js';
import { jlptSubmissionRepository } from './jlpt-submission.repository.js';

/**
 * Nộp đề JLPT: chấm, lưu kết quả gần nhất, ghi hoạt động học — trong một lượt
 * thi có định danh.
 *
 * Bản cũ không cộng XP cho việc thi (chỉ `upsert` một document streak rỗng với
 * trường `xp` không có trong schema), nên thi xong không được ghi nhận gì.
 */

/**
 * ID câu hỏi trong bài làm có thể thiếu hoặc không phải ObjectId (câu nằm
 * trong nhóm đọc/nghe không có ID riêng). Sinh ID mới cho những câu đó để bản
 * ghi lịch sử vẫn hợp lệ, đúng như hành vi cũ.
 */
const toQuestionId = (questionId) => {
  if (questionId && mongoose.Types.ObjectId.isValid(questionId)) {
    return new mongoose.Types.ObjectId(String(questionId));
  }
  return new mongoose.Types.ObjectId();
};

export const createJlptSubmissionService = ({
  repository = jlptSubmissionRepository,
  submitter = attemptSubmitter,
  score = scoreExamAnswers,
  now = () => new Date(),
} = {}) => ({
  async submit({ userId, examId, attemptId, answers, timeSpent }) {
    return submitter.submit({
      userId,
      type: 'jlpt.submit',
      sourceId: examId,
      attemptId,
      payload: { examId: String(examId), answers },
      persist: async ({ session }) => {
        const exam = await repository.findExam(examId, { session });
        if (!exam || !exam.is_published || !exam.is_active) {
          throw ApiError.notFound('Đề thi không tồn tại.');
        }

        const scored = score({ sections: exam.sections, rawAnswers: answers });
        const isPassed = scored.totalScore >= exam.pass_score;
        const duration = timeSpent ?? exam.time_limit * 60;

        await repository.saveHistory(
          {
            userId,
            examId,
            patch: {
              score: scored.totalScore,
              is_passed: isPassed,
              duration,
              section_scores: {
                moji_goi: scored.sectionScores.moji_goi,
                bunpou: scored.sectionScores.bunpou,
                dokkai: scored.sectionScores.dokkai,
                choukai: scored.sectionScores.choukai,
              },
              user_answers: scored.answerDetails.map((detail) => ({
                question_id: toQuestionId(detail.questionId),
                user_choice: detail.userChoice,
                is_correct: detail.isCorrect,
                section: detail.section,
                question_index: detail.questionIndex,
                group_index: detail.groupIndex,
              })),
              taken_at: now(),
            },
          },
          { session },
        );

        return {
          // Giữ nguyên vỏ response tiếng Việt mà client đang đọc.
          result: {
            KetQuaCuoiCung: isPassed ? 'Đỗ' : 'Trượt',
            DiemTuVung: scored.sectionScores.moji_goi,
            DiemNguPhap: scored.sectionScores.bunpou,
            DiemDocHieu: scored.sectionScores.dokkai,
            DiemNgheHieu: scored.sectionScores.choukai,
            TongDiemDatDuoc: scored.totalScore,
            TongThoiGian: duration,
          },
          outcome: { passed: isPassed },
        };
      },
    });
  },
});

export const jlptSubmissionService = createJlptSubmissionService();

export default jlptSubmissionService;
