import { list, ok } from '../../shared/http/respond.js';
import { convertDatesToVietnam } from '../../shared/utils/timezone.js';

/** Controller thống kê học tập: chỉ map HTTP <-> service. */
export const createProgressController = (service) => ({
  async list(req, res) {
    const items = await service.listLessonProgress(req.user._id);
    return list(res, convertDatesToVietnam(items));
  },

  async stats(req, res) {
    return ok(res, await service.dashboardStats(req.user._id));
  },

  async timeline(req, res) {
    return list(res, await service.timeline(req.user._id, req.valid.query.period));
  },

  async heatmap(req, res) {
    return list(res, await service.heatmap(req.user._id, req.valid.query.year));
  },

  async breakdown(req, res) {
    return ok(res, await service.breakdown(req.user._id));
  },

  async adminAnalytics(req, res) {
    return ok(res, await service.adminAnalytics(req.valid.query.period));
  },
});

export default createProgressController;
