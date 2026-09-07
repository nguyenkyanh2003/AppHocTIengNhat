/**
 * Lịch ôn tập Leitner, khớp với `model/SRSProgress.js` (box 1..5).
 *
 * Đây là các hàm thuần: không chạm DB, không chạm req/res, nên unit test được
 * trực tiếp. Mọi nơi cần lên lịch ôn tập phải dùng các hàm này thay vì tự tính.
 */
export const MIN_BOX = 1;
export const MAX_BOX = 5;

/** Số ngày chờ trước lần ôn tiếp theo, theo box hiện tại. */
export const BOX_INTERVAL_IN_DAYS = Object.freeze({
  1: 1,
  2: 3,
  3: 7,
  4: 14,
  5: 30,
});

const DAY_IN_MS = 24 * 60 * 60 * 1000;

const clampBox = (box) => {
  const value = Number.isFinite(box) ? Math.trunc(box) : MIN_BOX;
  return Math.min(Math.max(value, MIN_BOX), MAX_BOX);
};

/** Trả lời đúng thì lên một box (tối đa 5); sai thì quay về box 1. */
export const nextBox = (box, isCorrect) =>
  isCorrect ? clampBox(clampBox(box) + 1) : MIN_BOX;

/** Ngày ôn tiếp theo tính từ box mới. */
export const nextReviewDate = (box, now = new Date()) =>
  new Date(now.getTime() + BOX_INTERVAL_IN_DAYS[clampBox(box)] * DAY_IN_MS);

/** Chuỗi trả lời đúng liên tiếp; sai thì reset về 0. */
export const nextStreak = (streak, isCorrect) =>
  isCorrect ? Math.max(0, Math.trunc(streak ?? 0)) + 1 : 0;

/** Trạng thái ban đầu khi một item được đánh dấu đã học. */
export const initialProgress = (now = new Date()) => ({
  box: MIN_BOX,
  next_review: nextReviewDate(MIN_BOX, now),
  streak: 0,
});

/** Áp một lần trả lời lên tiến độ hiện tại. */
export const applyAnswer = (progress, isCorrect, now = new Date()) => {
  const box = nextBox(progress?.box ?? MIN_BOX, isCorrect);
  return {
    box,
    next_review: nextReviewDate(box, now),
    streak: nextStreak(progress?.streak, isCorrect),
  };
};

export const isDue = (progress, now = new Date()) =>
  !!progress?.next_review && new Date(progress.next_review) <= now;
