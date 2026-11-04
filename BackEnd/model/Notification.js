import mongoose from 'mongoose';

export const NOTIFICATION_TYPES = ['SYSTEM', 'LESSON', 'EXAM'];

/**
 * Thông báo cá nhân: mỗi bản ghi thuộc đúng một người nhận, nên trạng thái đọc
 * và việc xoá của mỗi người độc lập. Gửi cho tất cả là tạo một bản ghi cho mỗi
 * người (phase-2-plan A7).
 */
const NotificationSchema = new mongoose.Schema({
    recipient: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    title: { type: String, required: true, trim: true },
    message: { type: String, required: true, trim: true },
    type: { type: String, enum: NOTIFICATION_TYPES, default: 'SYSTEM' },
    data: { type: Object, default: {} },

    is_read: { type: Boolean, default: false },
    read_at: { type: Date, default: null },

    // Admin đã gửi; `null` dành cho thông báo hệ thống tự tạo (đợt sau).
    sender: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
}, { timestamps: true });

// Danh sách của một người, mới nhất trước.
NotificationSchema.index({ recipient: 1, createdAt: -1 });
// Bộ đếm chưa đọc và "đánh dấu tất cả đã đọc".
NotificationSchema.index({ recipient: 1, is_read: 1 });

export default mongoose.model('Notification', NotificationSchema);
