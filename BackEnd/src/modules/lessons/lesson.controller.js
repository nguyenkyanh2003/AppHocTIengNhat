import { created, list, ok } from '../../shared/http/respond.js';
import { lessonService } from './lesson.service.js';

/**
 * Chỉ map HTTP <-> service. Vỏ response của `listRoot`/`getById`/
 * `getStatsOverview`/`deleteRoot` KHÔNG dùng helper chuẩn `ok`/`list`/`paginated`
 * vì phải giữ đúng hình dạng cũ cho Flutter.
 */
export const createLessonController = (service) => ({
  async listRoot(req, res) {
    const { total, items, totalPages } = await service.list(req.valid.query);
    return res.json({
      totalItems: total,
      totalPages,
      currentPage: req.valid.query.page,
      data: items,
    });
  },

  async getById(req, res) {
    const lesson = await service.getDetail(req.valid.params.id);
    return res.json(lesson);
  },

  async getLevelByCapDo(req, res) {
    const lessons = await service.getByLevel(req.valid.params.capDo);
    return list(res, lessons);
  },

  async getTypeByLoaiBaiHoc(req, res) {
    const lessons = await service.getByType(req.valid.params.loaiBaiHoc);
    return list(res, lessons);
  },

  async getStatsOverview(req, res) {
    const stats = await service.getStatsOverview();
    return res.json(stats);
  },

  async postRoot(req, res) {
    const lesson = await service.create(req.valid.body);
    return created(res, lesson, { message: 'Thêm bài học thành công.' });
  },

  async postBulk(req, res) {
    const lessons = await service.createMany(req.valid.body.lessons);
    return created(res, lessons, {
      message: `Thêm thành công ${lessons.length} bài học.`,
    });
  },

  async putById(req, res) {
    const lesson = await service.update(req.valid.params.id, req.valid.body);
    return ok(res, lesson, { message: 'Cập nhật bài học thành công.' });
  },

  async deleteById(req, res) {
    const lesson = await service.remove(req.valid.params.id);
    return ok(res, lesson, { message: 'Xóa bài học thành công.' });
  },

  async deleteRoot(req, res) {
    const deletedCount = await service.removeMany(req.valid.body.ids);
    return res.json({
      message: `Xóa thành công ${deletedCount} bài học.`,
      deletedCount,
    });
  },

  async postByIdDuplicate(req, res) {
    const lesson = await service.duplicate(req.valid.params.id);
    return created(res, lesson, { message: 'Sao chép bài học thành công.' });
  },
});

export const lessonController = createLessonController(lessonService);

export default lessonController;
