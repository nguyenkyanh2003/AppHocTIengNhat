import { created, ok } from '../../shared/http/respond.js';

/**
 * HTTP của huy hiệu. Các đường người học giữ nguyên vỏ response cũ (mảng
 * trần, `{ earned, locked, ... }`) vì client hiện tại đọc thẳng các khoá đó.
 *
 * `POST /update-progress` không còn: tiến độ do server tự đếm, và huy hiệu
 * được cấp trong cổng ghi hoạt động học, không nhận lời khai từ client.
 */
export const createAchievementController = (service) => ({
  async getAll(_req, res) {
    res.json(await service.listActive());
  },

  async getMyAchievements(req, res) {
    res.json(await service.myAchievements(req.user._id));
  },

  async getByCategory(req, res) {
    res.json(await service.byCategory(req.user._id, req.valid.params.category));
  },

  async getStats(req, res) {
    res.json(await service.stats(req.user._id));
  },

  async getAdminAll(_req, res) {
    ok(res, await service.listAll());
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
    res.json({ message: 'Xóa achievement thành công' });
  },
});

export default createAchievementController;
