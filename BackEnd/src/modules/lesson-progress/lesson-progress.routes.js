import express from 'express';

import { authenticateUser } from '../../middleware/auth.middleware.js';
import { asyncHandler } from '../../shared/http/async-handler.js';
import { validate } from '../../shared/http/validate.js';
import { createLessonProgressController } from './lesson-progress.controller.js';
import * as schema from './lesson-progress.schema.js';
import { lessonProgressService } from './lesson-progress.service.js';

/**
 * Nhận dependency qua tham số để test dựng router với service giả và auth giả.
 */
export const createLessonProgressRoutes = ({
  service = lessonProgressService,
  authenticate = authenticateUser,
} = {}) => {
  const controller = createLessonProgressController(service);
  const router = express.Router();

  router.use(authenticate);

  router.get(
    '/lesson/:lessonId',
    validate({ params: schema.lessonIdParams }),
    asyncHandler(controller.getByLessonId),
  );
  router.get('/lessons', asyncHandler(controller.list));
  router.post(
    '/lesson/:lessonId/start',
    validate({ params: schema.lessonIdParams }),
    asyncHandler(controller.start),
  );
  router.post(
    '/lesson/:lessonId/update',
    validate({ params: schema.lessonIdParams, body: schema.updateBody }),
    asyncHandler(controller.update),
  );
  router.post(
    '/lesson/:lessonId/complete',
    validate({ params: schema.lessonIdParams }),
    asyncHandler(controller.complete),
  );
  router.post(
    '/lesson/:lessonId/reset',
    validate({ params: schema.lessonIdParams }),
    asyncHandler(controller.reset),
  );
  router.get('/stats', asyncHandler(controller.stats));
  router.get(
    '/level/:level',
    validate({ params: schema.levelParams }),
    asyncHandler(controller.levelStats),
  );

  return router;
};

export default createLessonProgressRoutes();
