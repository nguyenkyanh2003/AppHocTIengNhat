import express from 'express';

import {
  authenticateAdmin,
  authenticateUser,
} from '../../middleware/auth.middleware.js';
import { asyncHandler } from '../../shared/http/async-handler.js';
import { validate } from '../../shared/http/validate.js';
import { createLessonController } from './lesson.controller.js';
import * as schema from './lesson.schema.js';
import { lessonService } from './lesson.service.js';

/**
 * Route chỉ khai báo path, middleware và controller binding. Nhận dependency
 * qua tham số để test dựng router với service giả và middleware auth giả,
 * không cần MongoDB hay JWT — giống `createVocabularyRoutes`.
 */
export const createLessonRoutes = ({
  service = lessonService,
  authenticate = authenticateUser,
  authorizeAdmin = authenticateAdmin,
} = {}) => {
  const controller = createLessonController(service);
  const router = express.Router();

  router.get(
    '/',
    authenticate,
    validate({ query: schema.listQuery }),
    asyncHandler(controller.listRoot),
  );
  router.get(
    '/level/:capDo',
    authenticate,
    validate({ params: schema.capDoParams }),
    asyncHandler(controller.getLevelByCapDo),
  );
  router.get(
    '/type/:loaiBaiHoc',
    authenticate,
    validate({ params: schema.loaiBaiHocParams }),
    asyncHandler(controller.getTypeByLoaiBaiHoc),
  );
  router.get(
    '/stats/overview',
    authorizeAdmin,
    asyncHandler(controller.getStatsOverview),
  );
  router.get(
    '/:id',
    authenticate,
    validate({ params: schema.idParams }),
    asyncHandler(controller.getById),
  );
  router.post(
    '/',
    authorizeAdmin,
    validate({ body: schema.createBody }),
    asyncHandler(controller.postRoot),
  );
  router.post(
    '/bulk',
    authorizeAdmin,
    validate({ body: schema.bulkBody }),
    asyncHandler(controller.postBulk),
  );
  router.put(
    '/:id',
    authorizeAdmin,
    validate({ params: schema.idParams, body: schema.updateBody }),
    asyncHandler(controller.putById),
  );
  router.patch(
    '/:id',
    authorizeAdmin,
    validate({ params: schema.idParams, body: schema.updateBody }),
    asyncHandler(controller.putById),
  );
  router.delete(
    '/:id',
    authorizeAdmin,
    validate({ params: schema.idParams }),
    asyncHandler(controller.deleteById),
  );
  router.delete(
    '/',
    authorizeAdmin,
    validate({ body: schema.idsBody }),
    asyncHandler(controller.deleteRoot),
  );
  router.post(
    '/:id/duplicate',
    authorizeAdmin,
    validate({ params: schema.idParams }),
    asyncHandler(controller.postByIdDuplicate),
  );

  return router;
};

export default createLessonRoutes();
