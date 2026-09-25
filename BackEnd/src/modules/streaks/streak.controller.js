import { ok } from '../../shared/http/respond.js';

/**
 * HTTP của streak — chỉ còn đường **đọc**.
 *
 * Ba endpoint ghi cũ đã bị gỡ: `POST /add-xp` nhận thẳng số XP từ client,
 * `POST /test/reset-yesterday` và `GET /test/debug` là công cụ thử nghiệm để
 * lọt ra production. XP và ngày học giờ chỉ đi qua `recordActivity`, do chính
 * service nghiệp vụ gọi sau khi đã chấm xong (spec §3.1).
 *
 * `/my-streak`, `/xp-history` không query và `/leaderboard` trả thẳng, không
 * bọc `{ data }`: đó là hợp đồng client cũ đang đọc. Các đường mới —
 * `xp-history?mode=page`, `/days` và `/settings` — theo response contract chung.
 */
export const createStreakController = (readService, settingsService) => ({
  async getMyStreak(req, res) {
    res.json(await readService.summary(req.user._id));
  },

  async getXpHistory(req, res) {
    const { mode, limit, cursor } = req.valid.query;
    if (mode !== 'page') {
      res.json(await readService.xpHistory(req.user._id));
      return;
    }
    const page = await readService.xpHistoryPage(req.user._id, { limit, cursor });
    ok(res, page.data, { next_cursor: page.next_cursor, as_of: page.as_of });
  },

  async getDays(req, res) {
    const { data, ...meta } = await readService.days(req.user._id, req.valid.query);
    ok(res, data, meta);
  },

  async getLeaderboard(req, res) {
    const { period, limit } = req.valid.query;
    res.json(await readService.leaderboard({ userId: req.user._id, period, limit }));
  },

  async getSettings(req, res) {
    ok(res, await settingsService.get(req.user._id));
  },

  async putSettings(req, res) {
    ok(res, await settingsService.update(req.user._id, req.valid.body));
  },
});

export default createStreakController;
