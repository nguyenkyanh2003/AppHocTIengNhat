import { ApiError } from '../../shared/http/api-error.js';
import { streakRepository } from '../streaks/streak.repository.js';
import { dayKey, projectStreak } from '../streaks/streak-rules.js';
import { achievementRepository } from './achievement.repository.js';
import { countedMetricsFor, isUnlocked, progressOf } from './achievement-rules.js';

/**
 * Huy hiệu: đọc tiến độ, quản trị định nghĩa, và **cổng xét huy hiệu** mà
 * `recordActivity` gọi trong transaction của hoạt động học.
 *
 * Service này không tự ghi XP hay event: phần đó thuộc cổng ghi streak, để
 * mọi XP vẫn đi qua một đường duy nhất và cùng cơ chế chống trùng.
 */

/** Cách đếm từng số đo trong DB — tên khớp với `achievement-rules.js`. */
const METRIC_COUNTERS = Object.freeze({
  learnedVocabulary: (repository, args) => repository.countLearnedVocabulary(args),
  learnedKanji: (repository, args) => repository.countLearnedKanji(args),
  learnedGrammar: (repository, args) => repository.countLearnedGrammar(args),
  completedLessons: (repository, args) => repository.countCompletedLessons(args),
  exerciseSubmissions: (repository, args) => repository.countExerciseSubmissions(args),
});

/**
 * Chuỗi ngày và tổng XP hiện tại để hiển thị tiến độ — dùng đúng phép chiếu
 * của đường đọc streak, nên chuỗi đã đứt hiện 0 thay vì con số cũ.
 */
const readStreakSnapshot = async (userId, now = new Date()) => {
  const summary = await streakRepository.findByUser({ userId });
  if (!summary) return { currentStreak: 0, totalXp: 0 };
  const { currentStreak } = projectStreak(
    {
      currentStreak: summary.current_streak ?? 0,
      lastActivityDay: summary.last_activity_day ?? null,
      freezesAvailable: summary.freezes_available ?? 0,
    },
    dayKey(now),
  );
  return { currentStreak, totalXp: summary.total_xp ?? 0 };
};

export const createAchievementService = ({
  repository = achievementRepository,
  streakSnapshot = readStreakSnapshot,
} = {}) => {
  /**
   * Đếm lần lượt, không `Promise.all`: trong transaction, các lệnh cùng một
   * session không được chạy song song.
   */
  const gatherMetrics = async ({ userId, achievements, snapshot, session }) => {
    const metrics = { ...snapshot };
    for (const metric of countedMetricsFor(achievements)) {
      metrics[metric] = await METRIC_COUNTERS[metric](repository, { userId, session });
    }
    return metrics;
  };

  const toLocked = (achievement, metrics) => ({
    achievement,
    progress: progressOf(achievement, metrics),
    is_completed: false,
    is_locked: true,
  });

  return {
    /**
     * Huy hiệu user **vừa** đạt tiêu chí mà chưa được cấp.
     *
     * `snapshot` là chuỗi ngày và tổng XP ngay sau hoạt động học, **trước**
     * mọi thưởng: xét trên snapshot này thì XP của huy hiệu vừa cấp không thể
     * kéo theo một huy hiệu XP khác trong cùng lần ghi (spec streak §3.4).
     */
    async findUnlocked({ userId, snapshot, session }) {
      const definitions = await repository.findActive({ session });
      const completed = await repository.findCompletedAchievementIds({ userId, session });
      const pending = definitions.filter((definition) => !completed.has(String(definition._id)));
      if (pending.length === 0) return [];

      const metrics = await gatherMetrics({ userId, achievements: pending, snapshot, session });
      return pending
        .filter((definition) => isUnlocked(definition, metrics))
        .map((definition) => ({
          id: String(definition._id),
          xpReward: definition.xp_reward,
          progress: progressOf(definition, metrics),
        }));
    },

    markCompleted(args) {
      return repository.markCompleted(args);
    },

    listActive() {
      return repository.findActive();
    },

    /** Huy hiệu đã có và huy hiệu còn khoá kèm tiến độ server tự đếm. */
    async myAchievements(userId) {
      const [definitions, earned, snapshot] = await Promise.all([
        repository.findActive(),
        repository.findUserAchievements({ userId }),
        streakSnapshot(userId),
      ]);
      const earnedIds = new Set(earned.map((row) => String(row.achievement._id)));
      const locked = definitions.filter((definition) => !earnedIds.has(String(definition._id)));
      const metrics = await gatherMetrics({ userId, achievements: locked, snapshot });

      return {
        earned,
        locked: locked.map((definition) => toLocked(definition, metrics)),
        total: definitions.length,
        completed: earned.filter((row) => row.is_completed).length,
      };
    },

    async byCategory(userId, category) {
      const achievements = await repository.findActiveByCategory(category);
      const userProgress = await repository.findUserAchievements({
        userId,
        achievementIds: achievements.map((achievement) => achievement._id),
      });
      return { achievements, user_progress: userProgress };
    },

    async stats(userId) {
      const [total, completed, byCategory, earnedByCategory] = await Promise.all([
        repository.countActive(),
        repository.findCompletedAchievementIds({ userId }),
        repository.countActiveByCategory(),
        repository.countCompletedByCategory(userId),
      ]);
      return {
        total_achievements: total,
        earned_achievements: completed.size,
        completion_rate: total > 0 ? ((completed.size / total) * 100).toFixed(1) : 0,
        by_category: byCategory,
        earned_by_category: earnedByCategory,
      };
    },

    listAll() {
      return repository.findAll();
    },

    create(payload) {
      return repository.create(payload);
    },

    async update(id, updates) {
      const updated = await repository.updateById(id, updates);
      if (!updated) throw ApiError.notFound('Achievement không tồn tại');
      return updated;
    },

    async remove(id) {
      const deleted = await repository.deleteById(id);
      if (!deleted) throw ApiError.notFound('Achievement không tồn tại');
    },
  };
};

export const achievementService = createAchievementService();

export default achievementService;
