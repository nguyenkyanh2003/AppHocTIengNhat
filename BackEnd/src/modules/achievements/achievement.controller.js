import { created, list, ok } from '../../shared/http/respond.js';

/**
 * HTTP của huy hiệu: chỉ map request sang service.
 *
 * `POST /update-progress` không còn: tiến độ do server tự đếm, và huy hiệu
 * được cấp trong cổng ghi hoạt động học, không nhận lời khai từ client.
 */
export const createAchievementController = (service) => ({
  async getAll(_req, res) {
    list(res, await service.listActive());
  },

  async getMyAchievements(req, res) {
    ok(res, await service.myAchievements(req.user._id));
  },

  async getByCategory(req, res) {
    ok(res, await service.byCategory(req.user._id, req.valid.params.category));
  },

  async getStats(req, res) {
    ok(res, await service.stats(req.user._id));
  },

  async getAdminAll(_req, res) {
    list(res, await service.listAll());
  },

  async postCreate(req, res) {
    created(res, await service.create(req.valid.body), { message: 'Tạo thành tích thành công' });
  },

  async putAdminById(req, res) {
    const achievement = await service.update(req.valid.params.id, req.valid.body);
    ok(res, achievement, { message: 'Cập nhật thành công' });
  },

  async deleteAdminById(req, res) {
    await service.remove(req.valid.params.id);
    ok(res, { deleted: true }, { message: 'Xóa thành tích thành công' });
  },
});

export default createAchievementController;
