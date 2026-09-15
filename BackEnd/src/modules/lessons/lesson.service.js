import { ApiError } from '../../shared/http/api-error.js';
import { lessonRepository } from './lesson.repository.js';

const escapeRegExp = (value) => value.trim().replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

/**
 * Rule nghiệp vụ của domain bài học. Không biết `req`/`res`, không import model —
 * mọi truy cập dữ liệu đi qua repository được tiêm vào.
 */
export const createLessonService = ({ lessonRepository: repository }) => ({
  async list({ page, limit, level, type, situation, search }) {
    const filter = {};
    if (level) filter.level = level;
    if (type) filter.type = { $regex: escapeRegExp(type), $options: 'i' };
    if (situation) filter.situation = situation;
    if (search) {
      const pattern = { $regex: escapeRegExp(search), $options: 'i' };
      filter.$or = [{ title: pattern }, { description: pattern }];
    }

    const [items, total] = await Promise.all([
      repository.findMany({
        filter,
        sort: { level: -1, order: 1 },
        skip: (page - 1) * limit,
        limit,
      }),
      repository.count(filter),
    ]);

    return { items, page, limit, total, totalPages: Math.ceil(total / limit) };
  },

  /**
   * Chi tiết một bài học. `vocabularies`/`grammars`/`kanjis` populate rỗng khi
   * bài học chưa gắn tham chiếu trực tiếp — khi đó tra ngược theo
   * `Vocabulary.lesson`/`Grammar.lesson_id`/`Kanji.lessonId` thay vì trả mảng
   * rỗng, đúng hành vi trước khi tách tầng. `tuvungs`/`nguphaps` là alias mà
   * Flutter đang đọc, không phải field mới.
   */
  async getDetail(id) {
    const lesson = await repository.findById(id);
    if (!lesson) throw ApiError.notFound('Bài học không tồn tại.');

    const [vocabularies, grammars, kanjis] = await Promise.all([
      lesson.vocabularies?.length
        ? lesson.vocabularies
        : repository.findVocabulariesByLesson(lesson._id),
      lesson.grammars?.length
        ? lesson.grammars
        : repository.findActiveGrammarsByLesson(lesson._id),
      lesson.kanjis?.length
        ? lesson.kanjis
        : repository.findKanjisByLesson(lesson._id),
    ]);

    return {
      ...lesson,
      vocabularies,
      grammars,
      kanjis,
      tuvungs: vocabularies,
      nguphaps: grammars,
    };
  },

  getByLevel(level) {
    return repository.findByLevel(level);
  },

  /**
   * Danh sách tình huống có bài học, để client dựng bộ lọc.
   *
   * Chỉ trả tình huống thật sự có nội dung, và khi có `level` thì chỉ trả chủ
   * đề có bài ở cấp đó: hiện chủ đề không có bài thì chip bấm vào trả rỗng.
   */
  async listSituations({ level } = {}) {
    const situations = await repository.distinctSituations({ level });
    return [...situations].sort();
  },

  getByType(typePattern) {
    return repository.findByTypePattern({
      $regex: escapeRegExp(typePattern),
      $options: 'i',
    });
  },

  getStatsOverview() {
    return repository.aggregateStats();
  },

  create(input) {
    return repository.create(input);
  },

  createMany(inputs) {
    return repository.createMany(inputs);
  },

  async update(id, input) {
    const updated = await repository.updateById(id, input);
    if (!updated) throw ApiError.notFound('Bài học không tồn tại.');
    return updated;
  },

  async remove(id) {
    const related = await repository.countRelated([id]);
    if (Object.values(related).some((count) => count > 0)) {
      throw ApiError.conflict('Không thể xóa bài học đang có nội dung liên quan.', {
        details: related,
      });
    }

    const deleted = await repository.deleteById(id);
    if (!deleted) throw ApiError.notFound('Bài học không tồn tại.');
    return deleted;
  },

  async removeMany(ids) {
    const related = await repository.countRelated(ids);
    if (Object.values(related).some((count) => count > 0)) {
      throw ApiError.conflict('Không thể xóa các bài học đang có nội dung liên quan.', {
        details: related,
      });
    }

    return repository.deleteManyByIds(ids);
  },

  async duplicate(id) {
    const original = await repository.findByIdLean(id);
    if (!original) throw ApiError.notFound('Bài học không tồn tại.');

    delete original._id;
    delete original.createdAt;
    delete original.updatedAt;
    original.title = `${original.title} (Bản sao ${Date.now()})`;

    return repository.create(original);
  },
});

export const lessonService = createLessonService({ lessonRepository });

export default lessonService;
