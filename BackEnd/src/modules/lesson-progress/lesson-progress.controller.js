import { list, ok } from '../../shared/http/respond.js';

/** Controller tiến độ bài học: chỉ map HTTP <-> service. Người học lấy từ `req.user`. */
export const createLessonProgressController = (service) => {
  const key = (req) => ({ userId: req.user._id, lessonId: req.valid.params.lessonId });

  return {
    /** Chưa bắt đầu bài thì `data` là `null`, không phải 404. */
    async getByLessonId(req, res) {
      return ok(res, await service.getProgress(key(req)));
    },

    async list(req, res) {
      return list(res, await service.listProgress(req.user._id));
    },

    async start(req, res) {
      return ok(res, await service.startLesson(key(req)));
    },

    async update(req, res) {
      const { item_type: itemType, item_id: itemId, completed } = req.valid.body;
      return ok(res, await service.updateItem({ ...key(req), itemType, itemId, completed }));
    },

    async complete(req, res) {
      return ok(res, await service.completeLesson(key(req)));
    },

    async reset(req, res) {
      const { message } = await service.resetLesson(key(req));
      return ok(res, { reset: true }, { message });
    },
  };
};

export default createLessonProgressController;
