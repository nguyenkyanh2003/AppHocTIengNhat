import mongoose from 'mongoose';

/**
 * Nhật ký mọi hoạt động học **đã được server chấp nhận**, kể cả event 0 XP.
 *
 * Thay cho hai thứ cũ cùng lúc:
 *
 * - `UserStreak.xp_history` — mảng tăng vô hạn bên trong một document được đọc
 *   ở mọi lần xem streak.
 * - `UserStreak.reward_keys` — mảng khoá chống trùng, cũng tăng vô hạn, và chỉ
 *   bảo vệ được những loại hoạt động "một lần"; loại lặp lại (ôn thẻ) không có
 *   cơ chế chống trùng nào.
 *
 * Thiết kế mới gộp hai vai trò đó vào chính bản ghi event: **lần insert này có
 * thành công hay không chính là câu trả lời cho "đã ghi rồi hay chưa"**, nhờ
 * unique index `(user, event_key)`. Không còn đường nào đọc một mảng rồi quyết
 * định, tức là không còn khe hở giữa lúc đọc và lúc ghi.
 *
 * Lịch sử XP là một **cách đọc** collection này (lọc `xp_delta != 0`), không
 * phải một collection riêng chứa dữ liệu trùng (spec §3.2).
 */
const ActivityEventSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },

    /**
     * Định danh ổn định của **lần xảy ra**, do service nghiệp vụ dựng
     * (spec §3.3): `lesson-item:<lesson>:<type>:<item>`,
     * `lesson-complete:<lesson>`, `srs:<progressId>:<expected_next_review>`,
     * `exercise:<attemptId>`... Không phải `type:sourceId` — một thẻ SRS được
     * ôn nhiều lần trong đời nó, nên ID thẻ một mình không định danh được lượt.
     */
    event_key: { type: String, required: true, trim: true },

    type: { type: String, required: true, trim: true },
    source_id: { type: String, trim: true },

    occurred_at: { type: Date, required: true },

    /** Khoá ngày `YYYY-MM-DD` giờ Việt Nam tại lúc ghi (xem `streak-rules.js`). */
    day_key: { type: String, required: true },

    /**
     * XP do `streak-policy.js` quyết. Mặc định 0 chứ không để trống: trường
     * này được cộng dồn (`$inc`, `$sum`), và một `undefined` lọt vào phép cộng
     * sẽ biến tổng XP thành `NaN` — hỏng im lặng, khó lần ngược.
     */
    xp_delta: { type: Number, default: 0 },

    reason: { type: String, trim: true },

    /**
     * Event này có làm hôm nay thành ngày học không. Event thưởng mốc là
     * `false`: nhận huy hiệu không phải là học (spec §3.4).
     */
    counts_as_study: { type: Boolean, default: false },

    /** Phiên bản bảng XP đã dùng — cần để đọc lại lịch sử cho đúng ngữ cảnh. */
    policy_version: { type: String, required: true },

    /**
     * Ảnh chụp nhỏ của phản hồi đã trả cho lần nộp này, chỉ dùng cho retry
     * (spec §3.3).
     *
     * JLPT hiện ghi đè một `LearningHistory` theo (user, exam), nên khi người
     * học nộp lần B rồi retry lần A, đọc lại từ history sẽ trả điểm của lần B.
     * Giữ phản hồi ngay tại event khiến mỗi `attempt_id` đọc lại đúng kết quả
     * của chính nó. `Mixed` vì mỗi loại bài có hình dạng phản hồi khác nhau và
     * trường này không bao giờ bị query theo nội dung bên trong.
     */
    receipt: { type: mongoose.Schema.Types.Mixed },
  },
  { timestamps: true },
);

// Ràng buộc chống trùng — và là **toàn bộ** cơ chế chống trùng của đường ghi
// mới. Không TTL: khoá này đang giữ lời hứa "không phát thưởng lại", nên cho
// nó hết hạn nghĩa là mở lại đúng lỗ hổng nó vá (spec §3.2).
ActivityEventSchema.index({ user: 1, event_key: 1 }, { unique: true });

// Truy vấn lịch sử: "event của user này, mới nhất trước", phân trang bằng
// cursor `(occurred_at, _id)` chứ không `skip`. `_id` phải nằm trong index vì
// nó là khoá phá hoà của cursor — hai event ghi trong cùng một transaction có
// `occurred_at` bằng nhau, và nếu thứ tự giữa chúng không ổn định thì trang
// sau sẽ lặp hoặc bỏ sót bản ghi.
ActivityEventSchema.index({ user: 1, occurred_at: -1, _id: -1 });

export default mongoose.model('ActivityEvent', ActivityEventSchema);
