import { ApiError } from '../../shared/http/api-error.js';
import { LEGACY_XP_TYPE, streakRepository } from './streak.repository.js';
import { addDays, dayKey as defaultDayKey, daysBetween, projectStreak } from './streak-rules.js';

/**
 * Đường **đọc** của streak: tóm tắt, lịch sử XP, bảng xếp hạng.
 *
 * Tách khỏi `streak.service.js` vì hai nửa có luật ngược nhau: cổng ghi được
 * phép (và phải) ghi trong transaction, còn đường đọc thì tuyệt đối không ghi
 * gì — mở app xem streak không được tạo document, không được reset chuỗi, không
 * được cộng XP. Đó chính là lỗi cũ của `GET /my-streak` (spec §3.5).
 *
 * Hình dạng response giữ nguyên như bản cũ để client hiện tại chạy tiếp. Trong
 * lúc chờ migration (spec §4.1), lịch sử cũ nằm trong ba mảng của `UserStreak`
 * vẫn được gộp vào khi đọc, để người học không thấy lịch sử của mình biến mất.
 */

const XP_PER_LEVEL = 100;
const PAGE_SIZE = 200;
const DAY_MS = 24 * 60 * 60 * 1000;

/**
 * Giờ Việt Nam lệch cố định +07:00, không có giờ mùa hè — nên nửa đêm của một
 * `day_key` quy ra mốc UTC bằng một phép ghép chuỗi, không cần thư viện múi giờ.
 */
const VIETNAM_OFFSET = '+07:00';

/** Số ngày lịch Việt Nam của mỗi kỳ, **tính cả hôm nay**. */
const PERIOD_DAYS = Object.freeze({ week: 7, month: 30 });

/** Khoảng dài nhất một lần đọc lịch: một năm nhuận, tính cả hai đầu (spec §4.3). */
const MAX_DAY_RANGE = 366;

const OBJECT_ID = /^[a-f0-9]{24}$/i;

/**
 * Cursor của lịch sử XP phân trang — mờ với client (base64url của JSON).
 *
 * Mang theo user và `as_of`: dán cursor của người khác không đọc được gì, và
 * mọi trang của một lần xuất nhìn cùng một mốc thời gian (spec §4.2).
 */
const encodeCursor = (value) => Buffer.from(JSON.stringify(value), 'utf8').toString('base64url');

const isValidPosition = (value) =>
  value.phase === 'events'
    ? value.at === undefined || (!Number.isNaN(Date.parse(value.at)) && OBJECT_ID.test(value.id))
    : value.phase === 'legacy' && Number.isSafeInteger(value.offset) && value.offset >= 0;

const decodeCursor = (raw, userId) => {
  let value = null;
  try {
    value = JSON.parse(Buffer.from(raw, 'base64url').toString('utf8'));
  } catch {
    // Rơi xuống nhánh báo lỗi bên dưới.
  }
  const valid =
    value !== null &&
    typeof value === 'object' &&
    value.u === String(userId) &&
    !Number.isNaN(Date.parse(value.asOf)) &&
    isValidPosition(value);
  if (!valid) throw ApiError.badRequest('Cursor không hợp lệ.', { code: 'INVALID_CURSOR' });
  return value;
};

const newestFirst = (a, b) => new Date(b.earned_at) - new Date(a.earned_at);

const dayRow = (day) => ({
  day_key: day.day_key,
  status: day.status,
  origin: day.origin ?? 'activity',
  direct_xp: day.direct_xp ?? 0,
  review_count: day.review_count ?? 0,
  correct_self_reports: day.correct_self_reports ?? 0,
  wrong_self_reports: day.wrong_self_reports ?? 0,
});

/** Nhãn đọc được cho từng loại event, thay cho tên kỹ thuật. */
const REASON_LABELS = Object.freeze({
  'srs.review': 'Ôn tập SRS',
  'lesson.progress': 'Học mục trong bài',
  'lesson.complete': 'Hoàn thành bài học',
  'exercise.submit': 'Làm bài tập',
  'jlpt.submit': 'Làm đề JLPT',
  'streak.milestone': 'Thưởng mốc chuỗi ngày',
  'achievement.unlock': 'Mở khoá thành tích',
});

/**
 * Level suy ra từ tổng XP, cùng công thức với virtual của model.
 *
 * Tính lại mỗi lần đọc thay vì đọc trường `level` đã lưu: đường ghi mới chỉ
 * cộng `total_xp`, nên `level` trong document là của cơ chế cũ và đứng yên.
 */
export const levelFor = (totalXp) => Math.floor(Math.max(0, totalXp) / XP_PER_LEVEL) + 1;

const xpToNextLevel = (totalXp) => levelFor(totalXp) * XP_PER_LEVEL - totalXp;

export const createStreakReadService = ({
  repository = streakRepository,
  dayKey = defaultDayKey,
  clock = () => new Date(),
} = {}) => {
  /** Chuỗi hiện tại **đang còn hiệu lực**, không ghi lại gì. */
  const liveStreak = (summary, todayKey) =>
    summary
      ? projectStreak(
          {
            currentStreak: summary.current_streak ?? 0,
            lastActivityDay: summary.last_activity_day ?? null,
            freezesAvailable: summary.freezes_available ?? 0,
          },
          todayKey,
        ).currentStreak
      : 0;

  /**
   * Đọc hết mọi trang. Repository chặn mỗi trang ở 200 bản ghi; dừng ở trang
   * đầu là cắt cụt lịch sử của người học lâu năm — đúng lỗi làm export thiếu.
   */
  const readAll = async (readPage, cursorOf) => {
    const rows = [];
    let cursor;
    for (;;) {
      const page = await readPage(cursor);
      rows.push(...page);
      if (page.length < PAGE_SIZE) return rows;
      cursor = cursorOf(page[page.length - 1]);
    }
  };

  const allXpEvents = (userId) =>
    readAll(
      (cursor) => repository.listEvents({ userId, cursor, limit: PAGE_SIZE, withXpOnly: true }),
      (last) => ({ occurredAt: last.occurred_at, id: last._id }),
    );

  const allDays = (userId) =>
    readAll(
      (cursor) => repository.listDays({ userId, cursor, limit: PAGE_SIZE }),
      (last) => last.day_key,
    );

  /**
   * Ngày có học, cho lịch và heatmap.
   *
   * Ngày băng (`frozen`) không phải ngày học nên bị loại. Ngày cũ giữ nguyên
   * định dạng client đã quen đọc — đổi chúng sang `day_key` ở đây nghĩa là
   * đoán múi giờ của dữ liệu legacy, việc mà spec §4.1 bước 2 cấm làm khi
   * chưa audit.
   */
  const activityDates = async (userId, summary) => {
    const days = await allDays(userId);
    const studied = days
      .filter((day) => day.status === 'studied' || day.status === 'legacy')
      .map((day) => day.day_key);
    const legacy = (summary?.activity_dates ?? []).map((date) => new Date(date).toISOString());

    return [...new Set([...legacy, ...studied])].sort();
  };

  const periodTotals = async ({ period, now }) => {
    const todayKey = dayKey(now);
    const fromDay = dayKey(new Date(now.getTime() - (PERIOD_DAYS[period] - 1) * DAY_MS));

    const [eventTotals, migrated] = await Promise.all([
      repository.sumXpByUserBetween({ fromDay, toDay: todayKey }),
      repository.usersWithLegacyImport(),
    ]);
    const legacyTotals = await repository.sumLegacyXpByUserSince({
      since: new Date(`${fromDay}T00:00:00${VIETNAM_OFFSET}`),
      excludeUserIds: migrated,
    });

    const totals = new Map();
    for (const { _id, total } of [...eventTotals, ...legacyTotals]) {
      const key = String(_id);
      totals.set(key, (totals.get(key) ?? 0) + total);
    }
    return totals;
  };

  const entryFor = ({ summary, user, rank, todayKey, periodXp }) => {
    const totalXp = summary?.total_xp ?? 0;
    const entry = {
      rank,
      user: user ?? null,
      total_xp: totalXp,
      level: levelFor(totalXp),
      current_streak: liveStreak(summary, todayKey),
      longest_streak: summary?.longest_streak ?? 0,
    };
    if (periodXp !== undefined) entry.period_xp = periodXp;
    return entry;
  };

  const usersById = async (ids) => {
    const users = await repository.findUsersByIds(ids);
    return new Map(users.map((user) => [String(user._id), user]));
  };

  const historyRow = (event) => ({
    amount: event.xp_delta,
    reason: REASON_LABELS[event.type] ?? event.reason ?? event.type,
    earned_at: event.occurred_at,
  });

  /**
   * Mảng `xp_history` cũ, mới nhất trước — rỗng khi migration đã chép nó
   * thành event, để không dòng nào hiện hai lần.
   */
  const legacyXpRows = async (userId) => {
    const [summary, imported] = await Promise.all([
      repository.findByUser({ userId }),
      repository.hasLegacyImport({ userId }),
    ]);
    if (imported) return [];
    return (summary?.xp_history ?? [])
      .map(({ amount, reason, earned_at: earnedAt }) => ({ amount, reason, earned_at: earnedAt }))
      .sort(newestFirst);
  };

  return {
    /** Tóm tắt cho trang chủ và màn streak. Không ghi, không tạo document. */
    async summary(userId) {
      const summary = await repository.findByUser({ userId });
      const todayKey = dayKey(clock());
      const totalXp = summary?.total_xp ?? 0;
      const level = levelFor(totalXp);
      const lastActivityDay = summary?.last_activity_day ?? null;

      return {
        _id: summary?._id ?? null,
        user: userId,
        current_streak: liveStreak(summary, todayKey),
        longest_streak: summary?.longest_streak ?? 0,
        total_xp: totalXp,
        level,
        current_level: level,
        xp_to_next_level: xpToNextLevel(totalXp),
        last_activity_day: lastActivityDay,
        // Alias cho client cũ đang parse `last_activity_date`. Ngày học mới là
        // một ngày lịch, nên đưa ra đúng dạng ngày; chỉ user chưa học lần nào
        // sau cutover mới còn thấy mốc thời gian cũ.
        last_activity_date: lastActivityDay ?? summary?.last_activity_date ?? null,
        total_active_days: summary?.total_active_days ?? 0,
        legacy_day_count: summary?.legacy_day_count ?? 0,
        studied_today: lastActivityDay === todayKey,
        // Mốc dừng cho client đọc lịch ngược từng khoảng qua `GET /days`.
        first_day: await repository.findFirstDayKey({ userId }),
        activity_dates: await activityDates(userId, summary),
      };
    },

    /** Những ngày có học, cho lịch và heatmap. */
    async activityDates(userId) {
      return activityDates(userId, await repository.findByUser({ userId }));
    },

    /**
     * Toàn bộ lịch sử XP, mới nhất trước — client export đọc đúng mảng này
     * nên không được cắt trang.
     */
    async xpHistory(userId) {
      const [events, legacy] = await Promise.all([allXpEvents(userId), legacyXpRows(userId)]);
      return [...events.map(historyRow), ...legacy].sort(newestFirst);
    },

    /**
     * Một trang lịch sử XP, mới nhất trước: `{ data, next_cursor, as_of }`.
     *
     * Đọc qua hai pha nối tiếp: event trong nhật ký, rồi mảng `xp_history` cũ
     * của user chưa migration. Nối như vậy vẫn đúng thứ tự mới → cũ vì mảng cũ
     * đã đóng băng từ cutover — không writer nào ghi thêm vào đó nữa.
     *
     * Mỗi pha đọc dư một bản ghi để biết còn trang sau hay không, nên client
     * không phải gọi thêm một lần chỉ để nhận về trang rỗng.
     */
    async xpHistoryPage(userId, { limit, cursor: rawCursor }) {
      const cursor = rawCursor
        ? decodeCursor(rawCursor, userId)
        : { u: String(userId), asOf: clock().toISOString(), phase: 'events' };
      const nextCursor = (position) => encodeCursor({ u: cursor.u, asOf: cursor.asOf, ...position });
      const page = { data: [], next_cursor: null, as_of: cursor.asOf };

      if (cursor.phase === 'events') {
        const events = await repository.listEvents({
          userId,
          asOf: new Date(cursor.asOf),
          withXpOnly: true,
          limit: limit + 1,
          cursor: cursor.at ? { occurredAt: new Date(cursor.at), id: cursor.id } : undefined,
        });
        const shown = events.slice(0, limit);
        page.data.push(
          ...shown.map((event) => ({
            ...historyRow(event),
            source: event.type === LEGACY_XP_TYPE ? 'legacy' : 'activity',
          })),
        );
        if (events.length > limit) {
          const last = shown[shown.length - 1];
          page.next_cursor = nextCursor({
            phase: 'events',
            at: new Date(last.occurred_at).toISOString(),
            id: String(last._id),
          });
          return page;
        }
      }

      const offset = cursor.phase === 'legacy' ? cursor.offset : 0;
      const room = limit - page.data.length;
      const legacy = await legacyXpRows(userId);
      page.data.push(...legacy.slice(offset, offset + room).map((row) => ({ ...row, source: 'legacy' })));
      if (offset + room < legacy.length) {
        page.next_cursor = nextCursor({ phase: 'legacy', offset: offset + room });
      }
      return page;
    },

    /**
     * Lịch học trong một khoảng ngày, mới nhất trước: `{ data, next_cursor, from, to }`.
     *
     * Thiếu `to` thì lấy hôm nay; thiếu `from` thì lùi đủ một khoảng tối đa.
     * Chỉ đọc `StreakDay` — ngày trong mảng `activity_dates` cũ có mặt ở đây
     * sau khi migration chép chúng thành ngày `legacy`, vì đổi Date cũ sang
     * ngày lịch trước khi audit múi giờ là đoán (spec §4.1 bước 2).
     */
    async days(userId, { from, to, cursor, limit }) {
      const end = to ?? dayKey(clock());
      const start = from ?? addDays(end, -(MAX_DAY_RANGE - 1));
      const span = daysBetween(start, end);
      if (span < 0 || span >= MAX_DAY_RANGE) {
        throw ApiError.badRequest(`Khoảng ngày phải hợp lệ và không quá ${MAX_DAY_RANGE} ngày.`, {
          code: 'INVALID_DAY_RANGE',
        });
      }

      const rows = await repository.listDays({ userId, from: start, to: end, cursor, limit: limit + 1 });
      const shown = rows.slice(0, limit);
      return {
        data: shown.map(dayRow),
        next_cursor: rows.length > limit ? shown[shown.length - 1].day_key : null,
        from: start,
        to: end,
      };
    },

    /**
     * Bảng xếp hạng. `all` xếp theo tổng XP trọn đời; `week`/`month` xếp theo
     * XP kiếm được trong 7/30 ngày lịch Việt Nam gần nhất, tính cả hôm nay.
     *
     * Hạng của người đang xem được tính trên **cùng** thứ tự với danh sách —
     * lệch nhau là cách để một người thấy mình hạng 3 mà đứng thứ 5.
     */
    async leaderboard({ userId, period = 'all', limit = 50 }) {
      const now = clock();
      const todayKey = dayKey(now);

      if (period === 'all') {
        const [top, mine] = await Promise.all([
          repository.topByTotalXp({ limit }),
          repository.findByUser({ userId }),
        ]);
        const users = await usersById(top.map((row) => row.user));
        const above = mine
          ? await repository.countRankedAbove({
              totalXp: mine.total_xp ?? 0,
              currentStreak: mine.current_streak ?? 0,
              id: mine._id,
            })
          : null;

        return {
          leaderboard: top.map((summary, index) =>
            entryFor({ summary, user: users.get(String(summary.user)), rank: index + 1, todayKey }),
          ),
          user_rank: above === null ? null : above + 1,
        };
      }

      const totals = await periodTotals({ period, now });
      const ids = [...totals.entries()].filter(([, xp]) => xp > 0).map(([id]) => id);
      const summaries = await repository.findSummaries({ userIds: ids });
      const summaryOf = new Map(summaries.map((summary) => [String(summary.user), summary]));

      const ranked = ids
        .map((id) => ({ id, periodXp: totals.get(id), summary: summaryOf.get(id) }))
        .sort(
          (a, b) =>
            b.periodXp - a.periodXp ||
            (b.summary?.total_xp ?? 0) - (a.summary?.total_xp ?? 0) ||
            a.id.localeCompare(b.id),
        );

      const top = ranked.slice(0, limit);
      const users = await usersById(top.map((row) => row.id));
      const position = ranked.findIndex((row) => row.id === String(userId));

      return {
        leaderboard: top.map((row, index) =>
          entryFor({
            summary: row.summary,
            user: users.get(row.id),
            rank: index + 1,
            todayKey,
            periodXp: row.periodXp,
          }),
        ),
        user_rank: position === -1 ? null : position + 1,
      };
    },
  };
};

export const streakReadService = createStreakReadService();

export default streakReadService;
