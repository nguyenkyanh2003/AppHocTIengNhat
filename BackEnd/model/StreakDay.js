import mongoose from 'mongoose';

/**
 * Một ngày trong lịch học của người dùng.
 *
 * Trước đây nằm trong mảng `activity_dates` của `UserStreak`, tức là tăng vô
 * hạn trong một document được đọc ở mọi lần xem streak. Ngày nghỉ đơn giản là
 * không có bản ghi — không cần lưu trạng thái "nghỉ" tường minh. Đây là nguồn
 * dữ liệu của màn lịch ở Phần B, và là nguồn để đếm `total_active_days`.
 */
const StreakDaySchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    day_key: { type: String, required: true },

    /**
     * `studied` — có ít nhất một hoạt động học được ghi nhận trong ngày.
     * `frozen` — nghỉ nhưng được băng bảo vệ (Phần B; hiện chưa phát băng nào).
     * `legacy` — ngày dựng lại từ dữ liệu cũ, **không chứng minh được** là có
     * học thật (spec §3.2).
     *
     * Nhánh `legacy` tồn tại vì hai lựa chọn còn lại đều sai: gọi nó là
     * `studied` là bịa ra dữ liệu chưa bao giờ được xác minh, còn bỏ nó đi là
     * xoá trắng chuỗi mà người dùng đã tích luỹ thật. Giữ riêng một trạng thái
     * cho phép vừa hiển thị lịch đầy đủ vừa không tính nó vào số liệu mới.
     */
    status: { type: String, enum: ['studied', 'frozen', 'legacy'], required: true },

    /**
     * Nguồn của bản ghi, giữ **độc lập** với `status`.
     *
     * Một ngày legacy trùng với ngày có hoạt động mới sẽ được nâng `status`
     * lên `studied` nhưng vẫn giữ dấu `legacy_unverified` ở đây (spec §3.2) —
     * nhờ vậy migration biết được ngày đó đã từng được đếm ở baseline và
     * không cộng lại độ dài chuỗi lần thứ hai.
     */
    origin: {
      type: String,
      enum: ['activity', 'legacy_unverified'],
      default: 'activity',
      required: true,
    },

    /**
     * Các số đếm trong ngày, đều cộng dồn bằng `$inc`.
     *
     * Mặc định `0` chứ không để trống: `$inc` trên một field vắng mặt thì
     * Mongo tự coi là 0, nhưng một document cũ có field kiểu khác (hoặc code
     * đọc ra `undefined` rồi cộng trong JS) sẽ cho `NaN` — hỏng im lặng.
     *
     * `correct_self_reports`/`wrong_self_reports` mang chữ "self report" có
     * chủ đích: với SRS, "nhớ / chưa nhớ" là người học tự khai, server không
     * chấm được. Đặt tên đúng bản chất để sau này không ai đem nó đi tính tỷ
     * lệ đúng như thể đó là kết quả chấm.
     */
    direct_xp: { type: Number, default: 0 },
    review_count: { type: Number, default: 0 },
    correct_self_reports: { type: Number, default: 0 },
    wrong_self_reports: { type: Number, default: 0 },
  },
  { timestamps: true },
);

// Unique theo (user, day_key) chứ không chỉ index thường: đây là ràng buộc
// nghiệp vụ thật (mỗi ngày của một user chỉ có đúng một bản ghi), không phải
// chỉ để tăng tốc đọc. Đường ghi dựa vào chính ràng buộc này để upsert an toàn
// khi gọi lại nhiều lần cho cùng một ngày.
StreakDaySchema.index({ user: 1, day_key: 1 }, { unique: true });

export default mongoose.model('StreakDay', StreakDaySchema);
