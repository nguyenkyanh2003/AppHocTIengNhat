import mongoose from 'mongoose';

export const GOAL_TYPES = ['lessons', 'vocabulary', 'kanji'];

/** Ngày theo lịch người học chọn, không kèm giờ — tránh lệch ngày giữa các múi giờ. */
export const DATE_KEY = /^\d{4}-\d{2}-\d{2}$/;

/**
 * Mục tiêu học tập tích luỹ của một tài khoản: "đạt tổng cộng N bài / từ /
 * chữ Kanji đã học". Tiến độ không lưu ở đây — server đếm từ bộ đếm chung của
 * dashboard mỗi lần đọc; chỉ lưu thời điểm **lần đầu** đạt (phase-2-plan A8).
 */
const LearningGoalSchema = new mongoose.Schema({
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    type: { type: String, enum: GOAL_TYPES, required: true },
    title: { type: String, required: true, trim: true },
    target: { type: Number, required: true, min: 1 },
    deadline: { type: String, match: DATE_KEY, default: null },
    completed_at: { type: Date, default: null },
}, { timestamps: true });

LearningGoalSchema.index({ user: 1, createdAt: -1 });

export default mongoose.model('LearningGoal', LearningGoalSchema);
