import express from 'express';

import { authenticateUser } from '../../middleware/auth.middleware.js';
import { asyncHandler } from '../../shared/http/async-handler.js';
import { validate } from '../../shared/http/validate.js';
import { createLessonProgressController } from './lesson-progress.controller.js';
import * as schema from './lesson-progress.schema.js';
import { lessonProgressService } from './lesson-progress.service.js';

/**
 * Nhận dependency qua tham số để test dựng router với service giả và auth giả.
 * Xác thực gắn theo từng route (không `router.use`) để path không tồn tại vẫn là 404.
 */
export const createLessonProgressRoutes = ({
  service = lessonProgressService,
  authenticate = authenticateUser,
} = {}) => {
  const controller = createLessonProgressController(service);
  const lesson = validate({ params: schema.lessonIdParams });
  const router = express.Router();

  router.get('/lesson/:lessonId', authenticate, lesson, asyncHandler(controller.getByLessonId));
  router.get('/lessons', authenticate, asyncHandler(controller.list));
  router.post('/lesson/:lessonId/start', authenticate, lesson, asyncHandler(controller.start));
  router.post(
    '/lesson/:lessonId/update',
    authenticate,
    validate({ params: schema.lessonIdParams, body: schema.updateBody }),
    asyncHandler(controller.update),
  );
  router.post('/lesson/:lessonId/complete', authenticate, lesson, asyncHandler(controller.complete));
  router.post('/lesson/:lessonId/reset', authenticate, lesson, asyncHandler(controller.reset));

  return router;
};

export default createLessonProgressRoutes();
