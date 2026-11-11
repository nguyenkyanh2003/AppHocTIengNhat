import mongoose from 'mongoose';

/** Loại admin được chọn khi gửi tay. */
export const SENDABLE_NOTIFICATION_TYPES = ['SYSTEM', 'LESSON', 'EXAM'];

/**
 * Mọi loại có thể nằm trong DB. `ACHIEVEMENT` chỉ do server tạo khi cấp huy
 * hiệu (cùng transaction), admin không gửi được để không có huy hiệu giả.
 */
export const NOTIFICATION_TYPES = [...SENDABLE_NOTIFICATION_TYPES, 'ACHIEVEMENT'];

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

    // Admin đã gửi; `null` cho thông báo hệ thống tự tạo (vd. nhận huy hiệu).
    sender: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
}, { timestamps: true });

// Danh sách của một người, mới nhất trước.
NotificationSchema.index({ recipient: 1, createdAt: -1 });
// Bộ đếm chưa đọc và "đánh dấu tất cả đã đọc".
NotificationSchema.index({ recipient: 1, is_read: 1 });

export default mongoose.model('Notification', NotificationSchema);
