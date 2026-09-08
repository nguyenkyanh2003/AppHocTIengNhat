import { ApiError } from '../../shared/http/api-error.js';
import { getVietnamTime } from '../../shared/utils/timezone.js';
import { lessonProgressRepository } from './lesson-progress.repository.js';

const START_XP = 3;
const ITEM_XP = 2;
const COMPLETION_XP = 20;
const COMPLETION_REASON = 'Hoàn thành bài học';

const startRewardKey = (lessonId) => `lesson-start:${lessonId}`;
const completionRewardKey = (lessonId) => `lesson-complete:${lessonId}`;
const itemRewardKey = ({ lessonId, itemType, itemId }) =>
  `lesson-item:${lessonId}:${itemType}:${itemId}`;

const totalsOf = (content) => ({
  vocabularies: content.vocabularyIds.length,
  grammars: content.grammarIds.length,
  kanjis: content.kanjiIds.length,
});

const contentIdsFor = (content, itemType) => {
  if (itemType === 'vocabulary') return content.vocabularyIds;
  if (itemType === 'grammar') return content.grammarIds;
  return content.kanjiIds;
};

/**
 * Trạng thái thưởng suy ra từ ảnh chụp **trước** khi ghi.
 *
 * Bản ghi không có `completion_reward_state` mà đã `is_completed` là bản ghi
 * hoàn thành theo cơ chế cũ: nó đã được cộng XP một lần rồi, nên chỉ chiếm khóa
 * chứ không phát thưởng hồi tố.
 */
const rewardStateBefore = (progress) => {
  if (progress?.completion_reward_state) return progress.completion_reward_state;
  return progress?.is_completed ? 'granted' : 'pending';
};

/**
 * Rule nghiệp vụ của tiến độ bài học.
 *
 * Repository nhận qua tham số nên test chỉ cần một repository giả; không test
 * nào chạm MongoDB.
 */
export const createLessonProgressService = ({
  repository = lessonProgressRepository,
  now = getVietnamTime,
} = {}) => {
  /** Nội dung thật của bài, dùng chung cho start, update và complete. */
  const requireContent = async (lessonId) => {
    const content = await repository.findLessonContent(lessonId);
    if (!content) throw ApiError.notFound('Không tìm thấy bài học');
    return content;
  };

  /**
   * Chốt khoản thưởng hoàn thành bài. Dùng chung cho cả hai đường dẫn tới trạng
   * thái hoàn thành: bấm "hoàn thành toàn bài" và học nốt mục cuối cùng.
   */
  const settleCompletionReward = async ({ userId, lessonId, beforeState, becameCompleted }) => {
    const rewardKey = completionRewardKey(lessonId);

    // Đã ghi nhận xong: khóa thưởng đã tồn tại, không còn việc gì để làm.
    if (beforeState === 'granted') return;

    if (beforeState === 'pending' || becameCompleted) {
      await repository.grantXpOnce({
        userId,
        rewardKey,
        amount: COMPLETION_XP,
        reason: COMPLETION_REASON,
      });
      await repository.markCompletionRewardGranted({ userId, lessonId });
      return;
    }

    await repository.claimRewardKeyWithoutXp({ userId, rewardKey });
    await repository.markCompletionRewardGranted({ userId, lessonId });
  };

  return {
    getProgress({ userId, lessonId }) {
      return repository.findProgress({ userId, lessonId });
    },

    listProgress(userId) {
      return repository.findAllProgress(userId);
    },

    async startLesson({ userId, lessonId }) {
      const content = await requireContent(lessonId);

      const { progress, created } = await repository.startProgress({
        userId,
        lessonId,
        totals: totalsOf(content),
        at: now(),
      });

      if (created) {
        await repository.recordStudyActivity(userId);
        // Khóa theo bài: reset rồi bắt đầu lại không cộng thêm XP mở bài.
        await repository.grantXpOnce({
          userId,
          rewardKey: startRewardKey(lessonId),
          amount: START_XP,
          reason: 'Bắt đầu học bài',
        });
      }

      return progress;
    },

    async updateItem({ userId, lessonId, itemType, itemId, completed }) {
      const content = await requireContent(lessonId);

      if (!contentIdsFor(content, itemType).includes(String(itemId))) {
        throw ApiError.badRequest('Mục học không thuộc bài học này.');
      }

      const before = await repository.findProgress({ userId, lessonId });

      const progress = await repository.applyItemLearned({
        userId,
        lessonId,
        totals: totalsOf(content),
        itemType,
        itemId,
        learned: completed,
        at: now(),
      });

      if (completed) {
        await repository.recordStudyActivity(userId);
        // Khóa theo từng mục: đánh dấu lại mục cũ, hoặc gỡ rồi đánh dấu lại,
        // đều không cộng thêm XP.
        await repository.grantXpOnce({
          userId,
          rewardKey: itemRewardKey({ lessonId, itemType, itemId }),
          amount: ITEM_XP,
          reason: `Học ${itemType}`,
        });
      }

      if (!progress.is_completed) return progress;

      await settleCompletionReward({
        userId,
        lessonId,
        beforeState: before?.completion_reward_state,
        becameCompleted: before?.is_completed !== true,
      });

      return { ...progress, completion_reward_state: 'granted' };
    },

    /**
     * Nút "hoàn thành toàn bài" là xác nhận của người học rằng đã học hết nội
     * dung hiện có, nên ID đã học, counter, tổng số và trạng thái được ghi cùng
     * lúc từ nội dung thật. Bản cũ chỉ đặt `is_completed = true`, khiến tiến độ
     * vẫn hiển thị 0% ngay sau khi báo hoàn thành.
     */
    async completeLesson({ userId, lessonId }) {
      const before = await repository.findProgress({ userId, lessonId });
      if (!before) throw ApiError.notFound('Không tìm thấy tiến độ');

      const content = await requireContent(lessonId);
      const at = now();
      const beforeState = rewardStateBefore(before);

      const progress = await repository.saveCompletion({
        userId,
        lessonId,
        content,
        // Giữ nguyên mốc hoàn thành đã có, chỉ đặt mốc mới cho lần đầu.
        completedAt: before.completed_at ?? at,
        lastStudiedAt: at,
        rewardState: beforeState,
      });

      if (!progress) throw ApiError.notFound('Không tìm thấy tiến độ');

      await repository.recordStudyActivity(userId);
      await settleCompletionReward({
        userId,
        lessonId,
        beforeState: before.completion_reward_state,
        becameCompleted: before.is_completed !== true,
      });

      return { ...progress, completion_reward_state: 'granted' };
    },

    async resetLesson({ userId, lessonId }) {
      await repository.deleteProgress({ userId, lessonId });
      return { message: 'Đã reset tiến độ' };
    },

    async getStats(userId) {
      const allProgress = await repository.findAllProgress(userId);

      return {
        total_lessons: allProgress.length,
        completed_lessons: allProgress.filter((p) => p.is_completed).length,
        in_progress_lessons: allProgress.filter((p) => !p.is_completed).length,
        total_vocabularies_learned: allProgress.reduce((sum, p) => sum + p.completed_vocabularies, 0),
        total_grammars_learned: allProgress.reduce((sum, p) => sum + p.completed_grammars, 0),
        total_kanjis_learned: allProgress.reduce((sum, p) => sum + p.completed_kanjis, 0),
      };
    },

    async getLevelStats({ userId, level }) {
      const lessons = await repository.findLessonsByLevel(level);
      const lessonIds = lessons.map((lesson) => lesson._id);

      const progressList = await repository.findProgressForLessons({
        userId,
        lessonIds,
      });

      const completed = progressList.filter((p) => p.is_completed).length;

      return {
        level,
        total_lessons: lessons.length,
        started_lessons: progressList.length,
        completed_lessons: completed,
        progress_percentage:
          lessons.length > 0 ? Math.round((completed / lessons.length) * 100) : 0,
      };
    },
  };
};

export const lessonProgressService = createLessonProgressService();

export default lessonProgressService;
