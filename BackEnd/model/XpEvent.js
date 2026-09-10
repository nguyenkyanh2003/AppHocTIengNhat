import mongoose from 'mongoose';

/**
 * Một lần cộng XP.
 *
 * Trước đây nằm trong mảng `xp_history` của `UserStreak`, tức là tăng vô hạn
 * trong một document được đọc ở mọi lần xem streak. Tách ra collection riêng
 * để đọc streak không còn kéo theo toàn bộ lịch sử XP, và để có nguồn dữ liệu
 * phân trang được cho màn lịch sử XP.
 */
const XpEventSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    amount: { type: Number, required: true },
    reason: { type: String, trim: true },
    type: { type: String, trim: true },
    source_id: { type: String, trim: true },
    earned_at: { type: Date, default: Date.now },
  },
  { timestamps: true },
);

// Truy vấn chính là "lịch sử XP của một user, mới nhất trước" (listXpEvents) —
// index ghép theo đúng thứ tự lọc rồi sort để Mongo không phải quét rồi sắp
// riêng.
XpEventSchema.index({ user: 1, earned_at: -1 });

export default mongoose.model('XpEvent', XpEventSchema);
