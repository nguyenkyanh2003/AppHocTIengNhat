/**
 * HTTP của streak — chỉ còn đường **đọc**.
 *
 * Ba endpoint ghi cũ đã bị gỡ: `POST /add-xp` nhận thẳng số XP từ client,
 * `POST /test/reset-yesterday` và `GET /test/debug` là công cụ thử nghiệm để
 * lọt ra production. XP và ngày học giờ chỉ đi qua `recordActivity`, do chính
 * service nghiệp vụ gọi sau khi đã chấm xong (spec §3.1).
 *
 * Response trả thẳng, không bọc `{ data }`: đây là ba hợp đồng client hiện tại
 * đang đọc, và đổi vỏ response là việc của đợt làm lại phần đọc (plan Task 2.5).
 */
export const createStreakController = (readService) => ({
  async getMyStreak(req, res) {
    res.json(await readService.summary(req.user._id));
  },

  async getXpHistory(req, res) {
    res.json(await readService.xpHistory(req.user._id));
  },

  async getLeaderboard(req, res) {
    const { period, limit } = req.valid.query;
    res.json(await readService.leaderboard({ userId: req.user._id, period, limit }));
  },
});

export default createStreakController;
