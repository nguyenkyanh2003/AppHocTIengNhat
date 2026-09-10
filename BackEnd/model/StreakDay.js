import mongoose from 'mongoose';

/**
 * Một ngày trong lịch học của người dùng.
 *
 * Trước đây nằm trong mảng `activity_dates` của `UserStreak`, tức là tăng vô
 * hạn trong một document được đọc ở mọi lần xem streak. `status` phân biệt
 * ngày đã học với ngày được băng bảo vệ; ngày nghỉ đơn giản là không có bản
 * ghi — không cần lưu trạng thái "nghỉ" tường minh. Đây là nguồn dữ liệu của
 * màn lịch ở Phần B.
 */
const StreakDaySchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    day_key: { type: String, required: true },
    status: { type: String, enum: ['studied', 'frozen'], required: true },
  },
  { timestamps: true },
);

// Unique theo (user, day_key) chứ không chỉ index thường: đây là ràng buộc
// nghiệp vụ thật (mỗi ngày của một user chỉ có đúng một trạng thái), không
// phải chỉ để tăng tốc đọc. markDay dựa vào chính ràng buộc này để upsert an
// toàn khi gọi lại nhiều lần cho cùng một ngày.
StreakDaySchema.index({ user: 1, day_key: 1 }, { unique: true });

export default mongoose.model('StreakDay', StreakDaySchema);
