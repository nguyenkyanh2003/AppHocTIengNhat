import { created, list, ok, paginated } from '../../shared/http/respond.js';
import { lessonService } from './lesson.service.js';

/** Chỉ map HTTP <-> service. */
export const createLessonController = (service) => ({
  async listRoot(req, res) {
    return paginated(res, await service.list(req.valid.query));
  },

  async getById(req, res) {
    return ok(res, await service.getDetail(req.valid.params.id));
  },

  async getSituations(req, res) {
    return list(res, await service.listSituations(req.valid.query));
  },

  async getStatsOverview(_req, res) {
    return ok(res, await service.getStatsOverview());
  },

  async postRoot(req, res) {
    const lesson = await service.create(req.valid.body);
    return created(res, lesson, { message: 'Thêm bài học thành công.' });
  },

  async putById(req, res) {
    const lesson = await service.update(req.valid.params.id, req.valid.body);
    return ok(res, lesson, { message: 'Cập nhật bài học thành công.' });
  },

  async deleteById(req, res) {
    await service.remove(req.valid.params.id);
    return ok(res, { deleted: true }, { message: 'Xóa bài học thành công.' });
  },
});

export const lessonController = createLessonController(lessonService);

export default lessonController;
