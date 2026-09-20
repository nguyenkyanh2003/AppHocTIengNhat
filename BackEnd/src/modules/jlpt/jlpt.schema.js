import { z } from 'zod';

const objectId = z.string().regex(/^[0-9a-fA-F]{24}$/, 'Định danh không hợp lệ.');

export const submitParams = z.object({ id: objectId });

const answers = z.array(z.unknown()).min(1, 'Dữ liệu bài làm không hợp lệ.');
const seconds = z.coerce.number().int().min(0);

/**
 * Bài nộp của một lượt thi.
 *
 * Ba tên cho mảng bài làm và ba tên cho thời gian là di sản của client cũ; giữ
 * cả sáu để không phải đổi app trong cùng một đợt, nhưng `attempt_id` thì bắt
 * buộc — không có nó thì không phân biệt được "gửi lại" với "thi lại".
 */
export const submitBody = z
  .object({
    attempt_id: z.uuid('Lượt thi phải có định danh dạng UUID.'),
    userAnswers: answers.optional(),
    answers: answers.optional(),
    user_answers: answers.optional(),
    thoiGianLamBai: seconds.optional(),
    ThoiGianLamBai: seconds.optional(),
    time_spent: seconds.optional(),
  })
  .loose()
  .refine(
    (body) => Boolean(body.userAnswers ?? body.answers ?? body.user_answers),
    { message: 'Dữ liệu bài làm không hợp lệ.', path: ['answers'] },
  );

/** Mảng bài làm và thời gian, đã gộp về một tên. */
export const submissionOf = (body) => ({
  answers: body.userAnswers ?? body.answers ?? body.user_answers,
  timeSpent: body.thoiGianLamBai ?? body.ThoiGianLamBai ?? body.time_spent,
});
