import express from 'express';

import { authenticateAdmin, authenticateUser } from '../../middleware/auth.middleware.js';
import { asyncHandler } from '../../shared/http/async-handler.js';
import { validate } from '../../shared/http/validate.js';
import * as legacy from './kanji.controller.js';
import * as schema from './kanji.schema.js';
import { kanjiService } from './kanji.service.js';

/**
 * Nhận dependency qua tham số để test dựng router với service và auth giả.
 *
 * Chi tiết, thêm/gỡ ôn tập và xoá đi qua service; các route khác vẫn dùng
 * handler cũ cho tới đợt refactor module.
 */
export const createKanjiRoutes = ({
  service = kanjiService,
  authenticate = authenticateUser,
  authenticateAsAdmin = authenticateAdmin,
} = {}) => {
  const controller = legacy.createKanjiController(service);
  const byId = validate({ params: schema.idParams });
  const router = express.Router();

  router.get('/', authenticate, legacy.getRoot);
  router.get('/search', authenticate, legacy.getSearch);
  router.get('/level/:level', authenticate, legacy.getLevelByLevel);
  router.get('/lesson/:lessonId', authenticate, legacy.getLessonByLessonId);
  router.get('/:id', authenticate, byId, asyncHandler(controller.getById));
  router.post('/:id/mark-learned', authenticate, byId, asyncHandler(controller.markLearned));
  router.delete('/:id/mark-learned', authenticate, byId, asyncHandler(controller.unmarkLearned));
  router.post('/', authenticateAsAdmin, legacy.postRoot);
  router.post('/upload', authenticateAsAdmin, legacy.upload.single('fileExcel'), legacy.postUpload);
  router.put('/:id', authenticateAsAdmin, legacy.putById);
  router.delete('/:id', authenticateAsAdmin, byId, asyncHandler(controller.deleteById));

  return router;
};

export default createKanjiRoutes();
