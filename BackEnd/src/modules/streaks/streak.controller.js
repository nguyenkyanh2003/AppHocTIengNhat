import { list, ok } from '../../shared/http/respond.js';

/**
 * HTTP của streak — chỉ còn đường **đọc**.
 *
 * Ba endpoint ghi cũ đã bị gỡ: `POST /add-xp` nhận thẳng số XP từ client,
 * `POST /test/reset-yesterday` và `GET /test/debug` là công cụ thử nghiệm để
 * lọt ra production. XP và ngày học giờ chỉ đi qua `recordActivity`, do chính
 * service nghiệp vụ gọi sau khi đã chấm xong (spec §3.1).
 */
export const createStreakController = (readService, settingsService) => ({
  async getMyStreak(req, res) {
    ok(res, await readService.summary(req.user._id));
  },

  /**
   * `mode=page` đọc theo con trỏ cho tệp xuất dữ liệu: `next_cursor` là trang sau
   * (`null` là hết), `as_of` là mốc chụp để các trang khớp nhau khi XP mới chen vào.
   */
  async getXpHistory(req, res) {
    const { mode, limit, cursor } = req.valid.query;
    if (mode !== 'page') {
      list(res, await readService.xpHistory(req.user._id));
      return;
    }
    const page = await readService.xpHistoryPage(req.user._id, { limit, cursor });
    ok(res, page.data, { next_cursor: page.next_cursor, as_of: page.as_of });
  },

  /** Lịch học theo khoảng ngày: `from`/`to` là khoảng server đã chọn, `next_cursor` là trang sau. */
  async getDays(req, res) {
    const { data, ...meta } = await readService.days(req.user._id, req.valid.query);
    ok(res, data, meta);
  },

  async getLeaderboard(req, res) {
    const { period, limit } = req.valid.query;
    ok(res, await readService.leaderboard({ userId: req.user._id, period, limit }));
  },

  async getSettings(req, res) {
    ok(res, await settingsService.get(req.user._id));
  },

  async putSettings(req, res) {
    ok(res, await settingsService.update(req.user._id, req.valid.body));
  },
});

export default createStreakController;
