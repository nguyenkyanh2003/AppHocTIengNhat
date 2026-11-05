import Kanji from '../../../model/Kanji.js';
import LearningGoal from '../../../model/LearningGoal.js';
import Lesson from '../../../model/Lesson.js';

/**
 * Mọi truy vấn Mongoose của mục tiêu học tập. Thao tác trên một mục tiêu luôn
 * kèm `user` trong điều kiện, nên không bao giờ chạm mục tiêu của người khác.
 *
 * Ghi hoàn thành và sửa số cần đạt có thể chạy song song (một hoạt động học và
 * một request sửa), nên điều kiện đúng/sai nằm **trong** bộ lọc của lệnh ghi —
 * kiểm tra ở service rồi mới ghi là đã quá muộn.
 */
export const createGoalRepository = ({ LearningGoal: model, Lesson: lessonModel, Kanji: kanjiModel }) => ({
  findByUser(userId) {
    return model.find({ user: userId }).sort({ createdAt: -1, _id: -1 }).lean();
  },

  /** Mục tiêu chưa hoàn thành — đọc trong transaction của hoạt động học. */
  findIncomplete({ userId, session }) {
    return model.find({ user: userId, completed_at: null }).session(session).lean();
  },

  findOwned({ id, userId }) {
    return model.findOne({ _id: id, user: userId }).lean();
  },

  async create(doc) {
    const created = await model.create(doc);
    return created.toObject();
  },

  /** [onlyIfIncomplete]: chỉ khớp khi chưa hoàn thành (dùng khi đổi số cần đạt). */
  updateOwned({ id, userId, set, onlyIfIncomplete = false }) {
    const filter = { _id: id, user: userId, ...(onlyIfIncomplete ? { completed_at: null } : {}) };
    return model.findOneAndUpdate(filter, { $set: set }, { new: true, runValidators: true }).lean();
  },

  /**
   * Ghi thời điểm hoàn thành lần đầu. Chỉ khớp khi chưa hoàn thành **và** số
   * cần đạt vẫn là [target] vừa đọc — bị sửa giữa chừng thì không ghi. `true`
   * khi đã ghi.
   */
  async markCompleted({ id, userId, target, at, session }) {
    const result = await model.updateOne(
      { _id: id, user: userId, completed_at: null, target },
      { $set: { completed_at: at } },
      { session },
    );
    return result.modifiedCount === 1;
  },

  async deleteOwned({ id, userId }) {
    const result = await model.deleteOne({ _id: id, user: userId });
    return result.deletedCount;
  },

  /**
   * Nội dung hiện có để đạt mục tiêu: tổng số bài, và số chữ Kanji khác nhau
   * thuộc bài học (mảng `Lesson.kanjis`, hoặc khoá cũ `Kanji.lessonId`) — Kanji
   * chỉ tính là đã học khi bấm "Đã nhớ" trong bài.
   */
  async countAvailable() {
    const lessons = await lessonModel.countDocuments({});
    const inLessons = await lessonModel.distinct('kanjis', {});
    const byLegacyKey = await kanjiModel.distinct('_id', { lessonId: { $ne: null } });
    return { lessons, kanji: new Set([...inLessons, ...byLegacyKey].map(String)).size };
  },
});

export const goalRepository = createGoalRepository({ LearningGoal, Lesson, Kanji });
