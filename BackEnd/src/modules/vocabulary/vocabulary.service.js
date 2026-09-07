import { ApiError } from '../../shared/http/api-error.js';
import { initialProgress } from '../srs/srs-scheduling.js';
import { srsRepository } from '../srs/srs.repository.js';
import { vocabularyRepository } from './vocabulary.repository.js';
import {
  buildExportWorkbook as buildWorkbook,
  readWorkbookRows,
  toVocabularyRows,
} from './vocabulary-import.service.js';

const ITEM_TYPE = 'Vocabulary';

/**
 * `Vocabulary` không bật `timestamps`, nên `createdAt` không tồn tại và sort
 * theo nó không có tác dụng. `_id` của MongoDB đã mã hoá thời điểm tạo, nên
 * sort giảm dần theo `_id` chính là "mới nhất trước".
 */
const SORT_OPTIONS = Object.freeze({
  alphabet: { word: 1 },
  difficulty: { level: -1 },
  newest: { _id: -1 },
});

const sortFor = (sortBy) => SORT_OPTIONS[sortBy] ?? SORT_OPTIONS.newest;

const escapeRegExp = (value) => value.trim().replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

const buildKeywordFilter = (keyword) => {
  const pattern = new RegExp(escapeRegExp(keyword), 'i');
  return {
    $or: [{ word: pattern }, { hiragana: pattern }, { meaning: pattern }],
  };
};

/**
 * Rule nghiệp vụ của domain từ vựng.
 *
 * Service không biết `req`/`res` và không import model: mọi truy cập dữ liệu đi
 * qua repository được tiêm vào, nên test chỉ cần repository giả.
 */
export const createVocabularyService = ({
  vocabularyRepository: repository,
  srsRepository: srs,
  importer = {
    readWorkbookRows,
    toVocabularyRows,
    buildExportWorkbook: buildWorkbook,
  },
}) => {
  /** Giới hạn danh sách theo trạng thái đã học của user, trước khi phân trang. */
  const applyStudyStatus = async (filter, { userId, studyStatus }) => {
    if (studyStatus !== 'learned' && studyStatus !== 'unlearned') return filter;

    const learnedIds = await srs.findLearnedItemIds({
      userId,
      itemType: ITEM_TYPE,
    });

    return {
      ...filter,
      _id:
        studyStatus === 'learned' ? { $in: learnedIds } : { $nin: learnedIds },
    };
  };

  return {
    async list({ userId, page, limit, level, studyStatus, sortBy }) {
      const baseFilter = level ? { level } : {};
      const filter = await applyStudyStatus(baseFilter, { userId, studyStatus });

      const [items, total] = await Promise.all([
        repository.findPage({
          filter,
          sort: sortFor(sortBy),
          skip: (page - 1) * limit,
          limit,
        }),
        repository.count(filter),
      ]);

      return { items, page, limit, total };
    },

    search({ keyword, level }) {
      const filter = buildKeywordFilter(keyword);
      if (level) filter.level = level;

      return repository.findAll({ filter, sort: sortFor('newest') });
    },

    async getById({ id, userId }) {
      const vocabulary = await repository.findDetailById(id);
      if (!vocabulary) throw ApiError.notFound('Không tìm thấy từ vựng.');

      const progress = await srs.findProgress({
        userId,
        itemId: id,
        itemType: ITEM_TYPE,
      });

      return {
        ...vocabulary,
        isLearned: !!progress,
        ...(progress
          ? { learnedAt: progress.createdAt, reviewBox: progress.box }
          : {}),
      };
    },

    listByLesson(lessonId) {
      return repository.findAll({
        filter: { lesson: lessonId },
        sort: sortFor('newest'),
      });
    },

    listByLevel(level) {
      return repository.findAll({ filter: { level }, sort: sortFor('newest') });
    },

    async listSituations() {
      const situations = await repository.distinctUsageContexts();
      return [...situations].sort();
    },

    searchBySituation(query) {
      return repository.findAll({
        filter: { usage_context: new RegExp(escapeRegExp(query), 'i') },
        sort: sortFor('newest'),
      });
    },

    randomPractice({ limit, level }) {
      return repository.sample({ filter: level ? { level } : {}, size: limit });
    },

    /**
     * Học từ vựng trong bài học. XP chỉ được cộng qua lesson-progress, nên ở đây
     * chỉ kiểm tra từ vựng tồn tại rồi chỉ đường sang API đó.
     */
    async learnInLesson({ id, lessonId }) {
      const vocabulary = await repository.findById(id);
      if (!vocabulary) throw ApiError.notFound('Không tìm thấy từ vựng.');

      return {
        message:
          'Vui lòng sử dụng API /lesson-progress/lesson/:lessonId/update để cập nhật tiến độ học',
        redirect: `/lesson-progress/lesson/${lessonId}/update`,
      };
    },

    async create(payload) {
      const exists = await repository.lessonExists(payload.lesson);
      if (!exists) {
        throw ApiError.notFound(
          `Không tìm thấy bài học có ID: ${payload.lesson}`,
        );
      }

      const created = await repository.create(payload);
      return repository.findPopulatedById(created._id);
    },

    async update(id, payload) {
      if (payload.lesson) {
        const exists = await repository.lessonExists(payload.lesson);
        if (!exists) {
          throw ApiError.notFound(`Không tìm thấy bài học ${payload.lesson}.`);
        }
      }

      const updated = await repository.updateById(id, payload);
      if (!updated) {
        throw ApiError.notFound('Không tìm thấy từ vựng để cập nhật.');
      }

      return updated;
    },

    async remove(id) {
      const deleted = await repository.deleteById(id);
      if (!deleted) throw ApiError.notFound('Không tìm thấy từ vựng để xóa.');

      return deleted;
    },

    removeMany(ids) {
      return repository.deleteManyByIds(ids);
    },

    async importFromExcel({ buffer, lesson, level }) {
      const exists = await repository.lessonExists(lesson);
      if (!exists) throw ApiError.notFound(`Không tìm thấy bài học ${lesson}.`);

      const sheetRows = await importer.readWorkbookRows(buffer);
      const rows = importer.toVocabularyRows(sheetRows, { lesson, level });

      if (rows.length === 0) {
        throw ApiError.badRequest(
          'File Excel rỗng hoặc thiếu cột bắt buộc (TuVung, Hiragana, NghiaTV).',
        );
      }

      return repository.insertMany(rows);
    },

    stats() {
      return repository.stats();
    },

    async buildExportWorkbook({ level, lesson }) {
      const filter = {};
      if (level) filter.level = level;
      if (lesson) filter.lesson = lesson;

      const vocabularies = await repository.findForExport(filter);
      return importer.buildExportWorkbook(vocabularies);
    },

    async markLearned({ id, userId }) {
      const vocabulary = await repository.findById(id);
      if (!vocabulary) throw ApiError.notFound('Không tìm thấy từ vựng.');

      const existing = await srs.findProgress({
        userId,
        itemId: id,
        itemType: ITEM_TYPE,
      });

      if (existing) {
        return {
          progress: existing,
          created: false,
          message: 'Từ vựng đã được đánh dấu là đã học.',
        };
      }

      const { box, next_review: nextReview, streak } = initialProgress();
      const progress = await srs.createProgress({
        userId,
        itemId: id,
        itemType: ITEM_TYPE,
        box,
        nextReview,
        streak,
      });

      return {
        progress,
        created: true,
        message: 'Đã đánh dấu từ vựng là đã học.',
      };
    },

    async unmarkLearned({ id, userId }) {
      const deletedCount = await srs.deleteProgress({
        userId,
        itemId: id,
        itemType: ITEM_TYPE,
      });

      if (deletedCount === 0) {
        throw ApiError.notFound('Không tìm thấy progress để xóa.');
      }
    },
  };
};

export const vocabularyService = createVocabularyService({
  vocabularyRepository,
  srsRepository,
});

export default vocabularyService;
