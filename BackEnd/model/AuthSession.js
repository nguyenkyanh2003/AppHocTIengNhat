import mongoose from 'mongoose';

export const SESSION_REVOKE_REASONS = ['logout', 'password_changed', 'reuse_detected', 'account_inactive'];

/**
 * Một phiên đăng nhập trên một thiết bị.
 *
 * Chỉ lưu **bản băm SHA-256** của refresh token: lộ database không lộ token
 * dùng được. Mỗi lần làm mới, token đổi sang token mới và bản băm cũ chuyển
 * sang `previous_token_hash`. Trình lại token cũ đó ngay sau lúc thay
 * (`previous_retired_at`) là client mất phản hồi và đang thử lại; trình lại sau
 * đó là token bị đánh cắp, và cả phiên bị thu hồi.
 *
 * `superseded_token_hash`: token bị thay vì một lần thử lại như trên. Nó mà
 * xuất hiện thì có hai bên cùng giữ phiên — cũng thu hồi cả phiên.
 *
 * `rotation`: số lần đã thay token, đi kèm trong access token. Trên web các tab
 * dùng chung kho lưu và có thể cùng làm mới; phản hồi về ngược thứ tự thì số này
 * cho biết cặp token nào mới hơn, vì cùng `sid` không phân biệt được.
 */
const AuthSessionSchema = new mongoose.Schema({
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    refresh_token_hash: { type: String, required: true, unique: true },
    previous_token_hash: { type: String, default: null, index: true },
    previous_retired_at: { type: Date, default: null },
    superseded_token_hash: { type: String, default: null, index: true },
    rotation: { type: Number, default: 0 },
    expires_at: { type: Date, required: true },
    last_used_at: { type: Date, default: null },
    revoked_at: { type: Date, default: null },
    revoked_reason: { type: String, enum: [...SESSION_REVOKE_REASONS, null], default: null },
}, { timestamps: true });

// MongoDB tự xoá phiên đã hết hạn — kể cả phiên đã thu hồi, vốn chỉ cần giữ tới
// lúc đó để còn nhận ra token cũ bị dùng lại.
AuthSessionSchema.index({ expires_at: 1 }, { expireAfterSeconds: 0 });

export default mongoose.model('AuthSession', AuthSessionSchema);
