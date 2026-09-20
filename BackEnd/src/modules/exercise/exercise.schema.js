import { z } from 'zod';

const objectId = z.string().regex(/^[0-9a-fA-F]{24}$/, 'Định danh không hợp lệ.');

export const submitParams = z.object({ id: objectId });

/**
 * Bài nộp của một lượt làm.
 *
 * `attempt_id` do client sinh khi **bắt đầu** lượt làm và gửi lại đúng ID đó
 * khi thử lại (spec §3.3). Bắt buộc ở đây thay vì tự sinh trên server: chỉ
 * client mới biết hai request là một lượt hay hai lượt khác nhau.
 */
export const submitBody = z.object({
  attempt_id: z.uuid('Lượt làm phải có định danh dạng UUID.'),
  answers: z
    .array(
      z
        .object({
          question_id: z.string().min(1),
          answer_id: z.string().min(1),
        })
        .loose(),
    )
    .min(1, 'Bài làm không được rỗng.'),
  timeSpent: z.coerce.number().int().min(0).optional(),
});
