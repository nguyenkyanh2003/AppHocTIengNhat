import Grammar from '../../../model/Grammar.js';
import Kanji from '../../../model/Kanji.js';
import Lesson from '../../../model/Lesson.js';
import LessonProgress from '../../../model/LessonProgress.js';
import UserStreak from '../../../model/UserStreak.js';
import Vocabulary from '../../../model/Vocabulary.js';

const XP_PER_LEVEL = 100;

const toIdStrings = (ids) => (ids ?? []).map((id) => String(id));

/**
 * Nội dung bài học ưu tiên đọc từ mảng tham chiếu trong `Lesson`.
 *
 * Dữ liệu cũ có bài mà mảng tham chiếu rỗng trong khi từ vựng/ngữ pháp/kanji lại
 * trỏ ngược về bài qua khóa ngoại. Không có nhánh dự phòng này thì bài có nội
 * dung thật vẫn nhận `total` bằng 0 và tiến độ luôn hiển thị 0%.
 */
const resolveIds = async (referenced, fallback) =>
  Array.isArray(referenced) && referenced.length > 0
    ? toIdStrings(referenced)
    : toIdStrings(await fallback());

const applyTotals = (progress, totals) => {
  progress.total_vocabularies = totals.vocabularies;
  progress.total_grammars = totals.grammars;
  progress.total_kanjis = totals.kanjis;
};

/**
 * Mọi truy vấn Mongoose của domain tiến độ bài học.
 *
 * Repository trả plain object để service không cầm document Mongoose; phần logic
 * đếm nằm trong method của model (`markItemLearned` / `unmarkItemLearned`) nên
 * counter luôn bằng độ dài mảng ID.
 */
export const createLessonProgressRepository = ({
  LessonProgress: progressModel = LessonProgress,
  Lesson: lessonModel = Lesson,
  UserStreak: streakModel = UserStreak,
  Vocabulary: vocabularyModel = Vocabulary,
  Grammar: grammarModel = Grammar,
  Kanji: kanjiModel = Kanji,
} = {}) => ({
  findProgress({ userId, lessonId }) {
    return progressModel.findOne({ user: userId, lesson: lessonId }).lean();
  },

  findAllProgress(userId) {
    return progressModel
      .find({ user: userId })
      .populate('lesson', 'title level order')
      .sort({ last_studied_at: -1 })
      .lean();
  },

  findProgressForLessons({ userId, lessonIds }) {
    return progressModel
      .find({ user: userId, lesson: { $in: lessonIds } })
      .lean();
  },

  findLessonsByLevel(level) {
    return lessonModel.find({ level }).select('_id').lean();
  },

  /** ID nội dung thật của bài học; `null` khi bài không tồn tại. */
  async findLessonContent(lessonId) {
    const lesson = await lessonModel.findById(lessonId).lean();
    if (!lesson) return null;

    // Ba model dùng ba tên trường khác nhau để trỏ về bài học.
    const [vocabularyIds, grammarIds, kanjiIds] = await Promise.all([
      resolveIds(lesson.vocabularies, () =>
        vocabularyModel.distinct('_id', { lesson: lesson._id }),
      ),
      resolveIds(lesson.grammars, () =>
        grammarModel.distinct('_id', { lesson_id: lesson._id }),
      ),
      resolveIds(lesson.kanjis, () =>
        kanjiModel.distinct('_id', { lessonId: lesson._id }),
      ),
    ]);

    return { vocabularyIds, grammarIds, kanjiIds };
  },

  async startProgress({ userId, lessonId, totals, at }) {
    const existing = await progressModel.findOne({
      user: userId,
      lesson: lessonId,
    });

    if (existing) {
      applyTotals(existing, totals);
      existing.last_studied_at = at;
      await existing.save();
      return { progress: existing.toObject(), created: false };
    }

    const created = new progressModel({ user: userId, lesson: lessonId, last_studied_at: at });
    applyTotals(created, totals);
    await created.save();

    return { progress: created.toObject(), created: true };
  },

  async applyItemLearned({ userId, lessonId, totals, itemType, itemId, learned, at }) {
    const progress =
      (await progressModel.findOne({ user: userId, lesson: lessonId })) ??
      new progressModel({ user: userId, lesson: lessonId });

    applyTotals(progress, totals);
    const wasCompleted = progress.is_completed === true;

    if (learned) {
      progress.markItemLearned(itemType, itemId);
    } else {
      progress.unmarkItemLearned(itemType, itemId);
    }

    // Học nốt mục cuối cùng cũng là một lần hoàn thành bài. Ghi 'pending' ngay
    // trong lệnh này để nếu request chết trước khi cộng XP thì lần sau còn biết
    // khoản thưởng chưa được ghi nhận.
    if (!wasCompleted && progress.is_completed && !progress.completion_reward_state) {
      progress.completion_reward_state = 'pending';
    }

    progress.last_studied_at = at;
    await progress.save();

    return progress.toObject();
  },

  /**
   * Ghi trạng thái hoàn thành toàn bài một cách nhất quán: ID đã học, counter,
   * tổng số và trạng thái được đặt cùng lúc từ nội dung thật của bài.
   */
  async saveCompletion({ userId, lessonId, content, completedAt, lastStudiedAt, rewardState }) {
    const progress = await progressModel.findOne({
      user: userId,
      lesson: lessonId,
    });

    if (!progress) return null;

    progress.learned_vocabulary_ids = content.vocabularyIds;
    progress.learned_grammar_ids = content.grammarIds;
    progress.learned_kanji_ids = content.kanjiIds;
    progress.completed_vocabularies = content.vocabularyIds.length;
    progress.completed_grammars = content.grammarIds.length;
    progress.completed_kanjis = content.kanjiIds.length;
    applyTotals(progress, {
      vocabularies: content.vocabularyIds.length,
      grammars: content.grammarIds.length,
      kanjis: content.kanjiIds.length,
    });
    progress.is_completed = true;
    progress.completed_at = completedAt;
    progress.last_studied_at = lastStudiedAt;
    progress.completion_reward_state = rewardState;

    await progress.save();
    return progress.toObject();
  },

  async markCompletionRewardGranted({ userId, lessonId }) {
    await progressModel.updateOne(
      { user: userId, lesson: lessonId },
      { $set: { completion_reward_state: 'granted' } },
    );
  },

  deleteProgress({ userId, lessonId }) {
    return progressModel.findOneAndDelete({ user: userId, lesson: lessonId });
  },

  /** Ghi nhận "hôm nay có học"; không cộng XP. */
  async recordStudyActivity(userId) {
    const streak = await streakModel.findOne({ user: userId });
    if (!streak) return null;

    const result = streak.updateStreakOnActivity();
    await streak.save();

    return result;
  },

  /**
   * Cộng XP đúng một lần cho mỗi `rewardKey`.
   *
   * Điều kiện `reward_keys: { $ne: rewardKey }` và phép cộng nằm trong **một**
   * lệnh ghi, nên hai request đồng thời chỉ có một request khớp điều kiện. Ghi
   * bằng update pipeline để `level` được tính lại từ `total_xp` sau khi cộng,
   * đúng như `addXP` của model làm.
   *
   * Trả về `true` nếu lần gọi này thực sự cộng XP, `false` nếu khoản thưởng đã
   * được ghi nhận từ trước (hoặc user chưa có bản ghi streak).
   */
  async grantXpOnce({ userId, rewardKey, amount, reason }) {
    const result = await streakModel.updateOne(
      { user: userId, reward_keys: { $ne: rewardKey } },
      [
        {
          $set: {
            total_xp: { $add: [{ $ifNull: ['$total_xp', 0] }, amount] },
            reward_keys: {
              $concatArrays: [{ $ifNull: ['$reward_keys', []] }, [rewardKey]],
            },
            xp_history: {
              $concatArrays: [
                { $ifNull: ['$xp_history', []] },
                [{ amount, reason, earned_at: '$$NOW' }],
              ],
            },
          },
        },
        {
          $set: {
            level: {
              $add: [{ $floor: { $divide: ['$total_xp', XP_PER_LEVEL] } }, 1],
            },
          },
        },
      ],
    );

    return result.modifiedCount === 1;
  },

  /**
   * Đánh dấu khoản thưởng là đã ghi nhận mà **không** cộng XP.
   *
   * Dùng cho bản ghi hoàn thành từ trước khi có cơ chế khóa: chúng đã được cộng
   * XP theo cách cũ, nên chỉ cần chiếm khóa để lần sau không phát thưởng lại.
   */
  async claimRewardKeyWithoutXp({ userId, rewardKey }) {
    await streakModel.updateOne(
      { user: userId, reward_keys: { $ne: rewardKey } },
      { $push: { reward_keys: rewardKey } },
    );
  },
});

export const lessonProgressRepository = createLessonProgressRepository();

export default lessonProgressRepository;
