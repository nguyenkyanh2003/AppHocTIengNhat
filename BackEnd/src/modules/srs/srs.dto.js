/**
 * Tiến độ SRS như client thấy (spec SRS §3.3): đúng sáu trường, ngày ISO UTC.
 *
 * Dùng chung cho các route SRS và chi tiết từ vựng, để hai nơi không trả hai
 * hình dạng khác nhau cho cùng một thẻ.
 */
export const toSrsProgressDto = (progress) => ({
  _id: String(progress._id),
  item_id: String(progress.item_id),
  item_type: progress.item_type,
  box: progress.box,
  next_review: new Date(progress.next_review).toISOString(),
  streak: progress.streak ?? 0,
});
