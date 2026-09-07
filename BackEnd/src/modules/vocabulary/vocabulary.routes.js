import express from 'express';

import {
  authenticateAdmin,
  authenticateUser,
} from '../../middleware/auth.middleware.js';
import { uploadContentExcel } from '../../middleware/upload.middleware.js';
import { asyncHandler } from '../../shared/http/async-handler.js';
import { validate } from '../../shared/http/validate.js';
import { createVocabularyController } from './vocabulary.controller.js';
import * as schema from './vocabulary.schema.js';
import { vocabularyService } from './vocabulary.service.js';

/**
 * Route chỉ khai báo path, middleware và controller binding.
 *
 * Nhận dependency qua tham số để test có thể dựng router với service giả và
 * middleware auth giả, không cần MongoDB hay JWT.
 */
export const createVocabularyRoutes = ({
  service = vocabularyService,
  authenticate = authenticateUser,
  authorizeAdmin = authenticateAdmin,
  uploadExcel = uploadContentExcel,
} = {}) => {
  const controller = createVocabularyController(service);
  const router = express.Router();

  router.get(
    '/',
    authenticate,
    validate({ query: schema.listQuery }),
    asyncHandler(controller.listVocabularies),
  );
  router.get(
    '/search',
    authenticate,
    validate({ query: schema.searchQuery }),
    asyncHandler(controller.search),
  );
  router.get('/situations', authenticate, asyncHandler(controller.listSituations));
  router.get(
    '/lesson/:lessonId',
    authenticate,
    validate({ params: schema.lessonIdParams }),
    asyncHandler(controller.listByLesson),
  );
  router.get(
    '/level/:levelEnum',
    authenticate,
    validate({ params: schema.levelParams }),
    asyncHandler(controller.listByLevel),
  );
  router.get(
    '/situation/search',
    authenticate,
    validate({ query: schema.situationSearchQuery }),
    asyncHandler(controller.searchBySituation),
  );
  router.get(
    '/random/practice',
    authenticate,
    validate({ query: schema.randomPracticeQuery }),
    asyncHandler(controller.randomPractice),
  );
  router.get('/admin/stats', authorizeAdmin, asyncHandler(controller.adminStats));
  router.get(
    '/admin/export',
    authorizeAdmin,
    validate({ query: schema.exportQuery }),
    asyncHandler(controller.adminExport),
  );
  router.get(
    '/:id',
    authenticate,
    validate({ params: schema.idParams }),
    asyncHandler(controller.detail),
  );
  router.post(
    '/learn/:id',
    authenticate,
    validate({ params: schema.idParams, body: schema.learnBody }),
    asyncHandler(controller.learnInLesson),
  );
  router.post(
    '/',
    authorizeAdmin,
    validate({ body: schema.createBody }),
    asyncHandler(controller.create),
  );
  router.put(
    '/:id',
    authorizeAdmin,
    validate({ params: schema.idParams, body: schema.updateBody }),
    asyncHandler(controller.update),
  );
  router.delete(
    '/:id',
    authorizeAdmin,
    validate({ params: schema.idParams }),
    asyncHandler(controller.remove),
  );
  router.delete(
    '/',
    authorizeAdmin,
    validate({ body: schema.deleteManyBody }),
    asyncHandler(controller.removeMany),
  );
  router.post(
    '/upload',
    authorizeAdmin,
    uploadExcel,
    validate({ body: schema.uploadBody }),
    asyncHandler(controller.importExcel),
  );
  router.post(
    '/:id/mark-learned',
    authenticate,
    validate({ params: schema.idParams }),
    asyncHandler(controller.markLearned),
  );
  router.delete(
    '/:id/mark-learned',
    authenticate,
    validate({ params: schema.idParams }),
    asyncHandler(controller.unmarkLearned),
  );

  return router;
};

export default createVocabularyRoutes();
