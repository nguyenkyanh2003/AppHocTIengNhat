import { unitOfWork as defaultUnitOfWork } from '../../shared/db/unit-of-work.js';
import { ApiError } from '../../shared/http/api-error.js';
import { streakService } from '../streaks/streak.service.js';
import { toSrsProgressDto } from './srs.dto.js';
import { srsRepository } from './srs.repository.js';
import { applyAnswer, initialProgress, MAX_BOX, MIN_BOX } from './srs-scheduling.js';

/**
 * Vòng ôn tập SRS: lấy đợt thẻ đến hạn, trả lời, đặt lại lịch, xoá tiến độ.
 *
 * Service không tự tính lịch (mọi luật nằm ở `srs-scheduling.js`) và không tự
 * cấp XP (mọi XP đi qua `recordActivity`). Đồng hồ nhận qua tham số để test
 * kiểm được đúng mốc `next_review - 1ms`, bằng hạn và sau hạn.
 */

/** Ném trong transaction để rollback khi thua CAS; phân loại sau khi đã thoát ra. */
class ScheduleChanged extends Error {}

const notFound = () => ApiError.notFound('Không tìm thấy tiến độ ôn tập của từ này.');

const conflict = (code, message, progress) =>
  ApiError.conflict(message, { code, details: { current_progress: toSrsProgressDto(progress) } });

const notDue = (progress) =>
  conflict('SRS_NOT_DUE', 'Thẻ này chưa đến hạn ôn.', progress);

const changed = (progress) =>
  conflict('SRS_PROGRESS_CHANGED', 'Lịch ôn của thẻ đã thay đổi. Hãy tải lại thẻ.', progress);

const sameInstant = (a, b) => new Date(a).getTime() === new Date(b).getTime();

export const createSrsService = ({
  repository = srsRepository,
  streak = streakService,
  unitOfWork = defaultUnitOfWork,
  clock = () => new Date(),
} = {}) => {
  /**
   * Đọc **mới** (không dùng session của transaction đã rollback) rồi nói rõ
   * vì sao lượt ghi thua: thẻ đã mất, chưa đến hạn, hay vẫn đến hạn nhưng đã
   * đổi trạng thái. Không kết luận mọi `null` đều là "chưa đến hạn" (spec §3.5).
   */
  const explainLostWrite = async ({ userId, itemId, itemType, now, requireDue }) => {
    const current = await repository.findProgress({ userId, itemId, itemType });
    if (!current) throw notFound();
    if (requireDue && new Date(current.next_review) > now) throw notDue(current);
    throw changed(current);
  };

  return {
    /**
     * Một đợt thẻ đến hạn kèm nội dung để vẽ hai mặt.
     *
     * Thẻ mà nội dung đã bị xoá vẫn được trả về với `item: null, unavailable:
     * true` để người học chọn bỏ qua hoặc xoá — GET không âm thầm xoá gì.
     */
    async dueBatch({ userId, itemType, limit, excludeItemIds = [] }) {
      const progresses = await repository.findDueBatch({
        userId,
        itemType,
        now: clock(),
        excludeItemIds,
        limit,
      });
      const contents = await repository.findContentByIds({
        itemType,
        ids: progresses.map((progress) => progress.item_id),
      });
      const contentById = new Map(contents.map((item) => [String(item._id), item]));

      const cards = progresses.map((progress) => {
        const item = contentById.get(String(progress.item_id)) ?? null;
        return { ...toSrsProgressDto(progress), item, unavailable: item === null };
      });
      return { cards, limit };
    },

    /** Tổng thẻ đến hạn của user — độc lập với đợt đang ôn và tập loại trừ. */
    async dueCount({ userId, itemType }) {
      return { item_type: itemType, total: await repository.countDue({ userId, itemType, now: clock() }) };
    },

    async stats({ userId, itemType }) {
      const [rows, dueCount] = await Promise.all([
        repository.countByBox({ userId, itemType }),
        repository.countDue({ userId, itemType, now: clock() }),
      ]);

      // Đủ khoá "1".."5" kể cả hộp trống, để client không phải đoán hộp vắng.
      const byBox = {};
      for (let box = MIN_BOX; box <= MAX_BOX; box += 1) byBox[String(box)] = 0;
      for (const { _id: box, count } of rows) {
        if (String(box) in byBox) byBox[String(box)] = count;
      }

      return {
        item_type: itemType,
        total_cards: Object.values(byBox).reduce((sum, count) => sum + count, 0),
        due_count: dueCount,
        by_box: byBox,
      };
    },

    /**
     * Một lượt ôn: đọc → kiểm → tính lịch → CAS → ghi hoạt động, trong **một**
     * transaction. Lỗi ghi event/XP/ngày rollback luôn lịch ôn.
     *
     * Khoá hoạt động là thẻ ghép hạn ôn của đúng lượt vừa thắng CAS: ID thẻ
     * một mình không định danh được lượt, vì một thẻ được ôn nhiều lần trong
     * đời nó (spec streak §3.3).
     */
    async review({ userId, itemId, itemType, isCorrect, expectedNextReview }) {
      const now = clock();

      try {
        return await unitOfWork.run(async ({ session }) => {
          const progress = await repository.findProgress({ userId, itemId, itemType, session });
          if (!progress) throw notFound();
          if (new Date(progress.next_review) > now) throw notDue(progress);
          if (!sameInstant(progress.next_review, expectedNextReview)) throw changed(progress);

          if (!(await repository.contentExists({ itemType, itemId, session }))) {
            throw conflict('ITEM_UNAVAILABLE', 'Nội dung của thẻ này không còn tồn tại.', progress);
          }

          const saved = await repository.compareAndSet({
            progress,
            expectedNextReview,
            dueBy: now,
            next: applyAnswer(progress, isCorrect, now),
            session,
          });
          if (!saved) throw new ScheduleChanged();

          const recorded = await streak.recordActivity(
            {
              userId,
              type: 'srs.review',
              sourceId: String(progress._id),
              occurrenceKey: `srs:${progress._id}:${new Date(expectedNextReview).toISOString()}`,
              context: { outcome: { remembered: isCorrect } },
            },
            { session, now },
          );
          // Lượt này đã được ghi ở một request khác: bỏ lịch vừa tính.
          if (recorded.duplicate) throw new ScheduleChanged();

          return toSrsProgressDto(saved);
        });
      } catch (error) {
        if (!(error instanceof ScheduleChanged)) throw error;
        return explainLostWrite({ userId, itemId, itemType, now, requireDue: true });
      }
    },

    /**
     * Đặt lại lịch về hộp 1, hẹn sau 24 giờ — được phép cả khi chưa đến hạn.
     *
     * Không phải một lượt ôn: không XP, không ngày học. Vẫn so khớp lịch đang
     * thấy, để một reset cũ gửi lại muộn không đẩy lịch ra sau lần nữa.
     */
    async reset({ userId, itemId, itemType, expectedNextReview }) {
      const now = clock();
      const progress = await repository.findProgress({ userId, itemId, itemType });
      if (!progress) throw notFound();
      if (!sameInstant(progress.next_review, expectedNextReview)) throw changed(progress);

      const saved = await repository.compareAndSet({
        progress,
        expectedNextReview,
        next: initialProgress(now),
      });
      if (!saved) return explainLostWrite({ userId, itemId, itemType, now, requireDue: false });

      return toSrsProgressDto(saved);
    },

    /** Xoá tiến độ, tức bỏ dấu đã học của từ. Xoá lần nữa trả `deleted: false`. */
    async remove({ userId, itemId, itemType }) {
      const deleted = await repository.deleteProgress({ userId, itemId, itemType });
      return { deleted: deleted > 0 };
    },
  };
};

export const srsService = createSrsService();

export default srsService;
