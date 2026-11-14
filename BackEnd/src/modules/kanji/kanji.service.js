import { isDuplicateKeyError } from '../../shared/db/duplicate-key.js';
import { unitOfWork as defaultUnitOfWork } from '../../shared/db/unit-of-work.js';
import { readSheetRows } from '../../shared/excel/sheet.js';
import { ApiError } from '../../shared/http/api-error.js';
import { toSkip } from '../../shared/http/pagination.js';
import { escapeRegExp } from '../../shared/utils/regexp.js';
import { toSrsProgressDto } from '../srs/srs.dto.js';
import { srsRepository } from '../srs/srs.repository.js';
import { initialProgress } from '../srs/srs-scheduling.js';
import { REQUIRED_HEADERS, toKanjiDocuments } from './kanji-import.js';
import { kanjiRepository } from './kanji.repository.js';

const ITEM_TYPE = 'Kanji';
const SEARCH_LIMIT = 50;
const SEARCHED_FIELDS = ['character', 'hanviet', 'onyomi', 'kunyomi', 'meaning'];

const kanjiNotFound = () => ApiError.notFound('Không tìm thấy Kanji.');

const duplicateKanji = (message) => ApiError.conflict(message, { code: 'DUPLICATE_KANJI' });

/** Unique index `character` là chỗ chặn cuối khi hai lần ghi chạy cùng lúc. */
const rethrowDuplicate = (error) => {
  if (isDuplicateKeyError(error)) throw duplicateKanji('Chữ Kanji này đã có trong kho.');
  throw error;
};

/**
 * Kho Kanji và lịch ôn của nó (spec Kanji SRS §2).
 *
 * Thêm vào ôn tập chỉ tạo thẻ: không cộng XP, không đụng tiến độ bài học —
 * XP đến từ các lượt ôn sau đó, như thẻ từ vựng. Thẻ đi qua `srsRepository`
 * để hình dạng dữ liệu SRS chỉ được biết ở một chỗ.
 */
export const createKanjiService = ({
  repository = kanjiRepository,
  srs = srsRepository,
  clock = () => new Date(),
  unitOfWork = defaultUnitOfWork,
  readSheet = readSheetRows,
} = {}) => {
  const assertLessonsExist = async (ids) => {
    const existing = new Set(await repository.existingLessonIds(ids));
    const missing = ids.filter((id) => !existing.has(id));
    if (missing.length > 0) throw ApiError.notFound(`Không tìm thấy bài học ${missing.join(', ')}.`);
  };

  return {
    async list({ page, limit, level }) {
      const filter = level ? { level } : {};
      const [items, total] = await Promise.all([
        repository.findPage({ filter, skip: toSkip({ page, limit }), limit }),
        repository.count(filter),
      ]);
      return { items, total, page, limit };
    },

    /** Từ khoá khớp nguyên văn, không phân biệt hoa thường; không thấy là danh sách rỗng. */
    search({ keyword, level }) {
      const pattern = { $regex: escapeRegExp(keyword), $options: 'i' };
      const filter = {
        ...(level && { level }),
        $or: SEARCHED_FIELDS.map((field) => ({ [field]: pattern })),
      };
      return repository.search({ filter, limit: SEARCH_LIMIT });
    },

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

    async create(input) {
      await assertLessonsExist([input.lessonId]);
      return repository.create(input).catch(rethrowDuplicate);
    },

    /** Đổi sang bài khác thì bài đó phải có thật; gỡ khỏi bài (`null`) thì không cần kiểm. */
    async update(id, changes) {
      if (changes.lessonId) await assertLessonsExist([changes.lessonId]);
      const kanji = await repository.updateById({ id, set: changes }).catch(rethrowDuplicate);
      if (!kanji) throw kanjiNotFound();
      return kanji;
    },

    /** Nhập cả file hoặc không nhập gì: lỗi ở bất kỳ dòng nào cũng bỏ cả file. */
    async importSheet(buffer) {
      const { documents, errors } = toKanjiDocuments(await readSheet(buffer, { requiredHeaders: REQUIRED_HEADERS }));
      if (errors.length > 0) {
        throw ApiError.badRequest('Lỗi dữ liệu trong file Excel.', { code: 'INVALID_SHEET', details: errors });
      }
      if (documents.length === 0) throw ApiError.badRequest('File Excel không có dữ liệu.');

      await assertLessonsExist([...new Set(documents.map((doc) => doc.lessonId))]);
      const taken = await repository.findCharacters(documents.map((doc) => doc.character));
      if (taken.length > 0) throw duplicateKanji(`Kho đã có các chữ: ${taken.join(', ')}.`);

      const inserted = await unitOfWork
        .run(({ session }) => repository.insertMany(documents, { session }))
        .catch(rethrowDuplicate);
      return { insertedCount: inserted.length };
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
  };
};

export const kanjiService = createKanjiService();

export default kanjiService;
