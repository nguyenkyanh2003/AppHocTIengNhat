import { LEGACY_XP_TYPE } from '../src/modules/streaks/streak.repository.js';
import { dayKey, isDayKey } from '../src/modules/streaks/streak-rules.js';

/**
 * Logic thuần của audit và migration dữ liệu streak cũ (spec streak §4.1).
 *
 * Không chạm DB: `audit-user-streak.js` và `migrate-streak-legacy.js` đọc dữ
 * liệu thô rồi đưa vào đây, nên mọi quyết định — chép dòng nào, khoá gì, ngày
 * nào, sửa trường nào — đều test được bằng fixture.
 */

/** Đóng dấu vào mọi bản ghi migration tạo ra, để phân biệt và chạy lại an toàn. */
export const MIGRATION_VERSION = 'streak-legacy-migration@2026-09-23';

/** Event đánh dấu một khoản thưởng đã nhận trước cutover — 0 XP, chỉ để chặn phát lại. */
export const LEGACY_REWARD_TYPE = 'legacy.reward';

/** Ngày cutover đường ghi mới (commit `baa8a7a`, 2026-09-20). */
export const DEFAULT_CUTOVER_DAY = '2026-09-20';

const isValidDate = (value) => value instanceof Date && !Number.isNaN(value.getTime());

const isObjectId = (value) => typeof value?.toHexString === 'function';

/** Nửa đêm (giờ Việt Nam, +07:00) của ngày cutover — mốc thời gian của event đánh dấu. */
export const cutoverInstant = (cutoverDay) => new Date(`${cutoverDay}T00:00:00+07:00`);

// --- audit ------------------------------------------------------------------

const lengthStats = (docs, field) => {
  const lengths = docs.map((doc) => (Array.isArray(doc[field]) ? doc[field].length : 0));
  return {
    min: lengths.length ? Math.min(...lengths) : 0,
    max: lengths.length ? Math.max(...lengths) : 0,
    total: lengths.reduce((sum, length) => sum + length, 0),
  };
};

/**
 * Phân phối giờ:phút UTC của các mốc thời gian, nhiều nhất trước.
 *
 * Là cách duy nhất suy ra múi giờ máy chủ đã ghi ngày legacy: code cũ lưu
 * "nửa đêm theo giờ máy chủ", nên mọi mốc tụ về một giờ:phút UTC duy nhất.
 */
export const timeOfDayHistogram = (dates) => {
  const counts = new Map();
  for (const date of dates.filter(isValidDate)) {
    const bucket = date.toISOString().slice(11, 16);
    counts.set(bucket, (counts.get(bucket) ?? 0) + 1);
  }
  return [...counts].sort((a, b) => b[1] - a[1]).map(([time, count]) => ({ time, count }));
};

/** Múi giờ gợi ý khi ≥95% mốc tụ về một nửa đêm nhận ra được; không thì `null`. */
export const suggestLegacyTimeZone = (histogram) => {
  const total = histogram.reduce((sum, row) => sum + row.count, 0);
  const [top] = histogram;
  if (!top || total === 0 || top.count / total < 0.95) return null;
  const known = { '00:00': 'UTC', '17:00': 'Asia/Ho_Chi_Minh' };
  return known[top.time] ? { timeZone: known[top.time], share: top.count / total } : null;
};

/**
 * Báo cáo audit `userstreaks` theo nhóm — chỉ số đếm, không nội dung cá nhân.
 *
 * @param streaks       Document thô từ native collection (chưa qua Mongoose).
 * @param userIds       Tập `_id` user còn tồn tại, dạng chuỗi.
 */
export const auditUserStreaks = ({ streaks, userIds }) => {
  const report = {
    total: streaks.length,
    userMissingOrWrongType: 0,
    userDangling: 0,
    duplicateUsers: 0,
    lastActivityDateInvalid: 0,
    lastActivityDateMissing: 0,
    totalXpInvalid: 0,
    streakNegative: 0,
    currentAboveLongest: 0,
    xpHistoryEntriesInvalid: 0,
    alreadyOnNewPath: 0,
    arrays: {
      xp_history: lengthStats(streaks, 'xp_history'),
      activity_dates: lengthStats(streaks, 'activity_dates'),
      reward_keys: lengthStats(streaks, 'reward_keys'),
    },
  };

  const seen = new Set();
  for (const streak of streaks) {
    if (!isObjectId(streak.user)) report.userMissingOrWrongType += 1;
    else {
      const id = streak.user.toHexString();
      if (!userIds.has(id)) report.userDangling += 1;
      if (seen.has(id)) report.duplicateUsers += 1;
      seen.add(id);
    }

    if (streak.last_activity_date === undefined || streak.last_activity_date === null) {
      report.lastActivityDateMissing += 1;
    } else if (!isValidDate(streak.last_activity_date)) report.lastActivityDateInvalid += 1;

    if (typeof streak.total_xp !== 'number' || !Number.isFinite(streak.total_xp) || streak.total_xp < 0) {
      report.totalXpInvalid += 1;
    }
    const current = streak.current_streak ?? 0;
    const longest = streak.longest_streak ?? 0;
    if (current < 0 || longest < 0) report.streakNegative += 1;
    if (current > longest) report.currentAboveLongest += 1;

    for (const entry of streak.xp_history ?? []) {
      if (typeof entry?.amount !== 'number' || !isValidDate(entry?.earned_at)) report.xpHistoryEntriesInvalid += 1;
    }
    if (streak.last_activity_day) report.alreadyOnNewPath += 1;
  }

  const legacyDates = streaks.flatMap((streak) => [
    ...(streak.activity_dates ?? []),
    ...(streak.last_activity_date ? [streak.last_activity_date] : []),
  ]);
  report.timeOfDay = timeOfDayHistogram(legacyDates).slice(0, 5);
  report.suggestedTimeZone = suggestLegacyTimeZone(timeOfDayHistogram(legacyDates));
  return report;
};

// --- migration --------------------------------------------------------------

/**
 * Kế hoạch chép dữ liệu cũ của **một** user sang nhật ký và lịch mới.
 *
 * - `xp_history` → event `legacy.xp`, giữ số XP, lý do, thời điểm. Khoá theo
 *   `UserStreak._id` + vị trí trong mảng, để hai khoản giống hệt nhau không bị
 *   gộp làm một. Không đụng `total_xp`: số dư đã tính các khoản này rồi.
 * - `reward_keys` → event đánh dấu 0 XP **giữ nguyên khoá**, để writer mới
 *   (vd `lesson-complete:<bài>`) thấy khoá đã có và không phát thưởng lại.
 * - Huy hiệu đã hoàn thành → khoá `achievement:<user>:<huy hiệu>` 0 XP, cùng
 *   lý do.
 * - `activity_dates` → ngày `legacy/legacy_unverified` — chỉ khi đã biết múi
 *   giờ máy chủ cũ (`legacyTimeZone`); đoán múi giờ là đoán sai ngày.
 * - `last_activity_day` điền từ `last_activity_date` nếu còn trống, giữ nguyên
 *   độ dài chuỗi: chuỗi còn hiệu lực không bị hạ, chuỗi đã đứt không được hồi
 *   lại — phép chiếu của đường đọc tự lo hai việc đó.
 */
export const planUserMigration = ({
  streak,
  completedAchievementIds = [],
  legacyTimeZone = null,
  cutoverDay = DEFAULT_CUTOVER_DAY,
}) => {
  if (!isDayKey(cutoverDay)) throw new RangeError(`Ngày cutover không hợp lệ: ${cutoverDay}`);
  const user = streak.user;
  const userId = String(user);
  const fallbackInstant = isValidDate(streak.createdAt) ? streak.createdAt : cutoverInstant(cutoverDay);
  const problems = [];

  const marker = (eventKey, sourceId) => ({
    user,
    event_key: eventKey,
    type: LEGACY_REWARD_TYPE,
    source_id: sourceId,
    occurred_at: cutoverInstant(cutoverDay),
    day_key: cutoverDay,
    xp_delta: 0,
    reason: LEGACY_REWARD_TYPE,
    counts_as_study: false,
    policy_version: MIGRATION_VERSION,
  });

  const xpEvents = (streak.xp_history ?? []).map((entry, index) => {
    const validAmount = typeof entry?.amount === 'number' && Number.isFinite(entry.amount);
    const validDate = isValidDate(entry?.earned_at);
    if (!validAmount || !validDate) problems.push(`xp_history[${index}] thiếu amount hoặc earned_at`);
    const occurredAt = validDate ? entry.earned_at : fallbackInstant;
    return {
      user,
      event_key: `legacy-xp:${String(streak._id)}:${index}`,
      type: LEGACY_XP_TYPE,
      source_id: `xp_history:${index}`,
      occurred_at: occurredAt,
      day_key: dayKey(occurredAt),
      xp_delta: validAmount ? entry.amount : 0,
      reason: entry?.reason ?? LEGACY_XP_TYPE,
      counts_as_study: false,
      policy_version: MIGRATION_VERSION,
    };
  });

  const rewardKeys = [...new Set(streak.reward_keys ?? [])];
  const rewardEvents = rewardKeys.map((key) => marker(key, key));
  const achievementEvents = [...new Set(completedAchievementIds.map(String))].map((id) =>
    marker(`achievement:${userId}:${id}`, id),
  );

  const days = legacyTimeZone
    ? [
        ...new Set(
          (streak.activity_dates ?? []).filter(isValidDate).map((date) => dayKey(date, legacyTimeZone)),
        ),
      ].sort()
    : [];

  const summaryPatch = {};
  if (legacyTimeZone && !streak.last_activity_day && isValidDate(streak.last_activity_date)) {
    summaryPatch.last_activity_day = dayKey(streak.last_activity_date, legacyTimeZone);
  }
  if (!streak.tracking_started_day) summaryPatch.tracking_started_day = cutoverDay;

  return {
    events: [...xpEvents, ...rewardEvents, ...achievementEvents],
    days,
    summaryPatch,
    problems,
    legacyXpTotal: xpEvents.reduce((sum, event) => sum + event.xp_delta, 0),
  };
};

/**
 * Đối chiếu sau khi ghi: mọi thứ trong kế hoạch phải có mặt trong DB.
 *
 * Chênh giữa `total_xp` và tổng XP có lịch sử (dòng cũ + event mới) chỉ được
 * **báo**, không sửa: `total_xp` là số dư người học đã thấy, còn mảng cũ có
 * thể thiếu dòng (spec §4.1 bước 7).
 */
export const verifyUserMigration = ({ plan, streak, storedEventKeys, storedDayKeys, activityXpTotal = 0 }) => {
  const missingEvents = plan.events.filter((event) => !storedEventKeys.has(event.event_key)).length;
  const missingDays = plan.days.filter((day) => !storedDayKeys.has(day)).length;
  return {
    ok: missingEvents === 0 && missingDays === 0,
    missingEvents,
    missingDays,
    xpDifference: (streak.total_xp ?? 0) - plan.legacyXpTotal - activityXpTotal,
  };
};
