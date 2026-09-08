import { convertDatesToVietnam } from '../../shared/utils/timezone.js';

/**
 * Controller tiến độ bài học: chỉ map HTTP <-> service.
 *
 * Vỏ response giữ nguyên như bản cũ (trả thẳng document tiến độ, không bọc
 * `{ data }`) vì Flutter đang đọc trực tiếp `completed_*` / `total_*` để tự
 * tính phần trăm.
 */
export const createLessonProgressController = (service) => ({
  async getByLessonId(req, res) {
    const progress = await service.getProgress({
      userId: req.user._id,
      lessonId: req.valid.params.lessonId,
    });

    return res.json(progress ? convertDatesToVietnam(progress) : null);
  },

  async list(req, res) {
    const progressList = await service.listProgress(req.user._id);
    return res.json(convertDatesToVietnam(progressList));
  },

  async start(req, res) {
    const progress = await service.startLesson({
      userId: req.user._id,
      lessonId: req.valid.params.lessonId,
    });

    return res.json(convertDatesToVietnam(progress));
  },

  async update(req, res) {
    const progress = await service.updateItem({
      userId: req.user._id,
      lessonId: req.valid.params.lessonId,
      itemType: req.valid.body.item_type,
      itemId: req.valid.body.item_id,
      completed: req.valid.body.completed,
    });

    return res.json(convertDatesToVietnam(progress));
  },

  async complete(req, res) {
    const progress = await service.completeLesson({
      userId: req.user._id,
      lessonId: req.valid.params.lessonId,
    });

    return res.json(convertDatesToVietnam(progress));
  },

  async reset(req, res) {
    const result = await service.resetLesson({
      userId: req.user._id,
      lessonId: req.valid.params.lessonId,
    });

    return res.json(result);
  },

  async stats(req, res) {
    return res.json(await service.getStats(req.user._id));
  },

  async levelStats(req, res) {
    const stats = await service.getLevelStats({
      userId: req.user._id,
      level: req.valid.params.level,
    });

    return res.json(stats);
  },
});

export default createLessonProgressController;
