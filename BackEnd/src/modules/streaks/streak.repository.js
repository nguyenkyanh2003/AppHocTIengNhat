import ActivityEvent from '../../../model/ActivityEvent.js';
import StreakDay from '../../../model/StreakDay.js';
import UserStreak from '../../../model/UserStreak.js';

/**
 * Truy cập dữ liệu streak: nhật ký hoạt động, lịch ngày, và tóm tắt.
 *
 * Hai quyết định định hình cả tầng này:
 *
 * **1. Ghi event trước, cập nhật tóm tắt sau** (spec §3.1). Thiết kế trước làm
 * ngược lại — CAS tóm tắt trước rồi mới ghi nhật ký — nên câu hỏi "hoạt động
 * này đã được ghi chưa" phải trả lời bằng cách đọc một mảng khoá rồi so, và
 * giữa lúc đọc và lúc ghi luôn có khe hở. Bây giờ chính lần `insert` là câu
 * trả lời: unique index `(user, event_key)` do Mongo bảo đảm, không có khe hở
 * nào để lọt.
 *
 * **2. CAS trên `revision`, không trên `last_activity_day`** (spec §3.5). Hai
 * hoạt động khác nhau trong cùng một ngày không làm đổi ngày, nên filter theo
 * ngày khớp cho cả hai request đồng thời và bản ghi sau đè mất bản ghi trước.
 * `revision` đổi ở mọi lần ghi nên chỉ đúng một bên thắng.
 *
 * Model nhận qua tham số (mặc định về model thật) để test thay bằng model giả,
 * không cần MongoDB — cùng khuôn với `srs.repository.js`.
 */

/** Trần số bản ghi một lần đọc được phép trả, để không ai xin cả collection. */
const MAX_PAGE_SIZE = 200;
const DEFAULT_PAGE_SIZE = 20;

const DAY_STATUSES = new Set(['studied', 'frozen', 'legacy']);

const isDuplicateOf = (error, field) =>
  error?.code === 11000 && Boolean(error?.keyPattern && field in error.keyPattern);

const pageSize = (limit) => {
  const value = Number.isSafeInteger(limit) && limit > 0 ? limit : DEFAULT_PAGE_SIZE;
  return Math.min(value, MAX_PAGE_SIZE);
};

export const createStreakRepository = ({
  UserStreak: streakModel = UserStreak,
  ActivityEvent: eventModel = ActivityEvent,
  StreakDay: dayModel = StreakDay,
} = {}) => ({
  /** Đọc tóm tắt hiện tại, không ghi gì và không tiêu băng. */
  findByUser({ userId, session }) {
    return streakModel.findOne({ user: userId }).session(session).lean();
  },

  /**
   * Ghi một hoạt động vào nhật ký. Trả về `null` nếu hoạt động đó **đã được
   * ghi rồi** — không phải lỗi, mà là câu trả lời.
   *
   * Chỉ nuốt E11000 đến từ đúng index `event_key`. Nuốt mọi E11000 sẽ che mất
   * lỗi thật nếu collection có thêm unique index khác sau này, và một lần ghi
   * hỏng bị bỏ qua im lặng là kiểu hỏng khó lần ngược nhất.
   *
   * Mảng `[doc]` là bắt buộc chứ không phải phong cách: theo chính cảnh báo
   * trong mã nguồn Mongoose (`Model.create`, gh-7535), `session` ở tham số
   * thứ hai chỉ có tác dụng khi tham số đầu là mảng. Truyền thẳng một object
   * khiến `session` bị bỏ qua lặng lẽ và bản ghi rơi ra ngoài transaction —
   * đúng thứ mà cả thiết kế này dựa vào.
   */
  async insertEvent({
    userId,
    eventKey,
    type,
    sourceId,
    occurredAt,
    dayKey,
    xpDelta = 0,
    reason,
    countsAsStudy = false,
    policyVersion,
    receipt,
    session,
  }) {
    const doc = {
      user: userId,
      event_key: eventKey,
      type,
      source_id: sourceId,
      occurred_at: occurredAt,
      day_key: dayKey,
      xp_delta: xpDelta,
      reason,
      counts_as_study: countsAsStudy,
      policy_version: policyVersion,
    };
    // Chỉ đính receipt khi thật sự có: để `undefined` lọt vào doc thì Mongoose
    // vẫn tạo field rỗng, và mọi event thường đều mang theo một field thừa.
    if (receipt !== undefined) doc.receipt = receipt;

    try {
      const [saved] = await eventModel.create([doc], { session });
      return saved;
    } catch (error) {
      if (isDuplicateOf(error, 'event_key')) return null;
      throw error;
    }
  },

  /**
   * Ghi tóm tắt có điều kiện: chỉ thành công nếu `revision` trong DB vẫn đúng
   * bằng giá trị vừa đọc. Trả `null` khi thua — caller đọc lại rồi thử lại.
   *
   * `$inc` cho mọi số cộng dồn (`total_xp`, `total_active_days`) thay vì `$set`
   * giá trị tuyệt đối tính từ một lần đọc trước đó: ngay cả khi CAS đã chặn
   * được ghi đồng thời, dùng `$inc` khiến phép ghi tự nó đúng, không phụ thuộc
   * vào việc bản đọc có còn tươi hay không.
   *
   * `runValidators: true` là bắt buộc: Mongoose **không** tự chạy validator
   * trên `findOneAndUpdate`, nên thiếu cờ này thì mọi `min`/`max`/`enum` khai
   * trong schema trở thành lời nói suông ở đúng đường ghi chính.
   */
  casSummary({ userId, expectedRevision, patch, inc, session }) {
    const update = { $inc: { ...inc, revision: 1 } };
    // `$set: {}` không phải no-op mà là lỗi cú pháp của Mongo ("'$set' is
    // empty") — chỉ đính khi có gì để đặt.
    if (patch && Object.keys(patch).length > 0) update.$set = patch;

    return streakModel.findOneAndUpdate({ user: userId, revision: expectedRevision }, update, {
      new: true,
      runValidators: true,
      lean: true,
      session,
    });
  },

  /**
   * Đảm bảo user có tóm tắt, tạo nếu chưa có.
   *
   * `upsert` vẫn có thể ném E11000 khi hai request đầu tiên của cùng một user
   * chạy song song: cả hai cùng không tìm thấy document, cùng chuyển sang
   * nhánh insert, và unique index `user` chặn bên chậm hơn. Bên thua chỉ cần
   * đọc lại — bên thắng vừa tạo đúng thứ nó cần (spec §3.5).
   */
  async ensureSummary({ userId, session }) {
    try {
      return await streakModel.findOneAndUpdate(
        { user: userId },
        { $setOnInsert: { user: userId } },
        { upsert: true, new: true, setDefaultsOnInsert: true, runValidators: true, lean: true, session },
      );
    } catch (error) {
      if (!isDuplicateOf(error, 'user')) throw error;
      return streakModel.findOne({ user: userId }).session(session).lean();
    }
  },

  /**
   * Ghi nhận một ngày trong lịch, cộng dồn các số đếm trong ngày.
   *
   * `studied` dùng `$set` cho `status`: một ngày đang là `legacy` mà có hoạt
   * động thật phải được nâng lên `studied` (spec §3.2). `frozen`/`legacy` thì
   * chỉ `$setOnInsert` — chúng không được phép hạ cấp một ngày đã chứng minh
   * là có học.
   *
   * `origin` luôn chỉ nằm trong `$setOnInsert`, kể cả với `studied`: ngày
   * legacy được nâng cấp vẫn giữ dấu nguồn của nó, nhờ đó migration biết ngày
   * đó đã được tính ở baseline và không cộng lại độ dài chuỗi lần thứ hai.
   */
  async upsertDay({
    userId,
    dayKey,
    status,
    origin = 'activity',
    incDirectXp = 0,
    incReviewCount = 0,
    incCorrect = 0,
    incWrong = 0,
    session,
  }) {
    // Chặn ngay tại đây thay vì để `runValidators` bắt ở nhánh insert: với
    // upsert, một `status` sai chỉ lộ ra khi bản ghi chưa tồn tại — nhánh
    // update sẽ ghi im lặng. Kiểm ở đây thì cả hai nhánh đều được chặn.
    //
    // Hàm `async` để lỗi này đi ra bằng **cùng một đường** với lỗi DB (promise
    // bị reject). Một hàm vừa ném đồng bộ vừa trả promise buộc mọi caller phải
    // bọc cả `try/catch` lẫn `.catch()` mới bắt hết.
    if (!DAY_STATUSES.has(status)) {
      throw new RangeError(`status ngày không hợp lệ: ${status}`);
    }

    const setOnInsert = { user: userId, day_key: dayKey, origin };
    const update = {};
    if (status === 'studied') update.$set = { status };
    else setOnInsert.status = status;
    update.$setOnInsert = setOnInsert;

    const inc = {};
    if (incDirectXp) inc.direct_xp = incDirectXp;
    if (incReviewCount) inc.review_count = incReviewCount;
    if (incCorrect) inc.correct_self_reports = incCorrect;
    if (incWrong) inc.wrong_self_reports = incWrong;
    if (Object.keys(inc).length > 0) update.$inc = inc;

    return dayModel.updateOne({ user: userId, day_key: dayKey }, update, {
      upsert: true,
      runValidators: true,
      session,
    });
  },

  /**
   * Nhật ký hoạt động, mới nhất trước, phân trang bằng **cursor hai khoá**.
   *
   * Không dùng `skip`: với `skip(n)` Mongo vẫn phải duyệt qua n bản ghi (chậm
   * dần theo số trang), và quan trọng hơn — một event mới ghi trong lúc người
   * dùng đang lật trang sẽ đẩy toàn bộ danh sách xuống một dòng, làm trang sau
   * lặp lại bản ghi cuối của trang trước.
   *
   * Cursor phải gồm **cả** `_id`: các event ghi trong cùng một transaction có
   * `occurred_at` bằng nhau, nên chỉ so thời gian thì hoặc bỏ sót (`$lt`) hoặc
   * lặp (`$lte`) đúng nhóm đó.
   *
   * `asOf` ghim danh sách vào một mốc thời gian để cả chuỗi trang nhìn cùng
   * một ảnh chụp; `withXpOnly` là cách dựng "lịch sử XP" mà không cần
   * collection thứ hai chứa dữ liệu trùng (spec §3.2).
   */
  listEvents({ userId, cursor, limit, asOf, withXpOnly = false }) {
    const filter = { user: userId };
    if (asOf) filter.occurred_at = { $lte: asOf };
    if (withXpOnly) filter.xp_delta = { $ne: 0 };
    if (cursor) {
      filter.$or = [
        { occurred_at: { $lt: cursor.occurredAt } },
        { occurred_at: cursor.occurredAt, _id: { $lt: cursor.id } },
      ];
    }

    return eventModel
      .find(filter)
      .sort({ occurred_at: -1, _id: -1 })
      .limit(pageSize(limit))
      .lean();
  },

  /** Lịch học trong một khoảng ngày (bao gồm hai đầu), mới nhất trước. */
  listDays({ userId, from, to, cursor, limit }) {
    const range = {};
    if (from) range.$gte = from;
    if (to) range.$lte = to;
    // Cursor của lịch chỉ cần một khoá: `day_key` đã là duy nhất theo user.
    if (cursor) range.$lt = cursor;

    const filter = { user: userId };
    if (Object.keys(range).length > 0) filter.day_key = range;

    return dayModel.find(filter).sort({ day_key: -1 }).limit(pageSize(limit)).lean();
  },

  /**
   * Tổng XP trong một khoảng ngày — nguồn cho leaderboard theo kỳ.
   *
   * Cộng theo `day_key` chứ không theo `occurred_at`: kỳ của bảng xếp hạng là
   * kỳ theo **lịch Việt Nam**, và `day_key` đã là kết quả quy đổi múi giờ một
   * lần lúc ghi. Lọc lại theo mốc UTC ở đây sẽ đưa phép đổi múi giờ trở lại
   * đường đọc, đúng chỗ lỗi cũ đã nằm.
   */
  async sumXpBetween({ userId, fromDay, toDay, session }) {
    const rows = await eventModel.aggregate(
      [
        { $match: { user: userId, day_key: { $gte: fromDay, $lte: toDay }, xp_delta: { $ne: 0 } } },
        { $group: { _id: null, total: { $sum: '$xp_delta' } } },
      ],
      { session },
    );
    // Kỳ không có hoạt động nào là 0 XP, không phải `undefined` — aggregate
    // trả mảng rỗng chứ không trả một dòng tổng bằng 0.
    return rows[0]?.total ?? 0;
  },
});

/** Bản dựng sẵn dùng model thật, cho service không cần tự lắp tham số. */
export const streakRepository = createStreakRepository();

export default streakRepository;
