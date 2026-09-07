import { ApiError } from '../../shared/http/api-error.js';
import { created, list, ok, paginated } from '../../shared/http/respond.js';
import { vocabularyService } from './vocabulary.service.js';

/**
 * Controller chỉ map HTTP <-> service: đọc `req.valid`, chọn status code, chọn
 * hình dạng response. Không rule nghiệp vụ, không truy vấn DB, không try/catch
 * (asyncHandler + errorHandler lo phần lỗi).
 */
export const createVocabularyController = (service) => ({
  async listVocabularies(req, res) {
    const result = await service.list({
      userId: req.user._id,
      ...req.valid.query,
    });

    return paginated(res, result);
  },

  async search(req, res) {
    const items = await service.search(req.valid.query);
    return list(res, items);
  },

  async listSituations(req, res) {
    const situations = await service.listSituations();
    return list(res, situations);
  },

  async listByLesson(req, res) {
    const items = await service.listByLesson(req.valid.params.lessonId);
    return list(res, items);
  },

  async listByLevel(req, res) {
    const items = await service.listByLevel(req.valid.params.levelEnum);
    return list(res, items);
  },

  async searchBySituation(req, res) {
    const items = await service.searchBySituation(req.valid.query.q);
    return list(res, items);
  },

  async randomPractice(req, res) {
    const items = await service.randomPractice(req.valid.query);
    return list(res, items);
  },

  async detail(req, res) {
    const vocabulary = await service.getById({
      id: req.valid.params.id,
      userId: req.user._id,
    });

    return ok(res, vocabulary);
  },

  async learnInLesson(req, res) {
    const result = await service.learnInLesson({
      id: req.valid.params.id,
      lessonId: req.valid.body.lessonId,
    });

    return res.json(result);
  },

  async create(req, res) {
    const vocabulary = await service.create(req.valid.body);
    return created(res, vocabulary, { message: 'Thêm từ vựng thành công' });
  },

  async update(req, res) {
    const vocabulary = await service.update(req.valid.params.id, req.valid.body);
    return ok(res, vocabulary, { message: 'Cập nhật từ vựng thành công' });
  },

  async remove(req, res) {
    const vocabulary = await service.remove(req.valid.params.id);
    return ok(res, vocabulary, { message: 'Xóa từ vựng thành công' });
  },

  async removeMany(req, res) {
    const deletedCount = await service.removeMany(req.valid.body.ids);
    return ok(res, { deletedCount }, {
      message: `Đã xóa ${deletedCount} từ vựng.`,
    });
  },

  async importExcel(req, res) {
    if (!req.file) throw ApiError.badRequest('Vui lòng upload file Excel.');

    const vocabularies = await service.importFromExcel({
      buffer: req.file.buffer,
      ...req.valid.body,
    });

    return created(res, vocabularies, {
      message: `Thêm thành công ${vocabularies.length} từ vựng.`,
      count: vocabularies.length,
    });
  },

  async adminStats(req, res) {
    const stats = await service.stats();
    return ok(res, stats);
  },

  async adminExport(req, res) {
    const workbook = await service.buildExportWorkbook(req.valid.query);

    res.setHeader(
      'Content-Type',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
    res.setHeader(
      'Content-Disposition',
      `attachment; filename=vocabulary_export_${Date.now()}.xlsx`,
    );

    await workbook.xlsx.write(res);
    return res.end();
  },

  async markLearned(req, res) {
    const { progress, message } = await service.markLearned({
      id: req.valid.params.id,
      userId: req.user._id,
    });

    return ok(res, progress, { message });
  },

  async unmarkLearned(req, res) {
    await service.unmarkLearned({
      id: req.valid.params.id,
      userId: req.user._id,
    });

    return res.json({ message: 'Đã xóa đánh dấu đã học.' });
  },
});

export const vocabularyController = createVocabularyController(vocabularyService);

export default vocabularyController;
