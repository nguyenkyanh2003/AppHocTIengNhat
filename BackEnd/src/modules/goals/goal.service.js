import { achievementRepository } from '../achievements/achievement.repository.js';
import { ApiError } from '../../shared/http/api-error.js';
import { goalRepository } from './goal.repository.js';

/** Bộ đếm "đã học" của từng loại — đúng bộ dashboard và huy hiệu đang dùng. */
const COUNTER_OF = Object.freeze({
  lessons: 'countCompletedLessons',
  vocabulary: 'countLearnedVocabulary',
  kanji: 'countLearnedKanji',
});

const UNIT_OF = Object.freeze({ lessons: 'bài học', vocabulary: 'từ vựng', kanji: 'chữ Kanji' });

const toGoalDto = (goal, current) => ({
  id: String(goal._id),
  type: goal.type,
  title: goal.title,
  target: goal.target,
  current,
  is_completed: goal.completed_at !== null && goal.completed_at !== undefined,
  completed_at: goal.completed_at ? new Date(goal.completed_at).toISOString() : null,
  deadline: goal.deadline ?? null,
  created_at: new Date(goal.createdAt).toISOString(),
});

const notFound = () => ApiError.notFound('Không tìm thấy mục tiêu.');

const alreadyCompleted = () =>
  ApiError.badRequest('Mục tiêu đã hoàn thành, không đổi số cần đạt được.', { code: 'GOAL_COMPLETED' });

/**
 * Mục tiêu học tập tích luỹ. Tiến độ là số đã học **tính đến hiện tại**, kể cả
 * trước khi tạo mục tiêu — "Đã nhớ" trong bài không lưu thời điểm từng chữ nên
 * không đếm "từ ngày tạo" được. Vì vậy số cần đạt phải lớn hơn số đang có, và
 * lần đầu đạt được ghi lại để mục tiêu không rớt khi số giảm (gỡ thẻ ôn).
 *
 * Thời điểm hoàn thành được ghi **ngay lúc học** đạt mốc ([recordReached], gọi
 * từ đường ghi hoạt động học), không đợi người học mở màn mục tiêu.
 */
export const createGoalService = ({
  goalRepository: repository,
  counters,
  clock = () => new Date(),
}) => {
  const countOf = (type, userId, session) => counters[COUNTER_OF[type]]({ userId, session });

  const countsFor = async (userId) => {
    const [lessons, vocabulary, kanji] = await Promise.all(
      ['lessons', 'vocabulary', 'kanji'].map((type) => countOf(type, userId)),
    );
    return { lessons, vocabulary, kanji };
  };

  const requireAboveCurrent = (target, current, type) => {
    if (target > current) return;
    throw ApiError.badRequest(
      `Bạn đã có ${current} ${UNIT_OF[type]}; số cần đạt phải lớn hơn ${current}.`,
      { code: 'GOAL_TARGET_REACHED', details: { current } },
    );
  };

  return {
    /**
     * Mục tiêu mới nhất trước, kèm số đã học hiện tại (`counts`) và nội dung
     * hiện có (`available`) cho form tạo.
     *
     * Vẫn ghi hoàn thành cho mục tiêu đã đủ số mà chưa được ghi — lưới an toàn
     * cho số đã học tăng ngoài ứng dụng (script nạp dữ liệu, sửa tay database),
     * nơi không có đường học nào gọi [recordReached].
     */
    async list(userId) {
      const [goals, counts, available] = await Promise.all([
        repository.findByUser(userId),
        countsFor(userId),
        repository.countAvailable(),
      ]);
      const at = clock();
      const latest = [];
      for (const goal of goals) {
        if (goal.completed_at || counts[goal.type] < goal.target) {
          latest.push(goal);
        } else if (await repository.markCompleted({ id: goal._id, userId, target: goal.target, at })) {
          latest.push({ ...goal, completed_at: at });
        } else {
          // Bị sửa hoặc xoá giữa lúc đọc và lúc ghi: lấy bản mới nhất.
          const fresh = await repository.findOwned({ id: goal._id, userId });
          if (fresh) latest.push(fresh);
        }
      }
      return { goals: latest.map((goal) => toGoalDto(goal, counts[goal.type])), counts, available };
    },

    /**
     * Ghi hoàn thành cho mục tiêu vừa đủ số, trong transaction của hoạt động
     * học ([session]). Chỉ đếm những loại có mục tiêu đang chờ; trả ID các mục
     * tiêu vừa ghi.
     */
    async recordReached({ userId, at = clock(), session } = {}) {
      const goals = await repository.findIncomplete({ userId, session });
      if (goals.length === 0) return [];

      // Lần lượt, không song song: driver MongoDB khuyên tránh chạy song song trong transaction.
      const counts = {};
      for (const type of new Set(goals.map((goal) => goal.type))) {
        counts[type] = await countOf(type, userId, session);
      }

      const completed = [];
      for (const goal of goals) {
        if (counts[goal.type] < goal.target) continue;
        if (await repository.markCompleted({ id: goal._id, userId, target: goal.target, at, session })) {
          completed.push(String(goal._id));
        }
      }
      return completed;
    },

    async create({ userId, type, target, title, deadline = null }) {
      const current = await countOf(type, userId);
      requireAboveCurrent(target, current, type);
      const goal = await repository.create({
        user: userId,
        type,
        target,
        title: title || `Đạt ${target} ${UNIT_OF[type]}`,
        deadline,
      });
      return toGoalDto(goal, current);
    },

    /** Đổi tên và hạn lúc nào cũng được; số cần đạt chỉ đổi khi chưa hoàn thành. */
    async update({ id, userId, changes }) {
      const goal = await repository.findOwned({ id, userId });
      if (!goal) throw notFound();
      const current = await countOf(goal.type, userId);

      const changesTarget = changes.target !== undefined;
      if (changesTarget) {
        if (goal.completed_at) throw alreadyCompleted();
        requireAboveCurrent(changes.target, current, goal.type);
      }

      // Đổi số cần đạt chỉ khớp khi vẫn chưa hoàn thành ngay lúc ghi: một hoạt
      // động học có thể vừa ghi hoàn thành sau khi đọc ở trên.
      const updated = await repository.updateOwned({ id, userId, set: changes, onlyIfIncomplete: changesTarget });
      if (!updated) {
        const latest = await repository.findOwned({ id, userId });
        throw latest?.completed_at ? alreadyCompleted() : notFound();
      }
      return toGoalDto(updated, current);
    },

    async remove({ id, userId }) {
      const deleted = await repository.deleteOwned({ id, userId });
      if (deleted === 0) throw notFound();
    },
  };
};

export const goalService = createGoalService({ goalRepository, counters: achievementRepository });
