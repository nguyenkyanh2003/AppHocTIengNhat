import StreakDay from '../../../model/StreakDay.js';
import UserStreak from '../../../model/UserStreak.js';
import XpEvent from '../../../model/XpEvent.js';

/**
 * Truy cập dữ liệu streak, XP và lịch học.
 *
 * `casUpdate` là điểm mấu chốt: nó chỉ ghi khi `last_activity_day` trong DB vẫn
 * đúng bằng giá trị vừa đọc (compare-and-swap qua điều kiện filter, không cần
 * lock riêng). Nhờ vậy hai request đồng thời (hai thiết bị, một lần gửi lại
 * sau timeout) không thể cùng tiêu băng hoặc cùng tăng chuỗi — request thua sẽ
 * nhận về `null` và tầng service tự đọc lại trạng thái mới nhất thay vì ghi đè.
 *
 * `UserStreak`, `XpEvent`, `StreakDay` nhận qua tham số (mặc định về model
 * thật) để test thay bằng model giả, không cần MongoDB — cùng khuôn với
 * `srs.repository.js`.
 */
export const createStreakRepository = ({
  UserStreak: streakModel = UserStreak,
  XpEvent: xpModel = XpEvent,
  StreakDay: dayModel = StreakDay,
} = {}) => ({
  /** Đọc streak hiện tại của một user, không tiêu băng, không ghi gì. */
  findByUser({ userId, session }) {
    return streakModel.findOne({ user: userId }).session(session).lean();
  },

  /**
   * Ghi có điều kiện, nguyên tử trên **cả hai** ràng buộc cùng lúc — ngày
   * chưa đổi VÀ (nếu là hoạt động one-shot) hoạt động này chưa được thưởng —
   * trong đúng một `findOneAndUpdate`.
   *
   * Vòng sửa 1 (review Task 4): bản trước chỉ khoá theo `last_activity_day`
   * và ghi `total_xp`/`reward_keys` bằng `$set` giá trị tuyệt đối do service
   * tính từ một lần đọc trước đó. Vỡ khi hai hoạt động one-shot khác nhau
   * (vd `lesson.complete:l1` và `exercise.submit:e1`) về gần như đồng thời
   * trong cùng một ngày: hoạt động "lặp trong ngày" không đổi
   * `last_activity_day`, nên filter CAS cũ khớp cho **cả hai** request bất
   * kể ai ghi trước — và bản ghi sau, vì tính `total_xp`/`reward_keys` từ
   * bản đọc cũ của chính nó, **đè mất** cả XP lẫn `reward_keys` bản ghi
   * trước vừa thêm (một request gửi lại `sourceId` đã "mất khoá" đó sau này
   * sẽ được thưởng lần hai). Comment gốc ở `UserStreak.js` đòi đúng "một
   * lệnh ghi vừa kiểm đã thưởng chưa vừa cộng XP" — bản này khôi phục lại
   * đúng ý đó bằng cách gộp điều kiện chống trùng vào filter và dùng phép
   * ghi cộng dồn (`$inc`/`$addToSet`) thay vì set tuyệt đối:
   *
   * - `patch` giờ chỉ chứa các trường **tính lại mỗi lần** của streak
   *   (`current_streak`, `longest_streak`, `last_activity_day`,
   *   `freezes_available`) — không còn `total_xp`/`reward_keys` tuyệt đối.
   *   `freezes_available` vẫn an toàn để `$set`: chỉ lệnh làm đổi
   *   `last_activity_day` mới tiêu băng, mà lệnh đó đã bị khoá bởi điều
   *   kiện ngày trong chính filter này — nên chỉ một request có thể thắng.
   * - `xpDelta` cộng qua `$inc: { total_xp: xpDelta }` — hai request cùng
   *   thắng CAS (vì hai `rewardKey` khác nhau, cùng ngày) cộng dồn đúng thay
   *   vì đè số của nhau.
   * - `rewardKey` (chỉ truyền cho hoạt động one-shot — hoạt động lặp như
   *   `srs.review` để `undefined`) vừa là điều kiện filter
   *   (`reward_keys: { $ne: rewardKey }`, chặn thưởng hai lần cho cùng
   *   `sourceId` **dù ngày không đổi**) vừa là giá trị ghi qua
   *   `$addToSet: { reward_keys: rewardKey }` (không tạo bản sao nếu có race
   *   hi hữu nào đó vẫn lọt qua được filter).
   *
   * `expectedDay ?? null` vì document chưa từng học có `last_activity_day`
   * là `null` (giá trị `default` của field) chứ không phải field vắng mặt —
   * so khớp phải dùng đúng `null`, không phải `undefined`.
   *
   * `runValidators: true` bắt buộc: đây là đường ghi duy nhất chạm tới
   * `freezes_available` (khai báo `min: 0, max: 2` trong `UserStreak.js`).
   * Mongoose **không tự chạy validator** trên `findOneAndUpdate` — thiếu cờ
   * này thì một `patch.freezes_available` sai (bug ở service, vd âm hoặc
   * vượt `MAX_FREEZES`) sẽ được ghi thẳng vào DB, và comment "lưới an toàn
   * thứ hai" ở schema trở thành lời nói suông.
   */
  casUpdate({ userId, expectedDay, patch, xpDelta, rewardKey, session }) {
    const filter = { user: userId, last_activity_day: expectedDay ?? null };
    if (rewardKey) filter.reward_keys = { $ne: rewardKey };

    const update = { $set: patch };
    if (xpDelta) update.$inc = { total_xp: xpDelta };
    if (rewardKey) update.$addToSet = { reward_keys: rewardKey };

    return streakModel.findOneAndUpdate(filter, update, { new: true, runValidators: true, session });
  },

  /**
   * Đảm bảo user có document streak, tạo mới nếu chưa có. Dùng
   * `$setOnInsert` + `upsert` thay vì `findOne` rồi `create` để tránh race
   * giữa hai request đầu tiên của cùng một user (unique index trên `user`
   * sẽ chặn bản ghi trùng, nhưng `upsert` tránh luôn cả lỗi trùng khoá đó).
   *
   * `runValidators: true` cho nhất quán với `casUpdate`/`markDay`: chỉ ghi
   * `user` ở đây nên hiện tại không có validator nào bị bỏ qua, nhưng nếu
   * sau này `$setOnInsert` mở rộng thêm field thì lưới an toàn đã có sẵn
   * thay vì phải nhớ thêm lúc đó.
   */
  ensureFor({ userId, session }) {
    return streakModel.findOneAndUpdate(
      { user: userId },
      { $setOnInsert: { user: userId } },
      { upsert: true, new: true, setDefaultsOnInsert: true, runValidators: true, session },
    );
  },

  /**
   * Ghi một lần cộng XP vào collection riêng (thay cho `xp_history` cũ).
   *
   * Bọc doc trong mảng `[...]` dù chỉ ghi một bản ghi: đây là **bắt buộc**,
   * không phải phong cách. Theo chính cảnh báo trong mã nguồn Mongoose (xem
   * `Model.create`, gh-7535), truyền `session` qua tham số `options` thứ hai
   * chỉ có tác dụng khi tham số đầu là mảng — truyền thẳng một object doc
   * (không bọc mảng) khiến Mongoose không nhận ra `options` là options, nên
   * `session` bị bỏ qua lặng lẽ và bản ghi này rơi ra ngoài transaction.
   */
  appendXpEvent({ userId, amount, reason, type, sourceId, earnedAt, session }) {
    return xpModel.create(
      [
        {
          user: userId,
          amount,
          reason,
          type,
          source_id: sourceId,
          earned_at: earnedAt,
        },
      ],
      { session },
    );
  },

  /**
   * Đánh dấu một ngày trong lịch học (thay cho `activity_dates` cũ).
   *
   * Upsert theo `(user, day_key)` — trùng với unique index của `StreakDay` —
   * nên gọi lại nhiều lần cho cùng một ngày (retry, hai thiết bị) không sinh
   * bản sao. `$setOnInsert` chứ không phải `$set`: nếu ngày đó đã có bản ghi
   * rồi thì giữ nguyên `status` ban đầu, không để một lần gọi lại vô tình đổi
   * ngày đã "studied" thành "frozen" hay ngược lại.
   *
   * `runValidators: true` để nhánh insert của upsert vẫn bị chặn nếu có ai
   * gọi `markDay` với `status` ngoài enum `['studied', 'frozen']` — không có
   * cờ này, Mongoose bỏ qua schema và ghi thẳng giá trị sai vào DB.
   */
  markDay({ userId, dayKey, status, session }) {
    return dayModel.updateOne(
      { user: userId, day_key: dayKey },
      { $setOnInsert: { user: userId, day_key: dayKey, status } },
      { upsert: true, runValidators: true, session },
    );
  },

  /** Lịch sử XP, mới nhất trước, có phân trang cho màn hiển thị. */
  listXpEvents({ userId, page = 1, limit = 20 }) {
    return xpModel
      .find({ user: userId })
      .sort({ earned_at: -1 })
      .skip((page - 1) * limit)
      .limit(limit)
      .lean();
  },

  /** Tổng số bản ghi XP của user, dùng cùng `listXpEvents` để dựng phân trang. */
  countXpEvents({ userId }) {
    return xpModel.countDocuments({ user: userId });
  },
});

/** Bản dựng sẵn dùng model thật, cho service không cần tự lắp tham số. */
export const streakRepository = createStreakRepository();

export default streakRepository;
