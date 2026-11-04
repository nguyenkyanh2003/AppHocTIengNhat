import { ApiError } from '../../shared/http/api-error.js';
import { toSrsProgressDto } from '../srs/srs.dto.js';
import { srsRepository } from '../srs/srs.repository.js';
import { initialProgress } from '../srs/srs-scheduling.js';
import { kanjiRepository } from './kanji.repository.js';

const ITEM_TYPE = 'Kanji';

const kanjiNotFound = () => ApiError.notFound('Không tìm thấy Kanji.');

/**
 * Kanji trong lịch ôn (spec Kanji SRS §2).
 *
 * Thêm vào ôn tập chỉ tạo thẻ: không cộng XP, không đụng tiến độ bài học —
 * XP đến từ các lượt ôn sau đó, như thẻ từ vựng. Thẻ đi qua `srsRepository`
 * để hình dạng dữ liệu SRS chỉ được biết ở một chỗ.
 */
export const createKanjiService = ({
  repository = kanjiRepository,
  srs = srsRepository,
  clock = () => new Date(),
} = {}) => ({
  /** Chi tiết một chữ kèm tiến độ ôn của user đang xem, `null` khi chưa thêm. */
  async getDetail({ id, userId }) {
    const kanji = await repository.findById(id);
    if (!kanji) throw kanjiNotFound();

    const progress = await srs.findProgress({ userId, itemId: id, itemType: ITEM_TYPE });
    return { ...kanji, srs_progress: progress ? toSrsProgressDto(progress) : null };
  },

  /** Tạo thẻ hộp 1, hoặc trả thẻ đã có mà **không** đổi lịch. Bấm hai lần vẫn một thẻ. */
  async markLearned({ id, userId }) {
    if (!(await repository.findById(id))) throw kanjiNotFound();

    const { progress, created } = await srs.ensureProgress({
      userId,
      itemId: id,
      itemType: ITEM_TYPE,
      initial: initialProgress(clock()),
    });
    return { progress: toSrsProgressDto(progress), created };
  },

  async unmarkLearned({ id, userId }) {
    const deleted = await srs.deleteProgress({ userId, itemId: id, itemType: ITEM_TYPE });
    if (deleted === 0) throw ApiError.notFound('Chữ Kanji này chưa có trong lịch ôn.');
  },

  /**
   * Xoá một chữ. Còn ai đang ôn nó thì chặn: xoá đi sẽ biến thẻ của người học
   * thành thẻ mồ côi không trả lời được. Chữ còn nằm trong bài học cũng chặn:
   * bài vẫn đếm ID đó vào tổng số chữ nên không bao giờ học đủ được.
   */
  async remove(id) {
    if (await srs.hasCardsForItem({ itemType: ITEM_TYPE, itemId: id })) {
      throw ApiError.conflict('Không thể xoá Kanji này vì vẫn còn người học đang ôn tập nó.', {
        code: 'KANJI_IN_REVIEW',
      });
    }
    const lessons = await repository.findLessonsUsing(id);
    if (lessons.length > 0) {
      throw ApiError.conflict('Không thể xoá Kanji này vì chữ đang thuộc bài học.', {
        code: 'KANJI_IN_LESSON',
        details: { lessons: lessons.map((lesson) => lesson.title) },
      });
    }
    if (!(await repository.deleteById(id))) throw kanjiNotFound();
  },
});

export const kanjiService = createKanjiService();

export default kanjiService;
