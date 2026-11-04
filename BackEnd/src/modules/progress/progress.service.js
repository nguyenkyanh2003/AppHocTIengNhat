import { achievementRepository } from '../achievements/achievement.repository.js';
import { lessonProgressRepository } from '../lesson-progress/lesson-progress.repository.js';
import { srsRepository } from '../srs/srs.repository.js';
import { streakReadService } from '../streaks/streak-read.service.js';
import { addDays, dayKey } from '../streaks/streak-rules.js';
import { progressRepository } from './progress.repository.js';

/** Số ngày lịch Việt Nam của mỗi kỳ, **tính cả hôm nay**. */
const PERIOD_DAYS = Object.freeze({ week: 7, month: 30, year: 365 });
const ADMIN_PERIOD_DAYS = Object.freeze({ '7d': 7, '30d': 30, '90d': 90 });

const DAY_KEY = /^\d{4}-\d{2}-\d{2}$/;

/**
 * Giờ Việt Nam lệch cố định +07:00, không có giờ mùa hè — nên nửa đêm của một
 * ngày lịch quy ra mốc UTC bằng một phép ghép chuỗi.
 */
const startOfDay = (key) => new Date(`${key}T00:00:00+07:00`);

/** Khoảng `[from, to)` phủ trọn các ngày lịch từ `fromKey` tới `toKey`. */
const dayRange = (fromKey, toKey) => ({ from: startOfDay(fromKey), to: startOfDay(addDays(toKey, 1)) });

const percent = (completed, total) => (total === 0 ? 0 : Math.round((completed / total) * 100));

/**
 * Một dòng tiến độ bài học cho client và file xuất dữ liệu.
 *
 * `lean()` không chạy virtual nên `overall_progress` tính lại ở đây, cùng công
 * thức với virtual của model. Bỏ các mảng ID đã học và trạng thái thưởng: đó là
 * chi tiết nội bộ, người học không đọc được gì từ chúng.
 */
const toLessonProgressDto = (row) => {
  const counts = {
    completed_vocabularies: row.completed_vocabularies ?? 0,
    total_vocabularies: row.total_vocabularies ?? 0,
    completed_grammars: row.completed_grammars ?? 0,
    total_grammars: row.total_grammars ?? 0,
    completed_kanjis: row.completed_kanjis ?? 0,
    total_kanjis: row.total_kanjis ?? 0,
  };
  const completed = counts.completed_vocabularies + counts.completed_grammars + counts.completed_kanjis;
  const total = counts.total_vocabularies + counts.total_grammars + counts.total_kanjis;

  return {
    _id: row._id,
    lesson: row.lesson
      ? { _id: row.lesson._id, title: row.lesson.title, level: row.lesson.level, order: row.lesson.order }
      : null,
    ...counts,
    overall_progress: percent(completed, total),
    is_completed: row.is_completed === true,
    completed_at: row.completed_at ?? null,
    last_studied_at: row.last_studied_at ?? null,
  };
};

/**
 * Ngày học trong lịch streak là khoá `YYYY-MM-DD`; user chưa migration còn mốc
 * thời gian cũ, phải quy về ngày Việt Nam thì mới ghép được với hoạt động.
 */
const toDayKey = (value) => (DAY_KEY.test(value) ? value : dayKey(new Date(value)));

/** Gom số liệu theo ngày; ngày chưa có được tạo bằng `empty()`. */
const dayBuckets = (empty) => {
  const buckets = new Map();
  return {
    at(key) {
      if (!buckets.has(key)) buckets.set(key, empty());
      return buckets.get(key);
    },
    sorted() {
      return [...buckets.entries()]
        .sort(([a], [b]) => a.localeCompare(b))
        .map(([date, bucket]) => ({ date, ...bucket }));
    },
  };
};

/**
 * Rule nghiệp vụ của thống kê học tập.
 *
 * Định nghĩa "đã học" (từ vựng = có thẻ SRS, kanji = đã đánh dấu trong bài)
 * mượn của repository huy hiệu, để số trên dashboard và tiêu chí huy hiệu không
 * bao giờ lệch nhau. `kanji_reviewing` là số thẻ Kanji đang ôn — cùng nghĩa
 * với số từ vựng trên dashboard (spec Kanji SRS §2, #8). Mọi ngày đều là ngày
 * lịch Việt Nam — cùng cách chia ngày với streak.
 */
export const createProgressService = ({
  repository = progressRepository,
  lessonProgress = lessonProgressRepository,
  counters = achievementRepository,
  streak = streakReadService,
  srs = srsRepository,
  clock = () => new Date(),
} = {}) => {
  /** Bài tập đã nộp và bài học đã học trong trọn các ngày `fromKey`..`toKey`. */
  const activityBetween = async (userId, fromKey, toKey) => {
    const range = { userId, ...dayRange(fromKey, toKey) };
    const exercises = await repository.findExerciseResultsBetween(range);
    const lessons = await repository.findLessonsStudiedBetween(range);
    return { exercises, lessons };
  };

  return {
    async listLessonProgress(userId) {
      const rows = await lessonProgress.findAllProgress(userId);
      return rows.map(toLessonProgressDto);
    },

    async dashboardStats(userId) {
      const [vocabulary, kanji, kanjiReviewing, exercises, lessons, studySeconds, summary] = await Promise.all([
        counters.countLearnedVocabulary({ userId }),
        counters.countLearnedKanji({ userId }),
        srs.countCards({ userId, itemType: 'Kanji' }),
        counters.countExerciseSubmissions({ userId }),
        counters.countCompletedLessons({ userId }),
        repository.sumExerciseSeconds(userId),
        streak.summary(userId),
      ]);

      return {
        vocabulary_learned: vocabulary,
        kanji_learned: kanji,
        kanji_reviewing: kanjiReviewing,
        exercises_completed: exercises,
        lessons_completed: lessons,
        total_study_time: studySeconds,
        current_streak: summary.current_streak,
        total_xp: summary.total_xp,
        level: summary.level,
      };
    },

    /**
     * Hoạt động theo ngày của một kỳ, chỉ gồm ngày có hoạt động.
     *
     * Ngày chỉ kiếm XP (học từ, ôn SRS) cũng là ngày có học, nên được thêm vào
     * thay vì chỉ cộng XP vào ngày đã có bài tập hoặc bài học.
     */
    async timeline(userId, period) {
      const todayKey = dayKey(clock());
      const fromKey = addDays(todayKey, -(PERIOD_DAYS[period] - 1));
      const { exercises, lessons } = await activityBetween(userId, fromKey, todayKey);
      const days = dayBuckets(() => ({ exercises: 0, lessons: 0, time: 0, xp: 0 }));

      for (const exercise of exercises) {
        const day = days.at(dayKey(exercise.completed_at));
        day.exercises += 1;
        day.time += exercise.time_spent ?? 0;
      }
      for (const lesson of lessons) {
        days.at(dayKey(lesson.last_studied_at)).lessons += 1;
      }
      for (const { amount, earned_at: earnedAt } of await streak.xpHistory(userId)) {
        const key = dayKey(new Date(earnedAt));
        if (key >= fromKey && key <= todayKey) days.at(key).xp += amount;
      }

      return days.sorted();
    },

    /**
     * Lịch hoạt động một năm. `count` là số bài tập và bài học trong ngày; ngày
     * có trong lịch streak mà không còn bản ghi chi tiết (học từ, ôn SRS, ngày
     * cũ) vẫn tính là 1 để ô không trống.
     */
    async heatmap(userId, year = Number(dayKey(clock()).slice(0, 4))) {
      const fromKey = `${year}-01-01`;
      const toKey = `${year}-12-31`;
      const { exercises, lessons } = await activityBetween(userId, fromKey, toKey);
      const days = dayBuckets(() => ({ count: 0, time: 0 }));

      for (const exercise of exercises) {
        const day = days.at(dayKey(exercise.completed_at));
        day.count += 1;
        day.time += exercise.time_spent ?? 0;
      }
      for (const lesson of lessons) {
        days.at(dayKey(lesson.last_studied_at)).count += 1;
      }
      for (const key of (await streak.activityDates(userId)).map(toDayKey)) {
        if (key < fromKey || key > toKey) continue;
        const day = days.at(key);
        day.count = Math.max(day.count, 1);
      }

      return days.sorted();
    },

    async breakdown(userId) {
      const [lessonsByLevel, exercisesByType] = await Promise.all([
        repository.lessonsByLevel(userId),
        repository.exercisesByType(userId),
      ]);

      return {
        lessons_by_level: lessonsByLevel,
        exercises_by_type: exercisesByType.map((row) => ({
          ...row,
          average_score: Math.round(row.average_score * 10) / 10,
        })),
      };
    },

    async adminAnalytics(period) {
      const days = ADMIN_PERIOD_DAYS[period];
      const todayKey = dayKey(clock());
      const fromKey = addDays(todayKey, -(days - 1));
      const labels = Array.from({ length: days }, (_, offset) => addDays(fromKey, offset));
      const since = { since: startOfDay(fromKey) };

      const [
        totalUsers,
        activeToday,
        lessonsCompleted,
        examSeconds,
        registrations,
        activeUsers,
        completedLessons,
        examMinutes,
        levels,
      ] = await Promise.all([
        repository.countUsers(),
        repository.countUsersActiveSince({ since: startOfDay(todayKey) }),
        repository.countLessonsCompletedSince(since),
        repository.sumExamSecondsSince(since),
        repository.dailyRegistrations(since),
        repository.dailyActiveUsers(since),
        repository.dailyLessonsCompleted(since),
        repository.dailyExamMinutes(since),
        repository.levelDistribution(),
      ]);

      /** Chuỗi giá trị khớp từng nhãn; ngày không có dòng nào là 0. */
      const series = (rows) => {
        const values = new Map(rows.map((row) => [row._id, row.value]));
        return labels.map((key) => values.get(key) ?? 0);
      };

      return {
        period: `${days}d`,
        labels,
        metrics: {
          total_users: totalUsers,
          active_today: activeToday,
          lessons_completed: lessonsCompleted,
          study_minutes: Math.round(examSeconds / 60),
        },
        daily_active_users: series(activeUsers),
        new_registrations: series(registrations),
        lessons_completed: series(completedLessons),
        total_study_time: series(examMinutes).map((value) => Math.round(value)),
        level_distribution: Object.fromEntries(levels.map((row) => [row._id || 'Chưa đặt', row.value])),
      };
    },
  };
};

export const progressService = createProgressService();

export default progressService;
