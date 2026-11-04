import { list } from '../../shared/http/respond.js';
import { convertDatesToVietnam } from '../../shared/utils/timezone.js';

/**
 * Controller thống kê học tập: chỉ map HTTP <-> service.
 *
 * `GET /` theo contract danh sách `{ data, total }`. Các route dashboard và
 * analytics giữ vỏ response như bản cũ (trả thẳng object/mảng, không bọc
 * `{ data }`) vì Flutter đang đọc trực tiếp các khoá đó.
 */
export const createProgressController = (service) => ({
  async list(req, res) {
    const items = await service.listLessonProgress(req.user._id);
    return list(res, convertDatesToVietnam(items));
  },

  async stats(req, res) {
    return res.json(await service.dashboardStats(req.user._id));
  },

  async timeline(req, res) {
    return res.json(await service.timeline(req.user._id, req.valid.query.period));
  },

  async heatmap(req, res) {
    return res.json(await service.heatmap(req.user._id, req.valid.query.year));
  },

  async breakdown(req, res) {
    return res.json(await service.breakdown(req.user._id));
  },

  async adminAnalytics(req, res) {
    return res.json(await service.adminAnalytics(req.valid.query.period));
  },
});

export default createProgressController;
