import express from 'express';

import { authenticateAdmin, authenticateUser } from '../../middleware/auth.middleware.js';
import { uploadContentExcel } from '../../middleware/upload.middleware.js';
import { asyncHandler } from '../../shared/http/async-handler.js';
import { validate } from '../../shared/http/validate.js';
import { createKanjiController } from './kanji.controller.js';
import * as schema from './kanji.schema.js';
import { kanjiService } from './kanji.service.js';

/** Nhận dependency qua tham số để test dựng router với service, auth và upload giả. */
export const createKanjiRoutes = ({
  service = kanjiService,
  authenticate = authenticateUser,
  authenticateAsAdmin = authenticateAdmin,
  uploadExcel = uploadContentExcel,
} = {}) => {
  const controller = createKanjiController(service);
  const byId = validate({ params: schema.idParams });
  const router = express.Router();

  router.get('/', authenticate, validate({ query: schema.listQuery }), asyncHandler(controller.list));
  router.get('/search', authenticate, validate({ query: schema.searchQuery }), asyncHandler(controller.search));
  router.get('/:id', authenticate, byId, asyncHandler(controller.getById));
  router.post('/:id/mark-learned', authenticate, byId, asyncHandler(controller.markLearned));
  router.delete('/:id/mark-learned', authenticate, byId, asyncHandler(controller.unmarkLearned));
  router.post('/', authenticateAsAdmin, validate({ body: schema.createBody }), asyncHandler(controller.create));
  router.post('/upload', authenticateAsAdmin, uploadExcel, asyncHandler(controller.importSheet));
  router.put('/:id', authenticateAsAdmin, byId, validate({ body: schema.updateBody }), asyncHandler(controller.update));
  router.delete('/:id', authenticateAsAdmin, byId, asyncHandler(controller.deleteById));

  return router;
};

export default createKanjiRoutes();
