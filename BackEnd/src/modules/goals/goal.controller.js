import { created, list, ok } from '../../shared/http/respond.js';

/**
 * Controller chỉ map HTTP <-> service; chủ mục tiêu luôn lấy từ phiên đăng
 * nhập (`req.user`), không bao giờ từ body.
 */
export const createGoalController = (service) => ({
  /**
   * `counts`: số đã học hiện tại của cả ba loại ("bạn đang có X"); `available`:
   * số bài và số chữ Kanji các bài học đang có — trần để đạt mục tiêu.
   */
  async list(req, res) {
    const { goals, counts, available } = await service.list(req.user._id);
    return list(res, goals, { counts, available });
  },

  async create(req, res) {
    const goal = await service.create({ userId: req.user._id, ...req.valid.body });
    return created(res, goal);
  },

  async update(req, res) {
    const goal = await service.update({ id: req.valid.params.id, userId: req.user._id, changes: req.valid.body });
    return ok(res, goal);
  },

  async remove(req, res) {
    await service.remove({ id: req.valid.params.id, userId: req.user._id });
    return ok(res, { deleted: true });
  },
});
